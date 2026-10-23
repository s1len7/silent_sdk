# silent_sdk full setup: get this repo into C:\silent_sdk, then run every setup step.
#   irm https://raw.githubusercontent.com/s1len7/silent_sdk/main/setup.ps1 | iex
# ASCII-only so it works both via `irm | iex` and `-File` on Windows PowerShell 5.1.

$ErrorActionPreference = 'Stop'
$repo = 'https://github.com/s1len7/silent_sdk'
$dir  = 'C:\silent_sdk'

# Re-launch as admin
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $run = if ($PSCommandPath) { "-File `"$PSCommandPath`"" } else { "-Command irm https://raw.githubusercontent.com/s1len7/silent_sdk/main/setup.ps1 | iex" }
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass $run"
    exit
}

# Get repo (git if available, otherwise zip)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
if (Test-Path "$dir\.git") {
    git -C $dir pull --ff-only
} elseif (Get-Command git -ErrorAction SilentlyContinue) {
    git clone $repo $dir
} else {
    $zip = "$env:TEMP\silent_sdk.zip"
    Invoke-WebRequest "$repo/archive/refs/heads/main.zip" -OutFile $zip -UseBasicParsing
    Expand-Archive $zip $env:TEMP -Force
    New-Item -ItemType Directory -Force $dir | Out-Null
    Copy-Item "$env:TEMP\silent_sdk-main\*" $dir -Recurse -Force
}

# Setup steps
& "$dir\windows\scripts\setup-chrome.ps1"
# & "$dir\windows\scripts\setup-zoomit.ps1"  # PowerToys includes ZoomIt
& "$dir\windows\scripts\setup-powertoys.ps1"
& "$dir\windows\scripts\setup-pcmanager.ps1"
& "$dir\windows\scripts\setup-sysinternals.ps1"
& "$dir\windows\scripts\setup-git.ps1"
& "$dir\windows\scripts\setup-vscode.ps1"
& "$dir\windows\scripts\setup-docker.ps1"

Read-Host 'Done. Reboot to finish Docker setup. Press Enter to exit'
