# Setup the latest Git for Windows (64-bit) from GitHub releases, then set the global commit identity.
# -UserScope installs for the current user only (%LOCALAPPDATA%\Programs\Git, no admin needed).
# Without -UserScope the machine-wide installer runs (needs admin; used by desktop/titan-s260/thinkpad-s2-2g);
# generic-windows passes -UserScope so a borrowed PC needs no admin.
param([switch]$UserScope)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Installer logs go to the setup log folder (TEMP when run alone)
$logDir = if ($env:SILENT_SDK_LOG_DIR) { $env:SILENT_SDK_LOG_DIR } else { $env:TEMP }

# Commit identity: GitHub noreply address so the real email never lands in commits
$gitName  = 'silent'
$gitEmail = '20176737+s1len7@users.noreply.github.com'
$userGit  = "$env:LOCALAPPDATA\Programs\Git\cmd\git.exe"
$machineGit = "$env:ProgramFiles\Git\cmd\git.exe"

# Existing Git wins (any install), so a machine-wide Git is not reinstalled for the user
$git = @($userGit, $machineGit) | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $git) {
    $command = Get-Command git -ErrorAction SilentlyContinue
    if ($command) { $git = $command.Source }
}

# Already installed and the identity is set: Git updates are left to the user
if ($git -and (& $git config --global user.name) -eq $gitName -and (& $git config --global user.email) -eq $gitEmail) {
    Write-Host "Git is already installed with identity $gitName <$gitEmail>, skipped"
    $global:SetupStepSkipped = $true
    return
}

if ($git) {
    Write-Host 'Git is already installed, only setting the identity'
} else {
    $release = Invoke-RestMethod https://api.github.com/repos/git-for-windows/git/releases/latest -UseBasicParsing
    $asset = $release.assets | Where-Object name -match '^Git-[\d.]+-64-bit\.exe$' | Select-Object -First 1
    $exe = "$env:TEMP\$($asset.name)"
    Invoke-WebRequest $asset.browser_download_url -OutFile $exe -UseBasicParsing

    $installArgs = "/VERYSILENT /NORESTART /NOCANCEL /SP- /SUPPRESSMSGBOXES /LOG=`"$logDir\git-install.log`""
    if ($UserScope) {
        # Per-user install; the installer also appends Git to the user PATH
        $installArgs += ' /CURRENTUSER'
        $git = $userGit
    } else {
        $git = $machineGit
    }
    $p = Start-Process $exe -ArgumentList $installArgs -Wait -PassThru
    if ($p.ExitCode -ne 0) { throw "Git installer failed: exit code $($p.ExitCode)" }
    if (-not (Test-Path $git)) { throw "git not found after install: $git" }
    # The installer updates PATH for new processes only
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
    Write-Host "Git $($release.tag_name) setup done: $(& $git --version)"
}

# Global config goes to the elevated user's home (same account under normal UAC)
& $git config --global user.name $gitName
if ($LASTEXITCODE -ne 0) { throw "git config user.name failed: exit code $LASTEXITCODE" }
& $git config --global user.email $gitEmail
if ($LASTEXITCODE -ne 0) { throw "git config user.email failed: exit code $LASTEXITCODE" }
Write-Host "Git identity set: $gitName <$gitEmail>"
