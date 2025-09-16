#!/usr/bin/env bash
set -euo pipefail

LOG_DIR=/var/log/pc-setup
sudo mkdir -p "$LOG_DIR"
exec > >(sudo tee -a "$LOG_DIR/setup.log") 2>&1

ROLE="${ROLE:-default}"

# 実行時間計測・終了時通報
START_EPOCH="$(date -u +%s)"
post_discord() {
  local rc="${1:-0}"
  local end_epoch="$(date -u +%s)"
  local elapsed="$(( end_epoch - START_EPOCH ))"
  local status="SUCCESS"
  [ "$rc" -ne 0 ] && status="FAILURE($rc)"
  if [ -n "${DISCORD_WEBHOOK:-}" ]; then
    # JSON のエスケープを避けるため multipart/form-data で content を送る（シンプル）
    local msg="[$status] pc-setup macOS role=${ROLE} host=$(hostname -s) elapsed=${elapsed}s log=${LOG_DIR}/setup.log"
    curl -fsS -X POST -F "content=${msg}" "$DISCORD_WEBHOOK" || true
  fi
}
trap 'post_discord $?' EXIT

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

# Homebrew
if ! command -v brew >/dev/null 2>&1; then
  retry curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh -o /tmp/brew-install.sh
  /bin/bash /tmp/brew-install.sh
  eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"
fi

BASE="https://raw.githubusercontent.com/4sas/pc-setup/main/mac"
retry curl -fsSL "$BASE/install.sh" -o /tmp/install.sh
bash /tmp/install.sh "$ROLE"
