# Setup Docker Desktop (includes Docker Engine/CLI/Compose) with the WSL 2 backend. Run as admin.
# Reboot afterwards so the WSL features take effect.

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Already installed and the current user can use it: Docker Desktop keeps itself up to date
$installed = Test-Path "$env:ProgramFiles\Docker\Docker\Docker Desktop.exe"
$member = Get-LocalGroupMember docker-users -ErrorAction SilentlyContinue | Where-Object Name -like "*\$env:USERNAME"
if ($installed -and $member) {
    Write-Host 'Docker Desktop is already installed, skipped'
    $global:SetupStepSkipped = $true
    return
}
if ($installed) {
    Add-LocalGroupMember docker-users -Member $env:USERNAME
    Write-Host "Docker Desktop is already installed, added $env:USERNAME to docker-users"
    return
}

# WSL 2 prerequisites
foreach ($f in 'Microsoft-Windows-Subsystem-Linux', 'VirtualMachinePlatform') {
    dism.exe /online /enable-feature /featurename:$f /all /norestart | Out-Null
    if ($LASTEXITCODE -notin 0, 3010) { throw "Enabling $f failed: exit code $LASTEXITCODE" }
}
wsl.exe --update
if ($LASTEXITCODE -ne 0) { Write-Warning 'wsl --update failed, run it again after reboot' }

$exe = "$env:TEMP\DockerDesktopInstaller.exe"
Invoke-WebRequest 'https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe' -OutFile $exe -UseBasicParsing

$p = Start-Process $exe -ArgumentList 'install --quiet --accept-license --backend=wsl-2' -Wait -PassThru
if ($p.ExitCode -notin 0, 3010) { throw "Docker Desktop installer failed: exit code $($p.ExitCode)" }

# Let the current user use Docker without admin
Add-LocalGroupMember docker-users -Member $env:USERNAME -ErrorAction SilentlyContinue
Write-Host 'Docker Desktop setup done (reboot required)'
