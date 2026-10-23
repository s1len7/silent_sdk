# Setup the latest Git for Windows (64-bit) from GitHub releases, then set the global commit identity. Run as admin.

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Installer logs go to the setup log folder (TEMP when run alone)
$logDir = if ($env:SILENT_SDK_LOG_DIR) { $env:SILENT_SDK_LOG_DIR } else { $env:TEMP }

# Commit identity: GitHub noreply address so the real email never lands in commits
$gitName  = 'silent'
$gitEmail = '20176737+s1len7@users.noreply.github.com'
$git = "$env:ProgramFiles\Git\cmd\git.exe"

# Already installed and the identity is set: Git updates are left to the user
if ((Test-Path $git) -and (& $git config --global user.name) -eq $gitName -and (& $git config --global user.email) -eq $gitEmail) {
    Write-Host "Git is already installed with identity $gitName <$gitEmail>, skipped"
    $global:SetupStepSkipped = $true
    return
}

if (Test-Path $git) {
    Write-Host 'Git is already installed, only setting the identity'
} else {
    $release = Invoke-RestMethod https://api.github.com/repos/git-for-windows/git/releases/latest -UseBasicParsing
    $asset = $release.assets | Where-Object name -match '^Git-[\d.]+-64-bit\.exe$' | Select-Object -First 1
    $exe = "$env:TEMP\$($asset.name)"
    Invoke-WebRequest $asset.browser_download_url -OutFile $exe -UseBasicParsing

    $p = Start-Process $exe -ArgumentList "/VERYSILENT /NORESTART /NOCANCEL /SP- /SUPPRESSMSGBOXES /LOG=`"$logDir\git-install.log`"" -Wait -PassThru
    if ($p.ExitCode -ne 0) { throw "Git installer failed: exit code $($p.ExitCode)" }
    Write-Host "Git $($release.tag_name) setup done: $(& $git --version)"
}

# Global config goes to the elevated user's home (same account under normal UAC)
& $git config --global user.name $gitName
if ($LASTEXITCODE -ne 0) { throw "git config user.name failed: exit code $LASTEXITCODE" }
& $git config --global user.email $gitEmail
if ($LASTEXITCODE -ne 0) { throw "git config user.email failed: exit code $LASTEXITCODE" }
Write-Host "Git identity set: $gitName <$gitEmail>"
