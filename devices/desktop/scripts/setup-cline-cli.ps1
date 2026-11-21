# Setup the Cline CLI (official cline, npm). Run as admin, after the OpenCode
# step installs Node.js. No account or API key is configured here; connect a provider on first run.
# Docs: https://cline.bot

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$logDir = if ($env:SILENT_SDK_LOG_DIR) { $env:SILENT_SDK_LOG_DIR } else { $env:TEMP }
New-Item -ItemType Directory -Force $logDir | Out-Null

# Node.js and the npm global bin in this session too (a fresh install only updates PATH for new processes)
foreach ($dir in "$env:ProgramFiles\nodejs", "$env:APPDATA\npm") {
    if (($env:Path -split ';') -notcontains $dir) { $env:Path = "$dir;$env:Path" }
}

# Prefer the .cmd shim: PowerShell may pick cline.ps1 first, which the default execution
# policy can block in a new terminal
function Get-ClinePath {
    foreach ($name in 'cline.cmd', 'cline.exe', 'cline') {
        $command = Get-Command $name -ErrorAction SilentlyContinue
        if ($command) { return $command.Source }
    }
    return $null
}

# The agent-rules step only handles agents whose config folder exists
New-Item -ItemType Directory -Force (Join-Path $HOME '.cline') | Out-Null

$clinePath = Get-ClinePath
if ($clinePath) {
    Write-Host "Cline CLI is already installed, skipped: $clinePath"
    $global:SetupStepSkipped = $true
    return
}

$npm = (Get-Command npm.cmd -ErrorAction SilentlyContinue).Source
if (-not $npm) {
    throw 'npm not found. Run setup-opencode.ps1 first to install Node.js'
}

Write-Host 'Installing the Cline CLI (npm cline)'
$installLog = Join-Path $logDir 'cline-cli-install.log'
$previous = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
try {
    & $npm install -g --allow-scripts=cline cline@latest --loglevel error --logs-dir $logDir 2>&1 | Tee-Object -FilePath $installLog
} finally {
    $ErrorActionPreference = $previous
}
if ($LASTEXITCODE -ne 0) { throw "npm install cline failed: exit code $LASTEXITCODE (log: $installLog)" }

$clinePath = Get-ClinePath
if (-not $clinePath) { throw "cline not found after install (npm global bin: $env:APPDATA\npm)" }
$version = ((& $clinePath --version) -join '').Trim()
if ($LASTEXITCODE -ne 0) { throw "cline --version failed: exit code $LASTEXITCODE" }
if (-not $version) { throw 'cline --version returned no version. Reinstall cline' }

Write-Host "Cline CLI $version setup done: $clinePath"
Write-Host "Update: npm i -g --allow-scripts=cline cline@latest"
Write-Host "Run 'cline' in a new terminal"
