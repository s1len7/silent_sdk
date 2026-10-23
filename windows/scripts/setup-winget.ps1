# Setup WinGet (App Installer) when it is missing, e.g. on LTSC / IoT without the Microsoft Store. Run as admin.
# Uses Microsoft's documented bootstrap: the Microsoft.WinGet.Client module and Repair-WinGetPackageManager.

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# winget.exe: the per-user app alias, or whatever is on PATH
function Get-WinGetPath {
    $alias = "$env:LOCALAPPDATA\Microsoft\WindowsApps\winget.exe"
    if (Test-Path $alias) { return $alias }
    (Get-Command winget -ErrorAction SilentlyContinue).Source
}

# Version string when winget runs, otherwise $null
function Get-WinGetVersion {
    $winget = Get-WinGetPath
    if (-not $winget) { return $null }
    try {
        $version = & $winget --version
        if ($LASTEXITCODE -eq 0) { return $version }
    } catch {
        # Alias exists but does not start
    }
    return $null
}

$version = Get-WinGetVersion
if ($version) {
    Write-Host "WinGet $version is already installed, skipped"
    $global:SetupStepSkipped = $true
    return
}

Write-Host 'WinGet not found, installing with Repair-WinGetPackageManager'
$ProgressPreference = 'SilentlyContinue'
Install-PackageProvider -Name NuGet -Force | Out-Null
Install-Module -Name Microsoft.WinGet.Client -Repository PSGallery -Scope AllUsers -Force | Out-Null
Import-Module Microsoft.WinGet.Client
Repair-WinGetPackageManager -AllUsers

$version = Get-WinGetVersion
if (-not $version) { throw 'WinGet is still not available after Repair-WinGetPackageManager' }
Write-Host "WinGet $version setup done: $(Get-WinGetPath)"
