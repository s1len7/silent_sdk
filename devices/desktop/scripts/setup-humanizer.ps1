# Setup the Humanizer skill (blader/humanizer) for AI agents via npx skills.
# Installs the skill globally into ~/.agents/skills so Claude Code and OpenCode can use /humanizer.
# Run as admin, after the OpenCode step installs Node.js.
# Same process as devices/imac-27-2019/scripts/setup_humanizer.sh.
# Docs: https://github.com/blader/humanizer

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$logDir = if ($env:SILENT_SDK_LOG_DIR) { $env:SILENT_SDK_LOG_DIR } else { $env:TEMP }
New-Item -ItemType Directory -Force $logDir | Out-Null

$skillDir = Join-Path $HOME '.agents\skills\humanizer'
$skillFile = Join-Path $skillDir 'SKILL.md'

if (Test-Path $skillFile) {
    Write-Host "Humanizer skill is already installed, skipped: $skillFile"
    $global:SetupStepSkipped = $true
    return
}

$npx = (Get-Command npx.cmd -ErrorAction SilentlyContinue).Source
if (-not $npx) {
    throw 'npx not found. Run scripts/setup-opencode.ps1 first to install Node.js'
}

Write-Host 'Installing the Humanizer skill (npx skills add blader/humanizer -g)'
$installLog = Join-Path $logDir 'humanizer-install.log'
$previous = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
try {
    & $npx --yes skills add blader/humanizer -g -a '*' -y 2>&1 | Tee-Object -FilePath $installLog
} finally {
    $ErrorActionPreference = $previous
}
if ($LASTEXITCODE -ne 0) { throw "npx skills add blader/humanizer failed: exit code $LASTEXITCODE (log: $installLog)" }

if (-not (Test-Path $skillFile)) {
    throw "Humanizer skill is not installed after running npx skills (expected: $skillFile)"
}

Write-Host "Humanizer skill installed: $skillFile"
Write-Host "Use /humanizer in Claude Code or OpenCode. Restart the agent if it was already running"
