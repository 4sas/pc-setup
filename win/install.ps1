param([string]$Role='default')

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
function Invoke-ExternalWithRetry { param([string]$File,[string[]]$Args)
  Invoke-WithRetry { & $File @Args; if ($LASTEXITCODE -ne 0) { throw "$File failed with exit code $LASTEXITCODE" } }
}

# winget 確認
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
  Write-Error "winget（App Installer）が必要です。Microsoft Store から 'App Installer' を導入してください。"
  exit 1
}

# 取得先
$raw='https://raw.githubusercontent.com/<org>/pc-setup/main/win'
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
if ($hasRole) { Invoke-ExternalWithRetry 'winget' @('import','-i',"$temp\role_packages.json",'--accept-package-agreements','--accept-source-agreements','--silent','--ignore-versions') }

# msstore 復旧（任意）
try { $srcList = winget source list 2>$null; if (-not ($srcList -match '^\s*msstore\b')) { Invoke-ExternalWithRetry 'winget' @('source','reset','--force','--accept-source-agreements') } } catch { }

# msstore import
if ($hasMsCommon) { Invoke-ExternalWithRetry 'winget' @('import','-i',"$temp\packages.msstore.json",'--accept-package-agreements','--accept-source-agreements','--silent','--ignore-versions','--disable-interactivity') }
if ($hasMsRole)    { Invoke-ExternalWithRetry 'winget' @('import','-i',"$temp\role_packages.msstore.json",'--accept-package-agreements','--accept-source-agreements','--silent','--ignore-versions','--disable-interactivity') }

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
