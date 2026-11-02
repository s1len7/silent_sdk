# Setup the latest Cursor IDE (official per-user installer). Run as admin is not required.
# Flow: read the newest Windows x64 user build from the download page -> silent Inno Setup install -> verify Cursor.exe

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Installer log goes to the setup log folder (TEMP when run alone); Inno Setup writes it with /LOG
$logDir = if ($env:SILENT_SDK_LOG_DIR) { $env:SILENT_SDK_LOG_DIR } else { $env:TEMP }

# Already installed per-user: Cursor updates itself
$cursor = "$env:LOCALAPPDATA\Programs\cursor\Cursor.exe"
if (Test-Path $cursor) {
    Write-Host "Cursor is already installed, skipped: $cursor"
    $global:SetupStepSkipped = $true
    return
}

# The download page lists the newest release first and its links carry a major.minor version,
# which the update endpoint maps to the newest patch (3.27 -> 3.27.22)
$page = Invoke-WebRequest -Uri 'https://cursor.com/download' -UseBasicParsing
$version = ([regex]::Match($page.Content, 'win32-x64-user/cursor/([0-9.]+)')).Groups[1].Value
if (-not $version) { throw 'Could not find the Cursor download link on https://cursor.com/download' }
$url = "https://api2.cursor.sh/updates/download/golden/win32-x64-user/cursor/$version"
$exe = "$env:TEMP\CursorUserSetup-x64.exe"
Invoke-WebRequest -Uri $url -OutFile $exe -UseBasicParsing

# Inno Setup: silent, no restart. No /TASKS: the installer task names are not documented
$p = Start-Process $exe -ArgumentList "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /LOG=`"$logDir\cursor-install.log`"" -Wait -PassThru
if ($p.ExitCode -notin 0, 3010) { throw "Cursor installer failed: exit code $($p.ExitCode)" }
if (-not (Test-Path $cursor)) { throw "Cursor.exe not found after install: $cursor" }
Write-Host "Cursor $version setup done: $cursor"
