# Setup ZoomIt (Sysinternals) to Program Files and add a Start Menu shortcut. Run as admin.

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$dest = "$env:ProgramFiles\ZoomIt"
$lnkPath = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\ZoomIt.lnk"

if ((Test-Path "$dest\ZoomIt64.exe") -and (Test-Path $lnkPath)) {
    Write-Host "ZoomIt is already installed, skipped: $dest"
    $global:SetupStepSkipped = $true
    return
}

$zip  = "$env:TEMP\ZoomIt.zip"
Invoke-WebRequest https://download.sysinternals.com/files/ZoomIt.zip -OutFile $zip -UseBasicParsing
Expand-Archive $zip $dest -Force

$lnk = (New-Object -ComObject WScript.Shell).CreateShortcut($lnkPath)
$lnk.TargetPath = "$dest\ZoomIt64.exe"
$lnk.Save()
Write-Host "ZoomIt setup done: $dest"
