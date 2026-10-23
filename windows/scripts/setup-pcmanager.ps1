# Setup Microsoft PC Manager (Store app 9PM860492SZD) via winget. Run as admin.
# If winget is missing (e.g. LTSC), install it from GitHub releases first.

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$winget = "$env:LOCALAPPDATA\Microsoft\WindowsApps\winget.exe"
if (-not (Test-Path $winget)) {
    Write-Host 'winget not found, installing from GitHub'
    $base = 'https://github.com/microsoft/winget-cli/releases/latest/download'
    $tmp  = "$env:TEMP\winget-setup"
    New-Item -ItemType Directory -Force $tmp | Out-Null
    Invoke-WebRequest "$base/DesktopAppInstaller_Dependencies.zip" -OutFile "$tmp\deps.zip" -UseBasicParsing
    Invoke-WebRequest "$base/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle" -OutFile "$tmp\winget.msixbundle" -UseBasicParsing
    Expand-Archive "$tmp\deps.zip" "$tmp\deps" -Force
    $deps = Get-ChildItem "$tmp\deps" -Recurse -Include *.appx, *.msix | Where-Object FullName -match '\\x64\\'
    Add-AppxPackage -Path "$tmp\winget.msixbundle" -DependencyPath $deps.FullName
}

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
