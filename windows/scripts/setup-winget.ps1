# Setup WinGet (App Installer) when it is missing or does not start, e.g. on LTSC / IoT without the Microsoft Store. Run as admin.
# Provisions the GitHub release bundle machine-wide together with its license file. Installing the bundle
# without the license makes winget fail to start with "No applicable app licenses found".

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Installer logs go to the setup log folder (TEMP when run alone)
$logDir = if ($env:SILENT_SDK_LOG_DIR) { $env:SILENT_SDK_LOG_DIR } else { $env:TEMP }

$family = 'Microsoft.DesktopAppInstaller_8wekyb3d8bbwe'

# winget.exe: the per-user app alias, or whatever is on PATH
function Get-WinGetPath {
    $alias = "$env:LOCALAPPDATA\Microsoft\WindowsApps\winget.exe"
    if (Test-Path $alias) { return $alias }
    (Get-Command winget -ErrorAction SilentlyContinue).Source
}

# Version string when winget actually starts, otherwise $null (also covers the license error)
function Get-WinGetVersion {
    $winget = Get-WinGetPath
    if (-not $winget) { return $null }
    try {
        $version = & $winget --version
        if ($LASTEXITCODE -eq 0) { return $version }
    } catch {
        Write-Host "winget does not start: $($_.Exception.Message)"
    }
    return $null
}

$version = Get-WinGetVersion
if ($version) {
    Write-Host "WinGet $version is already installed, skipped"
    $global:SetupStepSkipped = $true
    return
}

# Bundle, dependencies and the license file (its name contains a hash) from the latest release
$release = Invoke-RestMethod https://api.github.com/repos/microsoft/winget-cli/releases/latest -UseBasicParsing
$asset = @{}
foreach ($pattern in '*.msixbundle', 'DesktopAppInstaller_Dependencies.zip', '*_License1.xml') {
    $asset[$pattern] = $release.assets | Where-Object name -like $pattern | Select-Object -First 1
    if (-not $asset[$pattern]) { throw "Asset $pattern not found in winget-cli $($release.tag_name)" }
}

$tmp = "$env:TEMP\winget-setup"
New-Item -ItemType Directory -Force $tmp | Out-Null
foreach ($a in $asset.Values) {
    Write-Host "Downloading $($a.name)"
    Invoke-WebRequest $a.browser_download_url -OutFile "$tmp\$($a.name)" -UseBasicParsing
}
$bundle  = "$tmp\$($asset['*.msixbundle'].name)"
$license = "$tmp\$($asset['*_License1.xml'].name)"
Expand-Archive "$tmp\$($asset['DesktopAppInstaller_Dependencies.zip'].name)" "$tmp\deps" -Force
$deps = Get-ChildItem "$tmp\deps\x64" -Filter *.appx

# Machine-wide with the license, then register for the current user now (otherwise only at the next sign-in)
Add-AppxProvisionedPackage -Online -PackagePath $bundle -DependencyPackagePath $deps.FullName -LicensePath $license `
    -LogPath "$logDir\winget-provision.log" | Out-Null
Add-AppxPackage -RegisterByFamilyName -MainPackage $family

$version = Get-WinGetVersion
if (-not $version) { throw "WinGet still does not start after provisioning $($release.tag_name)" }
Write-Host "WinGet $version setup done: $(Get-WinGetPath)"
