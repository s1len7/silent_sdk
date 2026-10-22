# Setup the latest PowerToys (machine-wide x64) from GitHub releases. Run as admin.

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$release = Invoke-RestMethod https://api.github.com/repos/microsoft/PowerToys/releases/latest -UseBasicParsing
$asset = $release.assets | Where-Object name -match '^PowerToysSetup-[\d.]+-x64\.exe$' | Select-Object -First 1
$exe = "$env:TEMP\$($asset.name)"
Invoke-WebRequest $asset.browser_download_url -OutFile $exe -UseBasicParsing

$p = Start-Process $exe -ArgumentList '/quiet /norestart' -Wait -PassThru
if ($p.ExitCode -notin 0, 3010) { throw "PowerToys installer failed: exit code $($p.ExitCode)" }
Write-Host "PowerToys $($release.tag_name) setup done"
