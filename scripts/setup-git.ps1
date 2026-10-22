# Setup the latest Git for Windows (64-bit) from GitHub releases. Run as admin.

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$release = Invoke-RestMethod https://api.github.com/repos/git-for-windows/git/releases/latest -UseBasicParsing
$asset = $release.assets | Where-Object name -match '^Git-[\d.]+-64-bit\.exe$' | Select-Object -First 1
$exe = "$env:TEMP\$($asset.name)"
Invoke-WebRequest $asset.browser_download_url -OutFile $exe -UseBasicParsing

$p = Start-Process $exe -ArgumentList '/VERYSILENT /NORESTART /NOCANCEL /SP- /SUPPRESSMSGBOXES' -Wait -PassThru
if ($p.ExitCode -ne 0) { throw "Git installer failed: exit code $($p.ExitCode)" }

# Refresh PATH so git works in this session
$env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
Write-Host "Git $($release.tag_name) setup done: $(git --version)"
