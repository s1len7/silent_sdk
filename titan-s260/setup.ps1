# titan-s260 full setup: get this repo into C:\titan-s260, then run every setup step.
#   irm https://raw.githubusercontent.com/s1len7/titan-s260/main/setup.ps1 | iex
# ASCII-only so it works both via `irm | iex` and `-File` on Windows PowerShell 5.1.

$ErrorActionPreference = 'Stop'
$repo = 'https://github.com/s1len7/titan-s260'
$dir  = 'C:\titan-s260'

# Re-launch as admin
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $run = if ($PSCommandPath) { "-File `"$PSCommandPath`"" } else { "-Command irm https://raw.githubusercontent.com/s1len7/titan-s260/main/setup.ps1 | iex" }
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
    $zip = "$env:TEMP\titan-s260.zip"
    Invoke-WebRequest "$repo/archive/refs/heads/main.zip" -OutFile $zip -UseBasicParsing
    Expand-Archive $zip $env:TEMP -Force
    New-Item -ItemType Directory -Force $dir | Out-Null
    Copy-Item "$env:TEMP\titan-s260-main\*" $dir -Recurse -Force
}

# Setup steps
& "$dir\scripts\activate-win10-iot.ps1" -NoPause
# & "$dir\scripts\setup-zoomit.ps1"  # PowerToys includes ZoomIt
& "$dir\scripts\setup-powertoys.ps1"
& "$dir\scripts\setup-pcmanager.ps1"
& "$dir\scripts\setup-performance.ps1"

Read-Host 'Done. Press Enter to exit'
