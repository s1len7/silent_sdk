# Setup Microsoft PC Manager (Store app 9PM860492SZD) via winget. Run as admin.
# Needs winget: setup-winget.ps1 runs before this step and installs it when missing (e.g. LTSC).

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# winget.exe: the per-user app alias, or whatever is on PATH
$winget = "$env:LOCALAPPDATA\Microsoft\WindowsApps\winget.exe"
if (-not (Test-Path $winget)) { $winget = (Get-Command winget -ErrorAction SilentlyContinue).Source }
if (-not $winget) { throw 'winget not found. Run setup-winget.ps1 first' }

# Already installed (winget list exits 0 when the package is found)
& $winget list --id 9PM860492SZD --exact --accept-source-agreements | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host 'PC Manager is already installed, skipped'
    $global:SetupStepSkipped = $true
    return
}

& $winget install --id 9PM860492SZD -s msstore --accept-package-agreements --accept-source-agreements
# -1978335189 (0x8A15002B): already installed / no newer version, treated as success
if ($LASTEXITCODE -notin 0, -1978335189) { throw "PC Manager setup failed: exit code $LASTEXITCODE" }
Write-Host 'PC Manager setup done'
