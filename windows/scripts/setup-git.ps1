# Setup the latest Git for Windows (64-bit) from GitHub releases, then set the global commit identity. Run as admin.

$ErrorActionPreference = 'Stop'

# Commit identity: GitHub noreply address so the real email never lands in commits
$gitName  = 'silent'
$gitEmail = '20176737+s1len7@users.noreply.github.com'
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

# Global config goes to the elevated user's home (same account under normal UAC)
git config --global user.name $gitName
if ($LASTEXITCODE -ne 0) { throw "git config user.name failed: exit code $LASTEXITCODE" }
git config --global user.email $gitEmail
if ($LASTEXITCODE -ne 0) { throw "git config user.email failed: exit code $LASTEXITCODE" }
Write-Host "Git identity set: $gitName <$gitEmail>"
