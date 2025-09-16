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
