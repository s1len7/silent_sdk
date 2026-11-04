# Setup the Bitwarden CLI (official @bitwarden/cli, npm) and connect it to the Vaultwarden
# server in devices/desktop/.env (VAULTWARDEN_URL). Run as admin, after the OpenCode step
# installs Node.js. Same process as devices/imac-27-2019/scripts/setup_bitwarden_cli.sh:
# install the CLI, read VAULTWARDEN_URL, require HTTPS, and set it with `bw config server`.
# The master password and session key are never read or stored here.
# Docs: https://bitwarden.com/help/cli/

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$logDir = if ($env:SILENT_SDK_LOG_DIR) { $env:SILENT_SDK_LOG_DIR } else { $env:TEMP }
New-Item -ItemType Directory -Force $logDir | Out-Null
$deviceDir = Split-Path $PSScriptRoot
$envFile = Join-Path $deviceDir '.env'
$envExample = Join-Path $deviceDir '.env.example'
$placeholder = 'https://<vaultwarden-example>.duckdns.org'

# Node.js and the npm global bin in this session too (a fresh install only updates PATH for new processes)
foreach ($dir in "$env:ProgramFiles\nodejs", "$env:APPDATA\npm") {
    if (($env:Path -split ';') -notcontains $dir) { $env:Path = "$dir;$env:Path" }
}

# Prefer the .cmd shim: PowerShell would pick bw.ps1 first, which the default execution
# policy can block in a new terminal
function Get-BwPath {
    foreach ($name in 'bw.cmd', 'bw.exe', 'bw') {
        $command = Get-Command $name -ErrorAction SilentlyContinue
        if ($command) { return $command.Source }
    }
    return $null
}

# Run bw and return stdout/exit code. Native stderr (e.g. the unreachable-server warning
# from `bw config server`) is ignored: Windows PowerShell 5.1 turns it into an error when
# $ErrorActionPreference is Stop, and bw still saves the server setting and exits 0.
function Invoke-Bw {
    param([Parameter(Mandatory)][string[]]$Arguments)
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = & $bwPath @Arguments 2>$null
        return [pscustomobject]@{
            ExitCode = $LASTEXITCODE
            Output   = (@($output) -join "`n").Trim()
        }
    } finally {
        $ErrorActionPreference = $previous
    }
}

# The last non-empty line: bw can print a first-run data file notice before the value
function Get-LastLine([string]$Text) {
    $lines = @($Text -split "`n" | Where-Object { $_.Trim() })
    if ($lines.Count) { return $lines[-1].Trim() }
    return ''
}

# 1. Install the CLI when missing
$bwPath = Get-BwPath
if (-not $bwPath) {
    $npm = (Get-Command npm.cmd -ErrorAction SilentlyContinue).Source
    if (-not $npm) { throw 'npm not found. Run scripts/setup-opencode.ps1 first to install Node.js' }
    $nodeVersion = (& node --version).TrimStart('v')
    $nodeMajor = [int]($nodeVersion -split '\.')[0]
    if ($nodeMajor -lt 22) {
        throw "Bitwarden CLI requires Node.js 22 or newer, found $nodeVersion. Run scripts/setup-opencode.ps1 to update Node.js"
    }
    Write-Host 'Installing the Bitwarden CLI (npm @bitwarden/cli)'
    $installLog = Join-Path $logDir 'bitwarden-cli-install.log'
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        & $npm install -g @bitwarden/cli --loglevel error 2>&1 | Tee-Object -FilePath $installLog
    } finally {
        $ErrorActionPreference = $previous
    }
    if ($LASTEXITCODE -ne 0) { throw "npm install @bitwarden/cli failed: exit code $LASTEXITCODE (log: $installLog)" }
    $bwPath = Get-BwPath
    if (-not $bwPath) { throw "bw not found after install (npm global bin: $env:APPDATA\npm)" }
}
$versionResult = Invoke-Bw -Arguments '--version'
if ($versionResult.ExitCode -ne 0) { throw "bw --version failed: exit code $($versionResult.ExitCode)" }
$version = Get-LastLine $versionResult.Output
if (-not $version) { throw 'bw --version returned no version. Reinstall @bitwarden/cli' }

# 2. Read VAULTWARDEN_URL from .env (create it from the example on first run)
if (-not (Test-Path $envFile)) {
    Copy-Item $envExample $envFile
    Write-Host "Created $envFile. Replace the example VAULTWARDEN_URL, then run this step again."
    $global:SetupStepSkipped = $true
    return
}
$values = @{}
foreach ($line in Get-Content $envFile) {
    if ($line -match '^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*?)\s*$') {
        $values[$Matches[1]] = $Matches[2].Trim('"', "'")
    }
}
$serverUrl = $values['VAULTWARDEN_URL']
if (-not $serverUrl) {
    Write-Host "VAULTWARDEN_URL is empty in $envFile. Add the Vaultwarden URL and run this step again."
    $global:SetupStepSkipped = $true
    return
}
if ($serverUrl -eq $placeholder) {
    Write-Host "Replace the example VAULTWARDEN_URL in $envFile, then run this step again."
    $global:SetupStepSkipped = $true
    return
}
if ($serverUrl -notmatch '^https://') { throw 'VAULTWARDEN_URL must use HTTPS' }
$serverUrl = $serverUrl.TrimEnd('/')

# 3. Connect the CLI to Vaultwarden (skip when it is already connected)
$current = Invoke-Bw -Arguments 'config', 'server'
if ($current.ExitCode -ne 0) { throw "bw config server failed: exit code $($current.ExitCode)" }
if ((Get-LastLine $current.Output) -eq $serverUrl) {
    Write-Host "Bitwarden CLI $version is connected to Vaultwarden, skipped"
    $global:SetupStepSkipped = $true
    return
}
Write-Host 'Configuring the Bitwarden CLI server'
$set = Invoke-Bw -Arguments 'config', 'server', $serverUrl
if ($set.ExitCode -ne 0) { throw "bw config server failed: exit code $($set.ExitCode)" }
$current = Invoke-Bw -Arguments 'config', 'server'
if ($current.ExitCode -ne 0) { throw "bw config server failed: exit code $($current.ExitCode)" }
if ((Get-LastLine $current.Output) -ne $serverUrl) {
    throw 'Bitwarden CLI server configuration did not match VAULTWARDEN_URL'
}
Write-Host "Bitwarden CLI $version is connected to Vaultwarden"
