# Setup the latest Visual Studio Code (system installer x64, machine-wide). Run as admin.

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

$exe = "$env:TEMP\VSCodeSetup-x64.exe"
Invoke-WebRequest https://update.code.visualstudio.com/latest/win32-x64/stable -OutFile $exe -UseBasicParsing

# Tasks: no launch after install, add to PATH, Explorer "Open with Code", file associations
$tasks = '!runcode,addtopath,addcontextmenufiles,addcontextmenufolders,associatewithfiles'
$p = Start-Process $exe -ArgumentList "/VERYSILENT /NORESTART /SUPPRESSMSGBOXES /MERGETASKS=$tasks /LOG=`"$logDir\vscode-install.log`"" -Wait -PassThru
if ($p.ExitCode -ne 0) { throw "VS Code installer failed: exit code $($p.ExitCode)" }
Write-Host 'VS Code setup done'
