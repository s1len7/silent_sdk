# silent_sdk full setup: get this repo into C:\silent_sdk, then run every setup step.
#   irm https://raw.githubusercontent.com/s1len7/silent_sdk/main/windows/setup.ps1 | iex
# ASCII-only so it works both via `irm | iex` and `-File` on Windows PowerShell 5.1.

$ErrorActionPreference = 'Stop'
$repo = 'https://github.com/s1len7/silent_sdk'
$dir  = 'C:\silent_sdk'

# Re-launch as admin
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $run = if ($PSCommandPath) { "-File `"$PSCommandPath`"" } else { "-Command irm https://raw.githubusercontent.com/s1len7/silent_sdk/main/windows/setup.ps1 | iex" }
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass $run"
    exit
}

# Log everything from here; the log moves into <repo>\logs once the repo is available
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$bootstrapLog = "$env:TEMP\silent_sdk-windows-$stamp.log"
Start-Transcript -Path $bootstrapLog | Out-Null

# Get repo (git if available, otherwise zip)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
try {
    if (Test-Path "$dir\.git") {
        git -C $dir pull --ff-only | Out-Host
        if ($LASTEXITCODE -ne 0) { throw "git pull failed: exit code $LASTEXITCODE" }
    } elseif (Get-Command git -ErrorAction SilentlyContinue) {
        git clone $repo $dir | Out-Host
        if ($LASTEXITCODE -ne 0) { throw "git clone failed: exit code $LASTEXITCODE" }
    } else {
        $zip = "$env:TEMP\silent_sdk.zip"
        Invoke-WebRequest "$repo/archive/refs/heads/main.zip" -OutFile $zip -UseBasicParsing
        Expand-Archive $zip $env:TEMP -Force
        New-Item -ItemType Directory -Force $dir | Out-Null
        Copy-Item "$env:TEMP\silent_sdk-main\*" $dir -Recurse -Force
    }
} catch {
    Write-Host "ERROR: getting the repo failed: $($_.Exception.Message)" -ForegroundColor Red
    if (-not (Test-Path "$dir\windows\scripts\lib-log.ps1")) {
        Stop-Transcript | Out-Null
        Read-Host "Setup aborted. Log: $bootstrapLog. Press Enter to exit"
        exit 1
    }
    Write-Warning "Continuing with the existing files in $dir"
}

. "$dir\windows\scripts\lib-log.ps1"
$logDir = Start-SetupLog $dir 'windows' $stamp $bootstrapLog

# Setup steps: a failed step is logged and the next one still runs
$s = "$dir\windows\scripts"
$results = @()
# RDP first: no download, so remote access is available as early as possible
$results += Invoke-Step 'rdp'          { & "$s\setup-rdp.ps1" }
$results += Invoke-Step 'chrome'       { & "$s\setup-chrome.ps1" }
# $results += Invoke-Step 'zoomit'     { & "$s\setup-zoomit.ps1" }  # PowerToys includes ZoomIt
$results += Invoke-Step 'powertoys'    { & "$s\setup-powertoys.ps1" }
$results += Invoke-Step 'winget'       { & "$s\setup-winget.ps1" }
$results += Invoke-Step 'pcmanager'    { & "$s\setup-pcmanager.ps1" }
$results += Invoke-Step 'sysinternals' { & "$s\setup-sysinternals.ps1" }
$results += Invoke-Step 'git'          { & "$s\setup-git.ps1" }
$results += Invoke-Step 'vscode'       { & "$s\setup-vscode.ps1" }
$results += Invoke-Step 'python'       { & "$s\setup-python.ps1" }
$results += Invoke-Step 'docker'       { & "$s\setup-docker.ps1" }

Write-SetupSummary $results $logDir
Stop-Transcript | Out-Null
Read-Host 'Done. Reboot to finish Docker setup. Press Enter to exit'
