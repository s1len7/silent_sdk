# Setup Microsoft PC Manager (Store app 9PM860492SZD) via winget. Run as admin.
# LTSC has no winget, so install it from GitHub releases first.

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

& $winget install --id 9PM860492SZD -s msstore --accept-package-agreements --accept-source-agreements
if ($LASTEXITCODE -ne 0) { throw "PC Manager setup failed: exit code $LASTEXITCODE" }
Write-Host 'PC Manager setup done'
