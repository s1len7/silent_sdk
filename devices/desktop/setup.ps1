# silent_sdk full setup: get this repo into ~\silent_sdk, then run every setup step.
#   irm https://raw.githubusercontent.com/s1len7/silent_sdk/main/devices/desktop/setup.ps1 | iex
# ASCII-only so it works both via `irm | iex` and `-File` on Windows PowerShell 5.1.

$ErrorActionPreference = 'Stop'
$repo = 'https://github.com/s1len7/silent_sdk'
$dir  = "$HOME\silent_sdk"

# Re-launch as admin
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $run = if ($PSCommandPath) { "-File `"$PSCommandPath`"" } else { "-Command irm https://raw.githubusercontent.com/s1len7/silent_sdk/main/devices/desktop/setup.ps1 | iex" }
    try {
        Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass $run"
    } catch {
        # Elevation is refused e.g. over SSH (no UAC prompt) or when the account is not an administrator.
        # return, not exit: under irm | iex, exit would close the window before the message can be read
        Write-Host "ERROR: could not restart as administrator: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host 'Open PowerShell as administrator (Win+X > Terminal (Admin)) and run the same command again.'
        return
    }
    exit
}

# Allow the step .ps1 files in this session only: an admin window opened by hand skips the
# re-launch above and keeps the default policy, which blocks them (Restricted on Windows 10)
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

# Log everything from here; the log moves into <repo>\logs once the repo is available
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$bootstrapLog = "$env:TEMP\silent_sdk-desktop-$stamp.log"
Start-Transcript -Path $bootstrapLog | Out-Null

# Get repo with git: install Git first, then pull, or clone when the folder is missing or not a git clone
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
try {
    # Full path: a session opened before Git was installed does not have it on PATH
    $git = "$env:ProgramFiles\Git\cmd\git.exe"
    if (-not (Test-Path $git)) {
        # The Git step script is not on disk yet; run it from GitHub as a script block,
        # which also works when the execution policy blocks .ps1 files
        $gitSetup = Invoke-RestMethod 'https://raw.githubusercontent.com/s1len7/silent_sdk/main/devices/generic-windows/scripts/setup-git.ps1' -UseBasicParsing
        & ([scriptblock]::Create($gitSetup)) | Out-Host
        # The installer adds Git to the system PATH, but this session still has the old one
        $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
    }
    if (Test-Path "$dir\.git") {
        & $git -C $dir pull --ff-only | Out-Host
        if ($LASTEXITCODE -ne 0) { throw "git pull failed: exit code $LASTEXITCODE" }
    } else {
        # Clone next to the folder, then swap: a folder from an older zip download is replaced,
        # but what is not in git (logs, .env) is kept from the old folder
        $new = "$dir.new"
        $old = "$dir.old"
        Remove-Item $new, $old -Recurse -Force -ErrorAction SilentlyContinue
        & $git clone $repo $new | Out-Host
        if ($LASTEXITCODE -ne 0) { throw "git clone failed: exit code $LASTEXITCODE" }
        Set-Location $env:TEMP
        # Rename first: if the folder is in use this fails and the old files stay intact
        if (Test-Path $dir) { Rename-Item $dir (Split-Path $old -Leaf) }
        try {
            Move-Item $new $dir
        } catch {
            if (Test-Path $old) { Rename-Item $old (Split-Path $dir -Leaf) }
            throw
        }
        if (Test-Path $old) {
            if (Test-Path "$old\logs") { Copy-Item "$old\logs\*" "$dir\logs" -Recurse -Force }
            Get-ChildItem $old -Recurse -Force -File -Filter '.env' | ForEach-Object {
                $target = Join-Path $dir $_.FullName.Substring($old.Length)
                New-Item -ItemType Directory -Force (Split-Path $target) | Out-Null
                Copy-Item $_.FullName $target -Force
            }
            try { Remove-Item $old -Recurse -Force } catch { Write-Warning "Could not remove $old`: $($_.Exception.Message)" }
        }
    }
} catch {
    Write-Host "ERROR: getting the repo failed: $($_.Exception.Message)" -ForegroundColor Red
    if (-not (Test-Path "$dir\devices\generic-windows\scripts\lib-log.ps1")) {
        Stop-Transcript | Out-Null
        Read-Host "Setup aborted. Log: $bootstrapLog. Press Enter to exit"
        exit 1
    }
    Write-Warning "Continuing with the existing files in $dir"
}

. "$dir\devices\generic-windows\scripts\lib-log.ps1"
$logDir = Start-SetupLog $dir 'desktop' $stamp $bootstrapLog

# Setup steps: a failed step is logged and the next one still runs
$s = "$dir\devices\desktop\scripts"
# Shared modules used by every Windows device (winget/git/vscode/opencode) live in generic-windows
$g = "$dir\devices\generic-windows\scripts"
$results = @()
# Hostname first: it asks for the new name, so the rest runs without waiting for input
$results += Invoke-Step 'hostname'     { & "$s\setup-hostname.ps1" -Default 'silent-desktop' }
# Windows updates early, so the following installers run on an up-to-date system
$results += Invoke-Step 'windows-update' { & "$s\setup-windows-update.ps1" }
# RDP right after: no download, so remote access is available early
$results += Invoke-Step 'rdp'          { & "$s\setup-rdp.ps1" }
$results += Invoke-Step 'desktop-icons' { & "$s\setup-desktop-icons.ps1" }
$results += Invoke-Step 'chrome'       { & "$s\setup-chrome.ps1" }
# $results += Invoke-Step 'zoomit'     { & "$s\setup-zoomit.ps1" }  # PowerToys includes ZoomIt
$results += Invoke-Step 'powertoys'    { & "$s\setup-powertoys.ps1" }
$results += Invoke-Step 'winget'       { & "$g\setup-winget.ps1" }
$results += Invoke-Step 'pcmanager'    { & "$s\setup-pcmanager.ps1" }
$results += Invoke-Step 'sysinternals' { & "$s\setup-sysinternals.ps1" }
# Autologon right after Sysinternals, which provides Autologon64.exe; asks for the account password
$results += Invoke-Step 'autologon'    { & "$s\setup-autologon.ps1" }
$results += Invoke-Step 'git'          { & "$g\setup-git.ps1" }
$results += Invoke-Step 'python'       { & "$s\setup-python.ps1" }
$results += Invoke-Step 'vscode'       { & "$g\setup-vscode.ps1" }
$results += Invoke-Step 'vscode-extensions' { & "$g\setup-vscode-extensions.ps1" }
$results += Invoke-Step 'docker'       { & "$s\setup-docker.ps1" }
$results += Invoke-Step 'openclaw-gateway' { & "$s\setup-openclaw-gateway.ps1" }
# After the local Gateway, which the tray app connects to
$results += Invoke-Step 'openclaw-companion' { & "$s\setup-openclaw-companion.ps1" }
$results += Invoke-Step 'opencode'     { & "$g\setup-opencode.ps1" }
# After the agents are installed, so their config folders exist
$results += Invoke-Step 'agent-rules'  { & "$s\setup-agent-rules.ps1" }

Write-SetupSummary $results $logDir
Stop-Transcript | Out-Null
Read-Host 'Done. Reboot to apply the hostname, updates and Docker setup, then run the setup again if any step failed. Press Enter to exit'
