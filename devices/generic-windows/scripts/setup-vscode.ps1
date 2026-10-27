# Setup the latest Visual Studio Code (x64). Run as admin for the machine-wide install.
# -UserScope installs for the current user only (%LOCALAPPDATA%\Programs\Microsoft VS Code, no admin needed).
param([switch]$UserScope)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Installer logs go to the setup log folder (TEMP when run alone)
$logDir = if ($env:SILENT_SDK_LOG_DIR) { $env:SILENT_SDK_LOG_DIR } else { $env:TEMP }

# Already installed (system or per-user install): VS Code keeps itself up to date
$code = "$env:ProgramFiles\Microsoft VS Code\Code.exe", "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe" |
    Where-Object { Test-Path $_ } | Select-Object -First 1
if ($code) {
    Write-Host "VS Code is already installed, skipped: $code"
    $global:SetupStepSkipped = $true
    return
}

# win32-x64-user is the per-user installer, win32-x64 the machine-wide one
$url = if ($UserScope) { 'https://update.code.visualstudio.com/latest/win32-x64-user/stable' } else { 'https://update.code.visualstudio.com/latest/win32-x64/stable' }
$exe = "$env:TEMP\VSCodeSetup-x64.exe"
$expected = if ($UserScope) { "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe" } else { "$env:ProgramFiles\Microsoft VS Code\Code.exe" }
Invoke-WebRequest $url -OutFile $exe -UseBasicParsing

# Tasks: no launch after install, add to PATH, Explorer "Open with Code", file associations
$tasks = '!runcode,addtopath,addcontextmenufiles,addcontextmenufolders,associatewithfiles'
$p = Start-Process $exe -ArgumentList "/VERYSILENT /NORESTART /SUPPRESSMSGBOXES /MERGETASKS=$tasks /LOG=`"$logDir\vscode-install.log`"" -Wait -PassThru
if ($p.ExitCode -ne 0) { throw "VS Code installer failed: exit code $($p.ExitCode)" }
if (-not (Test-Path $expected)) { throw "Code.exe not found after install: $expected" }
Write-Host "VS Code setup done: $expected"
