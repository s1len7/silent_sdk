# titan-s260 full setup: get silent_sdk into C:\silent_sdk, then run every titan-s260 setup step.
#   irm https://raw.githubusercontent.com/s1len7/silent_sdk/main/titan-s260/setup.ps1 | iex
# ASCII-only so it works both via `irm | iex` and `-File` on Windows PowerShell 5.1.

$ErrorActionPreference = 'Stop'
$repo = 'https://github.com/s1len7/silent_sdk'
$dir  = 'C:\silent_sdk'

# Re-launch as admin
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $run = if ($PSCommandPath) { "-File `"$PSCommandPath`"" } else { "-Command irm https://raw.githubusercontent.com/s1len7/silent_sdk/main/titan-s260/setup.ps1 | iex" }
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass $run"
    exit
}

# Log everything from here; the log moves into <repo>\logs once the repo is available
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$bootstrapLog = "$env:TEMP\silent_sdk-titan-s260-$stamp.log"
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
$logDir = Start-SetupLog $dir 'titan-s260' $stamp $bootstrapLog

# Setup steps (shared Windows scripts from windows\scripts): a failed step is logged and the next one still runs
$t = "$dir\titan-s260\scripts"
$w = "$dir\windows\scripts"
$results = @()
$results += Invoke-Step 'activation' {
    # The activation script reports failure by exit code, not by throwing
    & "$t\activate-win10-iot.ps1" -NoPause
    if ($LASTEXITCODE -ne 0) { throw "Activation failed: exit code $LASTEXITCODE" }
}
$results += Invoke-Step 'hostname'       { & "$w\setup-hostname.ps1" -Default 'titan-s260' }
# Windows updates early, so the following installers run on an up-to-date system
$results += Invoke-Step 'windows-update' { & "$w\setup-windows-update.ps1" }
# $results += Invoke-Step 'zoomit'       { & "$w\setup-zoomit.ps1" }  # PowerToys includes ZoomIt
$results += Invoke-Step 'powertoys'      { & "$w\setup-powertoys.ps1" }
$results += Invoke-Step 'winget'         { & "$w\setup-winget.ps1" }
$results += Invoke-Step 'pcmanager'      { & "$w\setup-pcmanager.ps1" }
$results += Invoke-Step 'performance'    { & "$t\setup-performance.ps1" }
$results += Invoke-Step 'touch-keyboard' { & "$t\setup-touch-keyboard.ps1" }

Write-SetupSummary $results $logDir
Stop-Transcript | Out-Null
Read-Host 'Done. Reboot to apply the updates, computer name and settings, then run the setup again if any step failed. Press Enter to exit'
