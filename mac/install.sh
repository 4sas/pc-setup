#!/usr/bin/env bash
set -euo pipefail

ROLE="${1:-default}"
LOG_DIR="/var/log/pc-setup"

BASE="https://raw.githubusercontent.com/4sas/pc-setup/main/mac"
TMP_COMMON="/tmp/BREWFILE.common.$$"
TMP_ROLE="/tmp/BREWFILE.role.$$"

# 失敗時のみ Discord 通知（ログ添付、なければメッセージのみ）
notify_discord_on_error() {
  local rc="${1:-0}"
  [ -z "${DISCORD_WEBHOOK:-}" ] && return 0
  [ "$rc" -eq 0 ] && return 0
  local host; host="$(hostname -s)"
  local content="[FAILURE(${rc})] pc-setup macOS install.sh role=${ROLE} host=${host} (see ${LOG_DIR}/setup.log)"
  if [ -r "${LOG_DIR}/setup.log" ]; then
    curl -fsS -X POST \
      -F "content=${content}" \
      -F "file=@${LOG_DIR}/setup.log;filename=setup.log" \
      "$DISCORD_WEBHOOK" || true
  else
    curl -fsS -X POST -F "content=${content}" "$DISCORD_WEBHOOK" || true
  fi
}
trap 'rc=$?; notify_discord_on_error "$rc"' EXIT

# リトライ（指数バックオフ）
RETRY_MAX="${RETRY_MAX:-5}"
RETRY_BASE_SEC="${RETRY_BASE_SEC:-1}"
retry() {
  local n=0 max="$RETRY_MAX" base="$RETRY_BASE_SEC"
  until "$@"; do
    n=$((n+1))
    if [ "$n" -ge "$max" ]; then
      echo "ERROR: failed after $n attempts: $*" >&2
      return 1
    fi
    local sleep_sec=$(( base * (2 ** (n-1)) ))
    echo "Retry $n/$max in ${sleep_sec}s: $*" >&2
    sleep "$sleep_sec"
  done
}

retry curl -fsSL "$BASE/Brewfile" -o "$TMP_COMMON"
retry brew update
retry brew bundle --file="$TMP_COMMON"

# 役割 Brewfile 追加適用（Xcode 要求時のみ mas ログイン確認）
if retry curl -fsSL "$BASE/roles/$ROLE/Brewfile" -o "$TMP_ROLE"; then
  if grep -qi 'Xcode' "$TMP_ROLE"; then
    if ! brew list mas >/dev/null 2>&1; then
      retry brew install mas
    fi
    if ! mas account 2>/dev/null | grep -q '@'; then
      open -a "App Store"
      echo "App Store にサインインしてから再実行してください。"
      exit 1
    fi
  fi
  retry brew bundle --file="$TMP_ROLE" || true
fi

VENDOR_MARKER="/var/log/pc-setup/vendor-installed.txt"
sudo touch "$VENDOR_MARKER"

download_and_verify() { # url sha out
  local url="$1" sha="$2" out="$3"
  retry curl -LfsS "$url" -o "$out"
  if [ -n "$sha" ]; then
    local calc; calc="$(shasum -a 256 "$out" | awk '{print $1}')"
    if [ "$calc" != "$sha" ]; then
      echo "ERROR: checksum mismatch for $url" >&2
      echo "  expected: $sha"; echo "  actual  : $calc"
      return 1
    fi
  fi
}

install_pkg_or_dmg() { # path [args...]
  local f="$1"; shift || true
  case "$f" in
    *.pkg|*.mpkg)
      sudo installer -pkg "$f" -target /
      ;;
    *.dmg)
      local mnt; mnt="$(mktemp -d)"
      hdiutil attach "$f" -mountpoint "$mnt" -nobrowse -quiet
      # pkg 優先、無ければ .app を /Applications へ
      local pkg app
      pkg="$(find "$mnt" -maxdepth 1 -type f -name '*.pkg' | head -n1 || true)"
      if [ -n "$pkg" ]; then
        sudo installer -pkg "$pkg" -target /
      else
        app="$(find "$mnt" -maxdepth 1 -type d -name '*.app' | head -n1 || true)"
        if [ -n "$app" ]; then
          local dest="/Applications/$(basename "$app")"
          if [ ! -e "$dest" ]; then
            sudo ditto "$app" "$dest"
          fi
        else
          echo "ERROR: no .pkg/.app found in DMG: $f" >&2
          hdiutil detach "$mnt" -quiet || true
          return 1
        fi
      fi
      hdiutil detach "$mnt" -quiet || true
      ;;
    *)
      echo "WARN: unsupported file type: $f (skip)" >&2
      ;;
  esac
}

process_csv() { # local_csv_path
  local csv="$1"
  [ -f "$csv" ] || return 0
  # ヘッダを除外し、空行/コメントを除く
  tail -n +2 "$csv" | sed 's/\r$//' | sed '/^\s*#/d;/^\s*$/d' | \
  while IFS=',' read -r label type target args keepalive; do
    label="$(echo "${label:-}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    type="$(echo "${type:-}"   | tr '[:upper:]' '[:lower:]' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    target="$(echo "${target:-}"| sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    args="$(echo "${args:-}"   | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    keepalive="$(echo "${keepalive:-}" | tr '[:upper:]' '[:lower:]')"

    [ -n "$type" ] || continue
    [ -n "$target" ] || continue

    ensure_login_agent_from_spec "$label" "$type" "$target" "$args" "$keepalive"
  done
}

process_json_if_available() { # local_json_path
  local jf="$1"
  [ -f "$jf" ] || return 0
  if ! command -v jq >/dev/null 2>&1; then
    echo "WARN: jq not found; skip JSON: $jf"
    return 0
  fi
  # 各エントリを TSV で流し、後段で分解
  jq -r '.[] | [
      (.label // ""),
      (has("app") and (.app|length>0) ? "app" : "cmd"),
      (.app // .cmd // ""),
      ((.args // []) | join(" ")),
      ((.keepAlive // false) | tostring)
    ] | @tsv' "$jf" | \
  while IFS=$'\t' read -r label type target args keepalive; do
    ensure_login_agent_from_spec "$label" "$type" "$target" "$args" "$keepalive"
  done
}

slugify() { # string -> slug
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//; s/-+/-/g'
}

bool_true() { # returns 0 if truthy else 1
  case "${1:-}" in
    1|true|yes|on) return 0 ;;
    *) return 1 ;;
  esac
}

# LaunchAgent 生成ロード
ensure_login_agent() { # label keepAlive program_and_args...
  local label="$1"; shift
  local keep="$1"; shift
  local dir="$HOME/Library/LaunchAgents"
  local plist="$dir/${label}.plist"
  mkdir -p "$dir"

  # ProgramArguments を plist として生成
  {
    cat <<'XML_HEAD'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
XML_HEAD
    printf "    <key>Label</key><string>%s</string>\n" "$label"
    echo "    <key>ProgramArguments</key>"
    echo "    <array>"
    for arg in "$@"; do
      printf '      <string>%s</string>\n' "$arg"
    done
    echo "    </array>"
    echo "    <key>RunAtLoad</key><true/>"
    if bool_true "$keep"; then
      echo "    <key>KeepAlive</key><true/>"
    else
      echo "    <key>KeepAlive</key><false/>"
    fi
    cat <<'XML_TAIL'
  </dict>
</plist>
XML_TAIL
  } > "$plist"

  # 再登録（冪等・両系統対応）
  if launchctl print "gui/$UID/${label}" >/dev/null 2>&1; then
    launchctl bootout "gui/$UID" "$plist" >/dev/null 2>&1 || launchctl unload -w "$plist" >/dev/null 2>&1 || true
  fi
  launchctl bootstrap "gui/$UID" "$plist" >/dev/null 2>&1 || launchctl load -w "$plist" >/dev/null 2>&1 || true
  launchctl enable "gui/$UID/${label}" >/dev/null 2>&1 || true

  echo "AutoLaunch enabled: label=${label}"
}

ensure_login_agent_from_spec() { # label type target args keepalive
  local label="$1" type="$2" target="$3" args="$4" keep="$5"
  if [ -z "$label" ]; then
    label="com.pc-setup.login.$(slugify "$target")"
  fi

  case "$type" in
    app)
      # open -a "AppName" [args...]
      # args はスペース区切り（単純形）。複雑な引数は JSON を利用。
      local argv=(/usr/bin/open -a "$target")
      for a in $args; do argv+=("$a"); done
      ensure_login_agent "$label" "$keep" "${argv[@]}"
      ;;
    cmd)
      local argv=("$target")
      for a in $args; do argv+=("$a"); done
      ensure_login_agent "$label" "$keep" "${argv[@]}"
      ;;
    *)
      echo "WARN: unknown Type='$type' for target='$target' (skip)"
      ;;
  esac
}

# 共通/役割 vendors.csv を順に適用
for src in "$BASE/vendors.csv" "$BASE/roles/$ROLE/vendors.csv"; do
  tmp="/tmp/vendors.$$.csv"
  if curl -fsSL "$src" -o "$tmp"; then
    process_csv "$tmp"
  fi
done

# --- Sleep to 5 minutes (non-interactive; skip if sudo password not cached)
if command -v pmset >/dev/null 2>&1; then
  if sudo -n true 2>/dev/null; then
    sudo -n pmset -a sleep 5 || true
  else
    echo "WARN: skipped setting sleep=5 (sudo password not cached)."
  fi
fi

# --- Internet Sharing を設定/起動（INTERNET_SHARING_PASSWORD があれば）
if [ -n "${INTERNET_SHARING_PASSWORD:-}" ]; then
  retry curl -fsSL "$BASE/internet-sharing.sh" -o /tmp/internet-sharing.sh
  sudo bash /tmp/internet-sharing.sh "$INTERNET_SHARING_PASSWORD" || echo "WARN: internet-sharing failed"
fi

# --- 起動時自動起動 ---
any_autostart=0
# CSV: 共通→役割
for cfg in "$BASE/autostart.csv" "$BASE/roles/$ROLE/autostart.csv"; do
  tmp="/tmp/autostart.$$.csv"
  if curl -fsSL "$cfg" -o "$tmp"; then
    process_csv "$tmp" && any_autostart=1
  fi
done

echo "macOS セットアップ完了（Role=$ROLE）"
