#!/usr/bin/env bash
# Internet Sharing (USB: AX88179A -> Wi-Fi) one-shot configurator
# SSID/Channel/Security are固定。パスワードは第1引数から。
# 依存: /usr/libexec/PlistBuddy, networksetup, launchctl, defaults
set -euo pipefail

# ---- 固定パラメータ（要件どおり） ----
SRC_SERVICE_NAME="AX88179A"                # 共有元（USB アダプタの“サービス名”）
SSID="k-sakanaka の MacBook Pro"           # 共有先 Wi-Fi の SSID
CHANNEL=11                                  # 共有先 Wi-Fi のチャンネル
SECURITY_LABEL="WPA2/WPA3 パーソナル"       # 表示用ラベル（実体は下の SecurityType を設定）
# 実際に plist に入れる想定キー。OS差分があるため複数キーをベストエフォートで設定する
SECURITY_TYPES=("WPA2/WPA3 Personal" "WPA2 Personal" "WPA3 Personal")

# ---- 引数: パスワード ----
if [[ $# -lt 1 ]]; then
  echo "Usage: sudo $0 '<wifi_password>'" >&2
  exit 2
fi
PASS="$1"
if [[ ${#PASS} -lt 8 || ${#PASS} -gt 63 ]]; then
  echo "ERROR: パスワードは 8〜63 文字の ASCII を推奨します。" >&2
  exit 2
fi

# ---- root 必須 ----
if [[ $EUID -ne 0 ]]; then
  echo "Please run as root (use: sudo $0 '<wifi_password>')" >&2
  exit 1
fi

# ---- 小道具 ----
PLIST_NAT="/Library/Preferences/SystemConfiguration/com.apple.nat.plist"
PREFS="/Library/Preferences/SystemConfiguration/preferences.plist"
PB="/usr/libexec/PlistBuddy"

pb_set() { # path key type value
  local path="$1" key="$2" type="$3" val="$4"
  "$PB" -c "Set ${path}:${key} ${val}" "$PLIST_NAT" 2>/dev/null || \
  "$PB" -c "Add ${path}:${key} ${type} ${val}" "$PLIST_NAT"
}

pb_ensure_dict() { # path
  local path="$1"
  "$PB" -c "Print ${path}" "$PLIST_NAT" >/dev/null 2>&1 || \
  "$PB" -c "Add ${path} dict" "$PLIST_NAT"
}

# ---- Wi-Fi サービス名（ローカライズ差対応） ----
WIFI_SERVICE="$(networksetup -listallnetworkservices 2>/dev/null \
  | tail -n +2 \
  | grep -E '^(Wi[--–]?Fi|AirPort)$' | head -n1 || true)"
# Wi-Fi デバイス名（en0 等）
WIFI_DEV="$(networksetup -listallhardwareports 2>/dev/null \
  | awk '/^Hardware Port: Wi-Fi$/{getline; if($1=="Device:") print $2}' | head -n1)"

# ---- 共有元（AX88179A）の Service UUID を取得 ----
# preferences.plist の NetworkServices から “UserDefinedName: AX88179A” を持つ UUID を探す
SRC_SERVICE_UUID="$(
  $PB -c "Print :NetworkServices" "$PREFS" 2>/dev/null \
  | awk -v RS= -v name="$SRC_SERVICE_NAME" '
      $0 ~ name && match($0, /([0-9A-Fa-f-]{36})\s=\s\{/){ print substr($0,RSTART,RLENGTH-3) ; exit }' \
  | head -n1
)"
if [[ -z "${SRC_SERVICE_UUID:-}" ]]; then
  echo "ERROR: Network Service '${SRC_SERVICE_NAME}' が見つかりません。" >&2
  exit 1
fi

# ---- いったん Internet Sharing を停止 ----
IS_PLIST="/System/Library/LaunchDaemons/com.apple.InternetSharing.plist"
# 新 launchctl（bootout/bootstrap）と旧（unload/load）の両対応
launchctl bootout system "$IS_PLIST" >/dev/null 2>&1 || true
launchctl unload -w "$IS_PLIST" >/dev/null 2>&1 || true

# ---- NAT 設定（com.apple.nat.plist）を作成/更新 ----
# NAT.Enabled=0 （編集中は無効）
defaults write /Library/Preferences/SystemConfiguration/com.apple.nat NAT -dict Enabled -int 0

# 必要な辞書を確保
pb_ensure_dict ":NAT"
pb_ensure_dict ":NAT:AirPort"

# 共有元（PrimaryService = AX88179A の Service UUID）
# 可能なら両方（PrimaryService / PrimaryInterface）を設定
defaults write /Library/Preferences/SystemConfiguration/com.apple.nat PrimaryService -string "$SRC_SERVICE_UUID" 2>/dev/null || true

# 共有先 Wi-Fi のオプション（ベストエフォートで複数キーを設定）
pb_set ":NAT:AirPort" "AllowNetCreation" integer 1
pb_set ":NAT:AirPort" "SSID" string "$SSID"
pb_set ":NAT:AirPort" "Channel" integer "$CHANNEL"
# パスワード（複数キー候補）
for k in Password PSK WPA2PSK; do
  pb_set ":NAT:AirPort" "$k" string "$PASS"
done
# セキュリティ種別（複数候補を順に書く）
for s in "${SECURITY_TYPES[@]}"; do
  pb_set ":NAT:AirPort" "SecurityType" string "$s"
done

# 共有サブネットは既定（192.168.2.0/24）を使用。必要なら以下を解放し調整:
# defaults write /Library/Preferences/SystemConfiguration/com.apple.nat NAT -dict-add SharingNetworkNumberStart "192.168.2.0"
# defaults write /Library/Preferences/SystemConfiguration/com.apple.nat NAT -dict-add SharingNetworkMask "255.255.255.0"

# ---- Wi-Fi を有効化（あれば）----
if [[ -n "${WIFI_SERVICE:-}" ]]; then
  networksetup -setairportpower "$WIFI_SERVICE" on || true
elif [[ -n "${WIFI_DEV:-}" ]]; then
  # 古い networksetup はサービス名必須だが、念のため dev でも試行
  networksetup -setairportpower "$WIFI_DEV" on || true
fi

# ---- Internet Sharing を有効化 ----
# NAT.Enabled=1
defaults write /Library/Preferences/SystemConfiguration/com.apple.nat NAT -dict Enabled -int 1

# Daemon 起動（新旧 launchctl 両対応）
launchctl bootstrap system "$IS_PLIST" 2>/dev/null || launchctl load -w "$IS_PLIST"

echo "Internet Sharing: ${SRC_SERVICE_NAME} → Wi-Fi (${SSID}) を起動しました。"
