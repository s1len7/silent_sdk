# Setup Sysinternals Suite to Program Files and add it to the machine PATH. Run as admin.

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$dest = "$env:ProgramFiles\Sysinternals"

# Already installed, in the machine PATH and with the EULA accepted
$done = (Test-Path "$dest\procexp.exe") -and
    ([Environment]::GetEnvironmentVariable('Path', 'Machine') -split ';') -contains $dest -and
    (Get-ItemProperty HKCU:\Software\Sysinternals -ErrorAction SilentlyContinue).EulaAccepted -eq 1
if ($done) {
    Write-Host "Sysinternals Suite is already installed, skipped: $dest"
    $global:SetupStepSkipped = $true
    return
}

$zip  = "$env:TEMP\SysinternalsSuite.zip"
Invoke-WebRequest https://download.sysinternals.com/files/SysinternalsSuite.zip -OutFile $zip -UseBasicParsing
Expand-Archive $zip $dest -Force

$path = [Environment]::GetEnvironmentVariable('Path', 'Machine')
if (($path -split ';') -notcontains $dest) {
    [Environment]::SetEnvironmentVariable('Path', "$path;$dest", 'Machine')
}
$env:Path += ";$dest"

# Skip the EULA dialog on first run of each tool (current user)
New-Item HKCU:\Software\Sysinternals -Force | Out-Null
Set-ItemProperty HKCU:\Software\Sysinternals EulaAccepted 1 -Type DWord
Write-Host "Sysinternals Suite setup done: $dest"
