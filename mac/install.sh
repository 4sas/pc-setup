#!/usr/bin/env bash
set -euo pipefail

ROLE="${1:-default}"

BASE="https://raw.githubusercontent.com/4sas/pc-setup/main/mac"
TMP_COMMON="/tmp/BREWFILE.common.$$"
TMP_ROLE="/tmp/BREWFILE.role.$$"

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
  while IFS=',' read -r url sha args; do
    url="${url//[[:space:]]/}"; sha="${sha//[[:space:]]/}"
    [ -n "$url" ] || continue
    if grep -Fxq "$url" "$VENDOR_MARKER"; then
      echo "Skip (already installed): $url"
      continue
    fi
    tmp="/tmp/vendor.$$.pkg"
    case "$url" in
      *.dmg) tmp="/tmp/vendor.$$.dmg" ;;
      *.pkg|*.mpkg) tmp="/tmp/vendor.$$.pkg" ;;
      *) tmp="/tmp/vendor.$$.bin" ;;
    esac
    download_and_verify "$url" "$sha" "$tmp"
    install_pkg_or_dmg "$tmp" ${args:-}
    echo "$url" | sudo tee -a "$VENDOR_MARKER" >/dev/null
  done
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

echo "macOS セットアップ完了（Role=$ROLE）"
