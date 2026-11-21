# Setup the Codex CLI (official @openai/codex, npm). Run as admin, after the OpenCode
# step installs Node.js. No account or API key is configured here; sign in on first run.
# Same process as devices/imac-27-2019/scripts/setup_codex_cli.sh: install the CLI and
# link `codex` into the npm global bin (~$env:APPDATA\npm).
# Docs: https://github.com/openai/codex

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$logDir = if ($env:SILENT_SDK_LOG_DIR) { $env:SILENT_SDK_LOG_DIR } else { $env:TEMP }
New-Item -ItemType Directory -Force $logDir | Out-Null

# Node.js and the npm global bin in this session too (a fresh install only updates PATH for new processes)
foreach ($dir in "$env:ProgramFiles\nodejs", "$env:APPDATA\npm") {
    if (($env:Path -split ';') -notcontains $dir) { $env:Path = "$dir;$env:Path" }
}

# Prefer the .cmd shim: PowerShell would pick codex.ps1 first, which the default execution
# policy can block in a new terminal
function Get-CodexPath {
    foreach ($name in 'codex.cmd', 'codex.exe', 'codex') {
        $command = Get-Command $name -ErrorAction SilentlyContinue
        if ($command) { return $command.Source }
    }
    return $null
}

$codexPath = Get-CodexPath
if ($codexPath) {
    Write-Host "Codex CLI is already installed, skipped: $codexPath"
    $global:SetupStepSkipped = $true
    return
}

$npm = (Get-Command npm.cmd -ErrorAction SilentlyContinue).Source
if (-not $npm) {
    throw 'npm not found. Run scripts/setup-opencode.ps1 first to install Node.js'
}

Write-Host 'Installing the Codex CLI (npm @openai/codex)'
$installLog = Join-Path $logDir 'codex-cli-install.log'
$previous = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
try {
    & $npm install -g @openai/codex@latest --loglevel error 2>&1 | Tee-Object -FilePath $installLog
} finally {
    $ErrorActionPreference = $previous
}
if ($LASTEXITCODE -ne 0) { throw "npm install @openai/codex failed: exit code $LASTEXITCODE (log: $installLog)" }

$codexPath = Get-CodexPath
if (-not $codexPath) { throw "codex not found after install (npm global bin: $env:APPDATA\npm)" }
$version = ((& $codexPath --version) -join '').Trim()
if ($LASTEXITCODE -ne 0) { throw "codex --version failed: exit code $LASTEXITCODE" }
if (-not $version) { throw 'codex --version returned no version. Reinstall @openai/codex' }

Write-Host "Codex CLI $version setup done: $codexPath"
Write-Host "Update: npm i -g @openai/codex@latest"
Write-Host "Run 'codex' in a new terminal (sign in with your OpenAI account on first run)"
