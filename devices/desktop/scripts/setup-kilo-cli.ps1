# Setup the Kilo Code CLI (official @kilocode/cli, npm). Run as admin, after the OpenCode
# step installs Node.js. No account or API key is configured here; run /connect on first use.
# Docs: https://kilo.ai/docs/code-with-ai/platforms/cli

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$logDir = if ($env:SILENT_SDK_LOG_DIR) { $env:SILENT_SDK_LOG_DIR } else { $env:TEMP }
New-Item -ItemType Directory -Force $logDir | Out-Null

# Node.js and the npm global bin in this session too (a fresh install only updates PATH for new processes)
foreach ($dir in "$env:ProgramFiles\nodejs", "$env:APPDATA\npm") {
    if (($env:Path -split ';') -notcontains $dir) { $env:Path = "$dir;$env:Path" }
}

# Prefer the .cmd shim: PowerShell may pick kilo.ps1 first, which the default execution
# policy can block in a new terminal
function Get-KiloPath {
    foreach ($name in 'kilo.cmd', 'kilo.exe', 'kilo') {
        $command = Get-Command $name -ErrorAction SilentlyContinue
        if ($command) { return $command.Source }
    }
    return $null
}

# The agent-rules step only handles agents whose config folder exists
New-Item -ItemType Directory -Force (Join-Path $HOME '.config\kilo') | Out-Null

$kiloPath = Get-KiloPath
if ($kiloPath) {
    Write-Host "Kilo Code CLI is already installed, skipped: $kiloPath"
    $global:SetupStepSkipped = $true
    return
}

$npm = (Get-Command npm.cmd -ErrorAction SilentlyContinue).Source
if (-not $npm) {
    throw 'npm not found. Run setup-opencode.ps1 first to install Node.js'
}

Write-Host 'Installing the Kilo Code CLI (npm @kilocode/cli)'
$installLog = Join-Path $logDir 'kilo-cli-install.log'
$previous = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
try {
    & $npm install -g --allow-scripts=@kilocode/cli @kilocode/cli@latest --loglevel error --logs-dir $logDir 2>&1 | Tee-Object -FilePath $installLog
} finally {
    $ErrorActionPreference = $previous
}
if ($LASTEXITCODE -ne 0) { throw "npm install @kilocode/cli failed: exit code $LASTEXITCODE (log: $installLog)" }

$kiloPath = Get-KiloPath
if (-not $kiloPath) { throw "kilo not found after install (npm global bin: $env:APPDATA\npm)" }
$version = ((& $kiloPath --version) -join '').Trim()
if ($LASTEXITCODE -ne 0) { throw "kilo --version failed: exit code $LASTEXITCODE" }
if (-not $version) { throw 'kilo --version returned no version. Reinstall @kilocode/cli' }

Write-Host "Kilo Code CLI $version setup done: $kiloPath"
Write-Host "Update: npm i -g --allow-scripts=@kilocode/cli @kilocode/cli@latest"
Write-Host "Run 'kilo' in a new terminal. Use /connect on first run"
