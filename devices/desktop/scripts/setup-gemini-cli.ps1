# Setup the Gemini CLI (official @google/gemini-cli, npm). Run as admin, after the OpenCode
# step installs Node.js. No account or API key is configured here; sign in on first run.
# Docs: https://github.com/google-gemini/gemini-cli

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$logDir = if ($env:SILENT_SDK_LOG_DIR) { $env:SILENT_SDK_LOG_DIR } else { $env:TEMP }
New-Item -ItemType Directory -Force $logDir | Out-Null

# Node.js and the npm global bin in this session too (a fresh install only updates PATH for new processes)
foreach ($dir in "$env:ProgramFiles\nodejs", "$env:APPDATA\npm") {
    if (($env:Path -split ';') -notcontains $dir) { $env:Path = "$dir;$env:Path" }
}

# Prefer the .cmd shim: PowerShell may pick gemini.ps1 first, which the default execution
# policy can block in a new terminal
function Get-GeminiPath {
    foreach ($name in 'gemini.cmd', 'gemini.exe', 'gemini') {
        $command = Get-Command $name -ErrorAction SilentlyContinue
        if ($command) { return $command.Source }
    }
    return $null
}

# The agent-rules step only handles agents whose config folder exists
New-Item -ItemType Directory -Force (Join-Path $HOME '.gemini') | Out-Null

$geminiPath = Get-GeminiPath
if ($geminiPath) {
    Write-Host "Gemini CLI is already installed, skipped: $geminiPath"
    $global:SetupStepSkipped = $true
    return
}

$npm = (Get-Command npm.cmd -ErrorAction SilentlyContinue).Source
if (-not $npm) {
    throw 'npm not found. Run setup-opencode.ps1 first to install Node.js'
}

Write-Host 'Installing the Gemini CLI (npm @google/gemini-cli)'
$installLog = Join-Path $logDir 'gemini-cli-install.log'
$previous = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
try {
    & $npm install -g --allow-scripts=@google/gemini-cli @google/gemini-cli@latest --loglevel error --logs-dir $logDir 2>&1 | Tee-Object -FilePath $installLog
} finally {
    $ErrorActionPreference = $previous
}
if ($LASTEXITCODE -ne 0) { throw "npm install @google/gemini-cli failed: exit code $LASTEXITCODE (log: $installLog)" }

$geminiPath = Get-GeminiPath
if (-not $geminiPath) { throw "gemini not found after install (npm global bin: $env:APPDATA\npm)" }
$version = ((& $geminiPath --version) -join '').Trim()
if ($LASTEXITCODE -ne 0) { throw "gemini --version failed: exit code $LASTEXITCODE" }
if (-not $version) { throw 'gemini --version returned no version. Reinstall @google/gemini-cli' }

Write-Host "Gemini CLI $version setup done: $geminiPath"
Write-Host "Update: npm i -g --allow-scripts=@google/gemini-cli @google/gemini-cli@latest"
Write-Host "Run 'gemini' in a new terminal"
