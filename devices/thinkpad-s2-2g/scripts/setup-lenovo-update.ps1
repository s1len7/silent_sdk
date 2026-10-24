# Setup Lenovo System Update (drivers, BIOS and firmware updates for ThinkPad) via winget. Run as admin.
# Needs winget: setup-winget.ps1 runs before this step and installs it when missing.

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$id = 'Lenovo.SystemUpdate'

# winget.exe: the per-user app alias, or whatever is on PATH
$winget = "$env:LOCALAPPDATA\Microsoft\WindowsApps\winget.exe"
if (-not (Test-Path $winget)) { $winget = (Get-Command winget -ErrorAction SilentlyContinue).Source }
if (-not $winget) { throw 'winget not found. Run setup-winget.ps1 first' }

# Already installed (winget list exits 0 when the package is found)
& $winget list --id $id --exact --accept-source-agreements | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host 'Lenovo System Update is already installed, skipped'
    $global:SetupStepSkipped = $true
    return
}

& $winget install --id $id --exact -s winget --silent --accept-package-agreements --accept-source-agreements
# -1978335189 (0x8A15002B): already installed / no newer version, treated as success
if ($LASTEXITCODE -notin 0, -1978335189) { throw "Lenovo System Update setup failed: exit code $LASTEXITCODE" }
Write-Host 'Lenovo System Update setup done (run it from the Start menu to check for updates)'
