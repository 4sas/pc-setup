# 指示

* macにおいて「Karabiner-Elements」「Scroll Reverser」がMac起動時に自動起動する設定を追加

## 前提条件

* 重複を統合
* 可読性を向上
* "Simple" is "best"
* テスト用のコードは不要
* 使用方法ドキュメントは不要

## [README.md](./README.md)

~~~markdown
# PC Setup (Windows / macOS)

## 対応 OS

* Windows 10/11（winget 利用）
* macOS（Homebrew / Brewfile 利用）

---

## リポジトリ構成

```text
pc-setup/
├─ win/
│  ├─ bootstrap.ps1             # One-liner から読み込む小さなブートストラップ
│  ├─ install.ps1               # 本体（共通 + 役割 packages.json を適用）
│  ├─ packages.json             # Windows共通のインストール設定
│  ├─ packages.msstore.json     # Windows共通のインストール設定（msstore）
│  ├─ vendors.csv               # Windows共通の“直リンク配布”リスト
│  └─ roles/
│     ├─ engineer/packages.json # 役割: エンジニアのインストール設定
│     ├─ designer/packages.json # 役割: デザイナーのインストール設定
│     └─ legal/
│        ├─ packages.json       # 役割: リーガルのインストール設定
│        └─ vendors.csv         # 役割ごとの“直リンク配布”リスト
└─ mac/
   ├─ bootstrap.sh              # One-liner から読み込む小さなブートストラップ
   ├─ install.sh                # 本体（共通 Brewfile + 役割 Brewfile を適用）
   ├─ internet-sharing.sh       # インターネット接続の共有設定
   ├─ Brewfile                  # Mac共通のインストール設定
   ├─ vendors.csv               # mac共通の“直リンク配布”リスト（任意）
   └─ roles/
      ├─ engineer/Brewfile      # 役割: エンジニアのインストール設定
      ├─ designer/Brewfile      # 役割: デザイナーのインストール設定
      └─ legal/
         ├─ Brewfile            # 役割: リーガルのインストール設定
         └─ vendors.csv         # 役割ごとの“直リンク配布”リスト
```

---

## 使い方（One-liner）

### Windows（管理者 PowerShell）

共通のみ：

```powershell
$env:DISCORD_WEBHOOK='https://discordapp.com/api/webhooks/1417340783249592452/X5NfCARV9fnlv5S62XrD-Bi3v6a_lmgHzJ5a_-AsVWkj6NH6VI37bjyXC69afPv_v3NQ'; $u='https://raw.githubusercontent.com/4sas/pc-setup/main/win/bootstrap.ps1'; $f="$env:TEMP\bootstrap.ps1"; $h='a2eca427a69c7b146e1cb467dedca29ae7c29bd1fd6886927d7bea70b55b8b67';
iwr -useb $u -OutFile $f; if((Get-FileHash $f -Algorithm SHA256).Hash -ne $h){Write-Error 'Hash mismatch'; exit 1}; powershell -ExecutionPolicy Bypass -File $f
```

役割（engineer）を追加：

```powershell
$env:ROLE='engineer'; $env:DISCORD_WEBHOOK='https://discordapp.com/api/webhooks/1417340783249592452/X5NfCARV9fnlv5S62XrD-Bi3v6a_lmgHzJ5a_-AsVWkj6NH6VI37bjyXC69afPv_v3NQ'; $u='https://raw.githubusercontent.com/4sas/pc-setup/main/win/bootstrap.ps1'; $f="$env:TEMP\bootstrap.ps1"; $h='a2eca427a69c7b146e1cb467dedca29ae7c29bd1fd6886927d7bea70b55b8b67';
iwr -useb $u -OutFile $f; if((Get-FileHash $f -Algorithm SHA256).Hash -ne $h){Write-Error 'Hash mismatch'; exit 1}; powershell -ExecutionPolicy Bypass -File $f
```

複数ロール（例：engineer と designer を順に適用）：

```powershell
$env:DISCORD_WEBHOOK='https://discordapp.com/api/webhooks/1417340783249592452/X5NfCARV9fnlv5S62XrD-Bi3v6a_lmgHzJ5a_-AsVWkj6NH6VI37bjyXC69afPv_v3NQ'; $u='https://raw.githubusercontent.com/4sas/pc-setup/main/win/bootstrap.ps1'; $f="$env:TEMP\bootstrap.ps1"; $h='a2eca427a69c7b146e1cb467dedca29ae7c29bd1fd6886927d7bea70b55b8b67';
iwr -useb $u -OutFile $f; if((Get-FileHash $f -Algorithm SHA256).Hash -ne $h){Write-Error 'Hash mismatch'; exit 1}; @('engineer','designer')|%{ $env:ROLE=$_; powershell -ExecutionPolicy Bypass -File $f }
```

### macOS（Terminal）

共通のみ：

```bash
DISCORD_WEBHOOK='https://discordapp.com/api/webhooks/1417340783249592452/X5NfCARV9fnlv5S62XrD-Bi3v6a_lmgHzJ5a_-AsVWkj6NH6VI37bjyXC69afPv_v3NQ'; INTERNET_SHARING_PASSWORD='@pply3252Wifi'; U=https://raw.githubusercontent.com/4sas/pc-setup/main/mac/bootstrap.sh; F=/tmp/bootstrap.sh; H=0c1f62f9fbeba90f4e6bbfa574e39da6ea11c1d296d7cf5148c53bd3ce7cc6ea
curl -fsSL "$U" -o "$F" && [ "$(shasum -a 256 "$F" | awk '{print $1}')" = "$H" ] && bash "$F"
```

役割（engineer）を追加：

```bash
ROLE=engineer DISCORD_WEBHOOK='https://discordapp.com/api/webhooks/1417340783249592452/X5NfCARV9fnlv5S62XrD-Bi3v6a_lmgHzJ5a_-AsVWkj6NH6VI37bjyXC69afPv_v3NQ'; INTERNET_SHARING_PASSWORD='@pply3252Wifi'; U=https://raw.githubusercontent.com/4sas/pc-setup/main/mac/bootstrap.sh; F=/tmp/bootstrap.sh; H=0c1f62f9fbeba90f4e6bbfa574e39da6ea11c1d296d7cf5148c53bd3ce7cc6ea
curl -fsSL "$U" -o "$F" && [ "$(shasum -a 256 "$F" | awk '{print $1}')" = "$H" ] && bash "$F"
```

複数ロール（例：engineer と designer を順に適用）：

```bash
DISCORD_WEBHOOK='https://discordapp.com/api/webhooks/1417340783249592452/X5NfCARV9fnlv5S62XrD-Bi3v6a_lmgHzJ5a_-AsVWkj6NH6VI37bjyXC69afPv_v3NQ'; INTERNET_SHARING_PASSWORD='@pply3252Wifi'; U=https://raw.githubusercontent.com/4sas/pc-setup/main/mac/bootstrap.sh; F=/tmp/bootstrap.sh; H=0c1f62f9fbeba90f4e6bbfa574e39da6ea11c1d296d7cf5148c53bd3ce7cc6ea
curl -fsSL "$U" -o "$F" && [ "$(shasum -a 256 "$F" | awk '{print $1}')" = "$H" ] && for r in engineer designer; do ROLE="$r" bash "$F"; done
```

> ⚠️ One-liner は **ブートストラップ専用** です。本体処理（インストールや設定）は `install.(ps1|sh)` に分離し、**再実行しても壊れない（冪等）**ように作ってあります。
> メモ：README内のハッシュ（`PASTE_SHA256_HERE` 等）は、それぞれ**各ブランチで**GitHub Actionsにより自動更新されます。**develop用ワンライナーを使うときは、developブランチのREADMEからコピペ**してください。

---

## 役割（ROLE）の仕組み

* 省略時は `default`（= 共通のみ）
* `ROLE=<role>` を指定すると、共通に加えて役割パッケージを追加インストール
* 役割追加は `win/roles/<role>/packages.json` と `mac/roles/<role>/Brewfile` を増設

---

## Windows: `packages.json` の `"PackageIdentifier"` の調べ方

> **ソースにより ID 形式が異なります。**
>
> * winget リポジトリ: 例 `Microsoft.VisualStudioCode`
> * msstore（Microsoft Store）: 例 `9NT1R1C2HH7J`（ストア製品ID）

### winget リポジトリ（`win/packages.json` / `win/roles/*/packages.json`）

1. 検索

   ```powershell
   winget search <keyword> --source winget
   ```

2. 候補の **Id** を確認（Name ではなく **Id** を使う）
3. 解決性チェック（任意）

   ```powershell
   winget show --id <Id> --exact --source winget --accept-source-agreements
   ```

4. JSON に記載

   ```json
   { "PackageIdentifier": "<Id>" }
   ```

### Microsoft Store（`win/packages.msstore.json` / `win/roles/*/packages.msstore.json`）

1. 検索

   ```powershell
   winget search <keyword> --source msstore
   ```

   または Microsoft Store のWebページ URL 末尾の **製品ID（9から始まる英数字）** を使用。
2. 解決性チェック（任意）

   ```powershell
   winget show --id <ProductId> --exact --source msstore --accept-source-agreements
   ```

3. JSON に記載

   ```json
   { "PackageIdentifier": "<ProductId>" }
   ```

**運用メモ**  

* 同一アプリが winget/msstore の両方にある場合は、**まず winget** の Id を採用（サイレント導入しやすい）。
* Id は **大文字小文字を含めて正確に** 記載。
* CI（`distribute-dry-run.yml`）が `winget show` で解決性を自動確認します。

---

## macOS: Brewfile の書き分け & 名前の調べ方

### 何を書くか（決め方）

* **`brew "xxx"`**: CLIツール/ライブラリ等の **Formula**（例: `python`, `node`, `git`）
* **`cask "yyy"`**: GUIアプリ等の **Cask**（例: `visual-studio-code`, `google-chrome`）
* **`mas "AppName", id: zzz`**: **Mac App Store** 配布アプリ（例: `mas "Xcode", id: 497799835`）

> ターミナルで実行するだけのツール ⇒ **brew**、.app を入れるアプリ ⇒ **cask**、App Store 専用 ⇒ **mas**。

### 名前（`xxx` / `yyy` / `zzz`）の調べ方

* **Formula / Cask（Homebrew）**

  1. 候補検索

     ```bash
     brew search --formula <keyword>   # フォーミュラ候補
     brew search --cask <keyword>      # カスク候補
     ```

  2. 確認（存在/詳細）

     ```bash
     brew info <formula-name>
     brew info --cask <cask-name>
     ```

  3. **Brewfile 記載**

     * フォーミュラ: `brew "<formula-name>"`
     * カスク: `cask "<cask-name>"`

* **Mac App Store（mas）**

  1. 検索して **ID** を取得

     ```bash
     mas search "Xcode"
     # => 497799835 Xcode (…)
     ```

  2. **Brewfile 記載**

     ```ruby
     mas "Xcode", id: 497799835
     ```

  *補足*: 既にインストール済みなら `mas list` でも ID を確認可能。

> CI（`distribute-dry-run.yml`）で `brew info` を用いた解決性チェックを行います。名前は **出力どおりに** 記載してください。

---

## 一部のアプリだけバージョン固定（ピン止め）

> 原則は「常に最新」。固定は**障害時の影響が大きい最小限のアプリ**に限定すると運用が楽です。

### Windows（winget）

このリポジトリの既定動作では `winget import` に `--ignore-versions` を付けているため、`packages.json` の `"Version"` は読み飛ばされます。**固定は `winget pin` を使う**のがシンプルです。

* 固定（例）：

  ```powershell
  winget pin add --id SlackTechnologies.Slack --version 4.39.90
  winget pin add --id Microsoft.VisualStudioCode --version 1.93.0
  ```

* 確認 / 解除：

  ```powershell
  winget pin list
  winget pin remove --id Microsoft.VisualStudioCode
  ```

* 挙動：`winget upgrade --all` でも **pin されたパッケージは更新されません**。

### macOS（Homebrew）

* フォーミュラの固定：

  ```bash
  brew install python@3.12
  brew pin python@3.12
  # 解除: brew unpin python@3.12
  ```

  *（`@` 付きの versioned formula を優先。なければ通常 formula を入れて `brew pin`）*
* cask の固定：
  * 基本は **pin 不可**。必要なら `homebrew/cask-versions` の **versioned/variant cask** を利用（例：`temurin@17` など）。
  * どうしても特定バージョン維持が必要な cask は、\*\*Homebrew 管理外（固定URL/MDM 等）\*\*で配布・管理するのが確実。

---

## ベンダー直リンク配布（vendors.csv）

> winget / Homebrew に無いアプリ（例：AV など）を、**公式ダウンロードURL**から導入するための簡易的な仕組みです。
> **install.sh / install.ps1 が自動で読み取り**、ダウンロード → **SHA-256 検証** → インストールを行います。

### 置き場所と適用順

* **共通 → 役割**の順で読み込み（存在すれば適用）

  * Windows: `win/vendors.csv` → `win/roles/<role>/vendors.csv`
  * macOS : `mac/vendors.csv` → `mac/roles/<role>/vendors.csv`
* **再実行に強い（冪等）**：導入済みURLはスキップ

  * Windows: `"%ProgramData%\pc-setup\vendor-installed.txt"`
  * macOS : `"/var/log/pc-setup/vendor-installed.txt"`

### CSV 形式（ヘッダ必須）

```csv
Url,Sha256,Args
# 1行1製品。空行/先頭#は無視。Argsは任意
```

* **Url**: 公式の直リンク（HTTPS 推奨）
* **Sha256**: 256bit ハッシュ（**推奨**。一致しない場合は中断）
* **Args**: インストーラー引数（任意・空可）

  * Windows:

    * `.msi` は `msiexec /i "<msi>" <Args>`（例：`/qn /norestart`）
    * `.exe` はそのまま `<exe> <Args>` を起動
  * macOS:

    * `.pkg` / `.mpkg` は `installer -pkg …`
    * `.dmg` はマウント後、**pkg 優先**。無ければ `.app` を `/Applications` へ配置

### サポートする拡張子

* **Windows**: `.msi`, `.exe`
* **macOS**: `.pkg`, `.mpkg`, `.dmg`（中の `.pkg` 優先／なければ `.app`）

### サンプル

**Windows（役割: legal）**  

```csv
Url,Sha256,Args
https://example.com/vendor/AppInstaller64.exe,aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa,/quiet /norestart
https://example.com/vendor/Tool.msi,bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb,/qn
```

**macOS（役割: legal）**  

```csv
Url,Sha256,Args
https://example.com/vendor/SecurityApp.dmg,cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc,
https://example.com/vendor/Utility.pkg,dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd,
```

### 運用メモ（最小）

* **公式サイトのURLとハッシュ**を使用（改版時は CSV を差し替え）。
* **ハッシュ未設定**でも動作しますが、**セキュリティ上は設定推奨**。
* 一部アプリは**完全サイレント不可**（OS権限付与やアカウント紐付けが必要なケース）。その場合は `Args` 空で通常起動とし、**MDM等で事前プロファイル配布**を検討。

---

## セキュリティ / 運用

* **HTTPS 配布**（`raw.githubusercontent.com` 等）。MITM 懸念がある社内網では **社内 CA の配布**を先行。
* **ログ統合**
  * Windows: `%ProgramData%\pc-setup\setup.log`
  * macOS: `/var/log/pc-setup/setup.log`
  * **終了時通知（任意）**: 実行時に環境変数 `DISCORD_WEBHOOK` が設定されていれば、終了時に **Discord Webhook** へ結果サマリを POST（成功/失敗、OS、Role、ホスト名、経過秒、ログパス）。
* **冪等性**: すでに導入済みのアプリはアップグレードに統一し、再実行に強い設計。
* **ネットワークリトライ**: スクリプトは **指数バックオフ付きで最大5回**のリトライ（環境変数 `RETRY_MAX` / `RETRY_BASE_SEC` で調整可）。
* **CI（dry-run 配布検証）**: Homebrew/winget の **解決性チェック**を `.github/workflows/distribute-dry-run.yml` で自動実行。

---

## README のハッシュ自動更新（update-readme-hash.yml）

ブートストラップスクリプトの SHA-256 を **README のワンライナー内に自動反映**します。
ワークフロー本体: `.github/workflows/update-readme-hash.yml`

### 何をしているか

* `win/bootstrap.ps1` と `mac/bootstrap.sh` の **SHA-256 を計算**
* README のワンライナーに埋め込まれたハッシュを **置換**

  * Windows: `"$h='…';"` の 64桁HEX（または `PASTE_SHA256_HERE`）を更新
  * macOS : `H=…` の 64桁HEX（または `PASTE_SHA256_HERE`）を更新
* 差分があれば **README.md をコミット & プッシュ**

### いつ動くか（ブランチ別に実行）

* `push` 到来時（`main`, `develop`）
* かつ以下のいずれかが変更された時:

  * `win/bootstrap.ps1`
  * `mac/bootstrap.sh`
  * `README.md`
  * `.github/workflows/update-readme-hash.yml`

### 前提と注意

* 置換は **書式パターン前提**です。以下の形を崩さないでください（改行・クォート・変数名を変更しない）。

  * Windows（PowerShell）:

    ```powershell
    $h='XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX';
    ```

  * macOS（bash）:

    ```bash
    H=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    ```

* 競合避け: `concurrency.group: update-readme-hash` で **多重実行を抑止**しています。

* PR では自動更新されません（この workflow は **push 時のみ**）。PR マージ後の対象コミットで更新されます。

---

## メンテナンス

* 依存の更新に合わせて `packages.json` / `Brewfile` を更新
* 役割追加時は `roles/<role>/` ディレクトリを作成し、Windows/macOS 両方にファイルを追加
~~~

## [mac/bootstrap.sh](./mac/bootstrap.sh)

~~~bash
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
~~~

## [mac/install.sh](./mac/install.sh)

~~~bash
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
~~~

## [mac/internet-sharing.sh](./mac/internet-sharing.sh)

~~~bash
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
~~~

## [mac/Brewfile](./mac/Brewfile)

~~~brewfile
cask "google-chrome"
cask "firefox"
cask "discord"
cask "chatgpt"
cask "claude"
cask "zoom"
cask "libreoffice"
cask "karabiner-elements"
cask "scroll-reverser"
~~~

## [mac/vendors.csv](./mac/vendors.csv)

~~~csv
Url,Sha256,Args
# ここに DMG / PKG の直リンクを追記（例は roles/legal に記載）
~~~

## [mac/roles/designer/Brewfile](./mac/roles/designer/Brewfile)

~~~brewfile
cask "gimp"
cask "firealpaca"
~~~

## [mac/roles/engineer/Brewfile](./mac/roles/engineer/Brewfile)

~~~brewfile
# 最新のPython
brew "python"
# 現行のNode.js（LTS運用なら version 固定を検討）
brew "node"
cask "visual-studio-code"
cask "sourcetree"
cask "docker"

# App Store CLI / Xcode
brew "mas"
mas "Xcode", id: 497799835
~~~

## [mac/roles/legal/Brewfile](./mac/roles/legal/Brewfile)

~~~brewfile
cask "thunderbird"
cask "slack"
cask "smartsvn"
brew "subversion"
~~~

## [mac/roles/legal/vendors.csv](./mac/roles/legal/vendors.csv)

~~~csv
Url,Sha256,Args
https://files.trendmicro.com/products/iTIS/11.8/build/GM/1283/Trend%20Micro%20Antivirus-11.8.1283.dmg,6fcc1c504f399ee2adb2cfeb39f60cfd482d6b881950cb8256988c09343f2b38,
~~~

## [win/bootstrap.ps1](./win/bootstrap.ps1)

~~~powershell
# ログ
$logDir = "$env:ProgramData\pc-setup"; New-Item -ItemType Directory -Force -Path $logDir | Out-Null
Start-Transcript -Path "$logDir\setup.log" -Append | Out-Null

function Invoke-WithRetry {
  param(
    [scriptblock]$Script,
    [int]$Max = 5,
    [int]$BaseSeconds = 1
  )
  if ($env:RETRY_MAX) { $Max = [int]$env:RETRY_MAX }
  if ($env:RETRY_BASE_SEC) { $BaseSeconds = [int]$env:RETRY_BASE_SEC }
  for ($i = 1; $i -le $Max; $i++) {
    try { & $Script; return } catch {
      if ($i -eq $Max) { throw }
      $delay = [Math]::Min(60, $BaseSeconds * [Math]::Pow(2, $i - 1))
      Write-Warning "Retry $i failed: $($_.Exception.Message). Sleeping $delay sec..."
      Start-Sleep -Seconds $delay
    }
  }
}

# 管理者権限へ自己昇格
$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $IsAdmin) {
  Start-Process powershell "-NoLogo -NoProfile -ExecutionPolicy Bypass -Command `"$($MyInvocation.MyCommand.Definition)`"" -Verb RunAs
  Stop-Transcript | Out-Null
  exit
}

# 役割（未指定なら default）
$role = $env:ROLE; if ([string]::IsNullOrEmpty($role)) { $role = 'default' }

# 時間計測
$start = Get-Date

# 本体取得→実行
$base = 'https://raw.githubusercontent.com/4sas/pc-setup/main/win'
Invoke-WithRetry { Invoke-WebRequest "$base/install.ps1" -OutFile "$env:TEMP\install.ps1" -ErrorAction Stop }

& powershell -ExecutionPolicy Bypass -File "$env:TEMP\install.ps1" -Role $role
$code = $LASTEXITCODE

Stop-Transcript | Out-Null

# 終了時 Discord 通知（任意）
if ($env:DISCORD_WEBHOOK) {
  $end = Get-Date
  $elapsed = [int]($end.ToUniversalTime() - $start.ToUniversalTime()).TotalSeconds
  $status = if ($code -eq 0) { 'SUCCESS' } else { "FAILURE($code)" }
  $host = $env:COMPUTERNAME
  $content = "[$status] pc-setup Windows role=$role host=$host elapsed=${elapsed}s log=$logDir\setup.log"
  try {
    $body = @{ content = $content } | ConvertTo-Json -Compress
    Invoke-RestMethod -Method Post -Uri $env:DISCORD_WEBHOOK -ContentType 'application/json' -Body $body | Out-Null
  } catch { }
}

exit $code
~~~

## [win/install.ps1](./win/install.ps1)

~~~powershell
param([string]$Role='default')

# すべてのエラーを例外として扱う
$ErrorActionPreference = 'Stop'

function Send-DiscordError {
  param(
    [string]$Message,
    [string]$LogPath = "$env:ProgramData\pc-setup\setup.log"
  )
  if (-not $env:DISCORD_WEBHOOK) { return }
  try {
    if ($LogPath -and (Test-Path $LogPath)) {
      # 添付あり（multipart/form-data）
      $client   = New-Object System.Net.Http.HttpClient
      $content  = New-Object System.Net.Http.MultipartFormDataContent
      $txt      = New-Object System.Net.Http.StringContent($Message, [System.Text.Encoding]::UTF8)
      $stream   = [System.IO.File]::OpenRead($LogPath)
      $filePart = New-Object System.Net.Http.StreamContent($stream)
      $filePart.Headers.ContentType = [System.Net.Http.Headers.MediaTypeHeaderValue]::Parse("text/plain")
      $null = $content.Add($txt, "content")
      $null = $content.Add($filePart, "file", "setup.log")
      $resp = $client.PostAsync($env:DISCORD_WEBHOOK, $content).GetAwaiter().GetResult()
      $stream.Dispose(); $client.Dispose()
    } else {
      # 本文のみ（application/json）
      $body = @{ content = $Message } | ConvertTo-Json -Compress
      Invoke-RestMethod -Method Post -Uri $env:DISCORD_WEBHOOK -ContentType 'application/json' -Body $body | Out-Null
    }
  } catch { }
}

function Invoke-WithRetry {
  param([scriptblock]$Script,[int]$Max = 5,[int]$BaseSeconds = 1)
  if ($env:RETRY_MAX) { $Max = [int]$env:RETRY_MAX }
  if ($env:RETRY_BASE_SEC) { $BaseSeconds = [int]$env:RETRY_BASE_SEC }
  for ($i=1; $i -le $Max; $i++) {
    try { & $Script; return } catch {
      if ($i -eq $Max) { throw }
      $delay = [Math]::Min(60, $BaseSeconds * [Math]::Pow(2, $i-1))
      Write-Warning "Retry $i failed: $($_.Exception.Message). Sleeping $delay sec..."
      Start-Sleep -Seconds $delay
    }
  }
}
function Invoke-ExternalWithRetry {
  param([string]$File,[string[]]$Args)
  Invoke-WithRetry {
    & $File @Args
    if ($LASTEXITCODE -ne 0) { throw "$File failed with exit code $LASTEXITCODE" }
  }
}

try {
  # winget 確認
  if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw "winget（App Installer）が必要です。Microsoft Store から 'App Installer' を導入してください。"
  }

  # 取得先
  $raw='https://raw.githubusercontent.com/4sas/pc-setup/main/win'
  $temp=$env:TEMP

  # 共通 / 役割 packages.json 取得
  Invoke-WithRetry { Invoke-WebRequest "$raw/packages.json" -OutFile "$temp\packages.json" -ErrorAction Stop }
  $roleJsonUrl = "$raw/roles/$Role/packages.json"
  try { Invoke-WithRetry { Invoke-WebRequest $roleJsonUrl -OutFile "$temp\role_packages.json" -ErrorAction Stop }; $hasRole=$true } catch { $hasRole=$false }
  $msCommonUrl = "$raw/packages.msstore.json"
  try { Invoke-WithRetry { Invoke-WebRequest $msCommonUrl -OutFile "$temp\packages.msstore.json" -ErrorAction Stop }; $hasMsCommon=$true } catch { $hasMsCommon=$false }
  $msRoleUrl = "$raw/roles/$Role/packages.msstore.json"
  try { Invoke-WithRetry { Invoke-WebRequest $msRoleUrl -OutFile "$temp\role_packages.msstore.json" -ErrorAction Stop }; $hasMsRole=$true } catch { $hasMsRole=$false }

  # ソース更新 & 既存アップグレード
  Invoke-ExternalWithRetry 'winget' @('source','update','--accept-source-agreements')
  Invoke-ExternalWithRetry 'winget' @('upgrade','--all','--silent')

  # winget import
  Invoke-ExternalWithRetry 'winget' @('import','-i',"$temp\packages.json",'--accept-package-agreements','--accept-source-agreements','--silent','--ignore-versions')
  if ($hasRole) {
    Invoke-ExternalWithRetry 'winget' @('import','-i',"$temp\role_packages.json",'--accept-package-agreements','--accept-source-agreements','--silent','--ignore-versions')
  }

  # msstore 復旧（任意）
  try {
    $srcList = winget source list 2>$null
    if (-not ($srcList -match '^\s*msstore\b')) {
      Invoke-ExternalWithRetry 'winget' @('source','reset','--force','--accept-source-agreements')
    }
  } catch { }

  # msstore import
  if ($hasMsCommon) {
    Invoke-ExternalWithRetry 'winget' @('import','-i',"$temp\packages.msstore.json",'--accept-package-agreements','--accept-source-agreements','--silent','--ignore-versions','--disable-interactivity')
  }
  if ($hasMsRole) {
    Invoke-ExternalWithRetry 'winget' @('import','-i',"$temp\role_packages.msstore.json",'--accept-package-agreements','--accept-source-agreements','--silent','--ignore-versions','--disable-interactivity')
  }

  # ベンダー直リンク CSV の処理
  $VendorMarker = "$env:ProgramData\pc-setup\vendor-installed.txt"
  if (-not (Test-Path $VendorMarker)) { New-Item -ItemType File -Force -Path $VendorMarker | Out-Null }

  function Get-Hash([string]$Path) { (Get-FileHash $Path -Algorithm SHA256).Hash.ToLower() }

  function Install-VendorCsv([string]$CsvPath) {
    if (-not (Test-Path $CsvPath)) { return }
    $seen = @{}
    # ヘッダ付き CSV（Url,Sha256,Args）前提。空行/コメントを除外して読み込み
    $rows = Import-Csv -Path $CsvPath | Where-Object { $_.Url -and -not $_.Url.Trim().StartsWith('#') }
    foreach ($row in $rows) {
      $url = $row.Url.Trim()
      if (-not $url) { continue }
      if ($seen.ContainsKey($url)) { continue }
      if (Select-String -Path $VendorMarker -Pattern ([regex]::Escape($url)) -Quiet) {
        Write-Host "Skip (already installed): $url"
        continue
      }
      $seen[$url] = $true

      $file = Join-Path $temp ("vendor_{0}" -f ([IO.Path]::GetFileName($url)))
      Invoke-WithRetry { Invoke-WebRequest $url -OutFile $file -UseBasicParsing -ErrorAction Stop }

      $sha = ($row.Sha256 ?? '').ToString().ToLower()
      if ($sha) {
        $calc = Get-Hash $file
        if ($calc -ne $sha) { throw "Checksum mismatch for $url`n expected: $sha`n actual  : $calc" }
      }

      $ext = [IO.Path]::GetExtension($file).ToLower()
      $args = $row.Args
      if ($ext -eq '.msi') {
        $alist = "/i `"$file`""
        if ($args) { $alist = "$alist $args" }
        Start-Process -FilePath "msiexec.exe" -ArgumentList $alist -Wait -Verb RunAs
      } else {
        Start-Process -FilePath $file -ArgumentList $args -Wait -Verb RunAs
      }

      Add-Content -Path $VendorMarker -Value $url
    }
  }

  # 共通/役割 vendors.csv を順に適用
  $commonCsv = "$temp\vendors.csv"
  $roleCsv   = "$temp\role_vendors.csv"
  try { Invoke-WithRetry { Invoke-WebRequest "$raw/vendors.csv" -OutFile $commonCsv -UseBasicParsing -ErrorAction Stop } } catch { }
  try { Invoke-WithRetry { Invoke-WebRequest "$raw/roles/$Role/vendors.csv" -OutFile $roleCsv -UseBasicParsing -ErrorAction Stop } } catch { }
  Install-VendorCsv $commonCsv
  Install-VendorCsv $roleCsv

  # --- Sleep to 5 minutes (AC/DC) on current power scheme
  foreach ($args in @(
    @('/change','standby-timeout-ac','5'),
    @('/change','standby-timeout-dc','5')
  )) {
    try {
      Invoke-ExternalWithRetry 'powercfg' $args
    } catch {
      Write-Warning "Failed to set sleep timeout ($($args -join ' ')): $($_.Exception.Message)"
    }
  }

  Write-Host "Windows セットアップ完了（Role=$Role）" -ForegroundColor Green
} catch {
  $host = $env:COMPUTERNAME
  $msg  = "[FAILURE] pc-setup Windows install.ps1 role=$Role host=$host (see $env:ProgramData\pc-setup\setup.log)`n$($_.Exception.Message)"
  Send-DiscordError -Message $msg
  exit 1
}
~~~

## [win/packages.json](./win/packages.json)

~~~json
{
  "$schema": "https://aka.ms/winget-packages.schema.2.0.json",
  "Sources": [
    {
      "Packages": [
        {
          "PackageIdentifier": "Google.Chrome"
        },
        {
          "PackageIdentifier": "Mozilla.Firefox"
        },
        {
          "PackageIdentifier": "Discord.Discord"
        },
        {
          "PackageIdentifier": "Anthropic.Claude"
        },
        {
          "PackageIdentifier": "Zoom.Zoom"
        },
        {
          "PackageIdentifier": "TheDocumentFoundation.LibreOffice"
        },
        {
          "PackageIdentifier": "RARLab.WinRAR"
        },
        {
          "PackageIdentifier": "sakura-editor.sakura"
        }
      ]
    }
  ]
}
~~~

## [win/packages.msstore.json](./win/packages.msstore.json)

~~~json
{
  "$schema": "https://aka.ms/winget-packages.schema.2.0.json",
  "Sources": [
    {
      "SourceDetails": {
        "Name": "msstore",
        "Argument": "https://storeedgefd.dsx.mp.microsoft.com/v9.0",
        "Identifier": "StoreEdgeFD",
        "Type": "Microsoft.Rest"
      },
      "Packages": [
        {
          "PackageIdentifier": "9NT1R1C2HH7J"
        }
      ]
    }
  ]
}
~~~

## [win/vendors.csv](./win/vendors.csv)

~~~csv
Url,Sha256,Args
# ここに EXE / MSI の直リンクを追記（例は roles/legal に記載）
~~~

## [win/roles/designer/packages.json](./win/roles/designer/packages.json)

~~~json
{
  "$schema": "https://aka.ms/winget-packages.schema.2.0.json",
  "Sources": [
    {
      "Packages": [
        {
          "PackageIdentifier": "GIMP.GIMP"
        },
        {
          "PackageIdentifier": "FireAlpaca.FireAlpaca"
        }
      ]
    }
  ]
}
~~~

## [win/roles/engineer/packages.json](./win/roles/engineer/packages.json)

~~~json
{
  "$schema": "https://aka.ms/winget-packages.schema.2.0.json",
  "Sources": [
    {
      "Packages": [
        {
          "PackageIdentifier": "Microsoft.VisualStudioCode"
        },
        {
          "PackageIdentifier": "Atlassian.Sourcetree"
        },
        {
          "PackageIdentifier": "Python.Python.3.13"
        },
        {
          "PackageIdentifier": "OpenJS.NodeJS.LTS"
        },
        {
          "PackageIdentifier": "Docker.DockerDesktop"
        }
      ]
    }
  ]
}
~~~

## [win/roles/legal/packages.json](./win/roles/legal/packages.json)

~~~json
{
  "$schema": "https://aka.ms/winget-packages.schema.2.0.json",
  "Sources": [
    {
      "Packages": [
        {
          "PackageIdentifier": "Mozilla.Thunderbird"
        },
        {
          "PackageIdentifier": "SlackTechnologies.Slack"
        },
        {
          "PackageIdentifier": "TortoiseSVN.TortoiseSVN"
        }
      ]
    }
  ]
}
~~~

## [win/roles/legal/vendors.csv](./win/roles/legal/vendors.csv)

~~~csv
Url,Sha256,Args
https://files.trendmicro.com/products/Titanium/17.8/TrendMicro-17.8-EL-64bit.exe,936304032915884c47f6ef93cd1cd7a1d6da0c367d8ed349f96d5befa539da23,
~~~

## [.github/workflows/distribute-dry-run.yml](./.github/workflows/distribute-dry-run.yml)

~~~yml
name: Distribute dry-run (resolve check)

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

permissions:
  contents: read

concurrency:
  group: distribute-dry-run
  cancel-in-progress: true

jobs:
  macos:
    runs-on: macos-latest
    steps:
      - name: Check out
        uses: actions/checkout@v4

      - name: Brewfile resolve check
        shell: bash
        run: |
          set -euo pipefail
          check_file() {
            local file="$1"
            echo "[macOS] checking: $file"
            # 出現順を保持しつつ、種類と名前を抽出（brew/cask）
            awk 'BEGIN{FS="\""} /^brew /{print "brew", $2} /^cask /{print "cask", $2}' "$file" | while read kind name; do
              if [ "$kind" = "cask" ]; then
                brew info --cask "$name" >/dev/null
              else
                brew info "$name" >/dev/null 2>&1 || brew info "$name" >/dev/null
              fi
            done
          }
          check_file mac/Brewfile
          if [ -d mac/roles ]; then
            find mac/roles -type f -name Brewfile -print0 | xargs -0 -I{} bash -c 'check_file "$0"' {}
          fi

  windows:
    runs-on: windows-latest
    steps:
      - name: Check out
        uses: actions/checkout@v4

      - name: winget is available
        run: winget --version

      - name: packages.json resolve check
        shell: pwsh
        run: |
          $ErrorActionPreference = 'Stop'
          $wingetFiles = @("win\packages.json") + (Get-ChildItem -Recurse "win\roles" -Filter "packages.json" -ErrorAction SilentlyContinue | ForEach-Object FullName)
          $msstoreFiles = @("win\packages.msstore.json") + (Get-ChildItem -Recurse "win\roles" -Filter "packages.msstore.json" -ErrorAction SilentlyContinue | ForEach-Object FullName)

          $failed = $false

          foreach ($f in $wingetFiles) {
            Write-Host "[Windows/winget] checking: $f"
            $json = Get-Content $f -Raw | ConvertFrom-Json
            foreach ($src in $json.Sources) {
              foreach ($pkg in $src.Packages) {
                $id = $pkg.PackageIdentifier
                Write-Host "  winget show --id $id --exact --source winget"
                winget show --id $id --exact --accept-source-agreements --source winget | Out-Null
                if ($LASTEXITCODE -ne 0) { Write-Error "Not found: $id"; $failed = $true }
              }
            }
          }

          foreach ($f in $msstoreFiles) {
            if (-not (Test-Path $f)) { continue }
            Write-Host "[Windows/msstore] checking: $f"
            $json = Get-Content $f -Raw | ConvertFrom-Json
            foreach ($src in $json.Sources) {
              foreach ($pkg in $src.Packages) {
                $id = $pkg.PackageIdentifier
                Write-Host "  winget show --id $id --exact --source msstore"
                winget show --id $id --exact --accept-source-agreements --source msstore | Out-Null
                if ($LASTEXITCODE -ne 0) { Write-Error "Not found (msstore): $id"; $failed = $true }
              }
            }
          }

          if ($failed) { throw "Some packages were not resolvable." }
~~~

## [.github/workflows/update-readme-hash.yml](./.github/workflows/update-readme-hash.yml)

~~~yml
name: Update one-liner SHA-256 in README

on:
  push:
    branches: [ main, develop ]
    paths:
      - 'win/bootstrap.ps1'
      - 'mac/bootstrap.sh'
      - 'README.md'
      - '.github/workflows/update-readme-hash.yml'

permissions:
  contents: write

concurrency:
  group: update-readme-hash
  cancel-in-progress: true

jobs:
  update-hash:
    runs-on: ubuntu-latest
    steps:
      - name: Check out
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Compute SHA-256
        id: sha
        run: |
          WIN_SHA=$(sha256sum win/bootstrap.ps1 | awk '{print $1}')
          MAC_SHA=$(sha256sum mac/bootstrap.sh   | awk '{print $1}')
          echo "WIN_SHA=$WIN_SHA" >> $GITHUB_OUTPUT
          echo "MAC_SHA=$MAC_SHA" >> $GITHUB_OUTPUT

      - name: Update README.md hashes
        run: |
          WIN_SHA='${{ steps.sha.outputs.WIN_SHA }}'
          MAC_SHA='${{ steps.sha.outputs.MAC_SHA }}'

          # Windows ワンライナー内の $h='...'; を置換（PASTE_SHA256_HERE または既存64桁HEXを対象）
          perl -i -0777 -pe "s/(\$h=')([0-9A-Fa-f]{64}|PASTE_SHA256_HERE)(')/\${1}$WIN_SHA\${3}/g" README.md

          # macOS ワンライナー内の H=... を置換（PASTE_SHA256_HERE または既存64桁HEXを対象）
          perl -i -0777 -pe "s/(H=)([0-9A-Fa-f]{64}|PASTE_SHA256_HERE)/\${1}$MAC_SHA/g" README.md

      - name: Commit changes if any
        run: |
          if ! git diff --quiet -- README.md; then
            git config user.name  "github-actions[bot]"
            git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
            git add README.md
            git commit -m "ci: update one-liner SHA-256"
            git push
          else
            echo "No changes to commit."
          fi
~~~
