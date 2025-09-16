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
$base = 'https://raw.githubusercontent.com/<org>/pc-setup/main/win'
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
