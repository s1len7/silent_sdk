# Setup the OpenCode CLI with a free default model and a runtime fallback chain. Run as admin.
# Node.js (winget) -> OpenCode CLI (npm, latest) -> ~/.config/opencode/opencode.json (model, fallback plugin)
# -> ~/.config/opencode/opencode-fallback.json (fallback models) -> Gemini API key from devices/desktop/.env
# (GEMINI_API_KEY; skipped when empty). The free opencode/* models need no login.
# Needs winget: setup-winget.ps1 runs before this step and installs it when missing.
# -UserScope skips winget and installs Node.js from the official win-x64 zip into
# %LOCALAPPDATA%\Programs\nodejs, then adds that folder and the npm global bin to the user PATH
# (no admin). The config and auth files are already per-user either way.
# Docs: https://opencode.ai/docs/
param([switch]$UserScope)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$logDir = if ($env:SILENT_SDK_LOG_DIR) { $env:SILENT_SDK_LOG_DIR } else { $env:TEMP }
$envFile = Join-Path (Split-Path $PSScriptRoot) '.env'
$configDir = "$env:USERPROFILE\.config\opencode"
$configFile = "$configDir\opencode.json"
$fallbackFile = "$configDir\opencode-fallback.json"
# Credentials saved by "opencode auth login"
$authFile = "$env:USERPROFILE\.local\share\opencode\auth.json"
$model = 'opencode/deepseek-v4.1-flash-free'
$plugin = 'opencode-runtime-fallback@0.3.0'
$fallbackModels = @('opencode/glm-5.3-flash-free', 'opencode/beam-free')

# Read KEY=VALUE lines from .env (comments and blank lines ignored, optional quotes removed)
$values = @{}
if (Test-Path $envFile) {
    foreach ($line in Get-Content $envFile -Encoding UTF8) {
        if ($line -match '^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*?)\s*$') {
            $values[$Matches[1]] = $Matches[2].Trim('"', "'")
        }
    }
}
$apiKey = $values['GEMINI_API_KEY']

# Node.js and npm global bin in this session too (a fresh install only updates PATH for new processes)
$nodeDir = if ($UserScope) { "$env:LOCALAPPDATA\Programs\nodejs" } else { "$env:ProgramFiles\nodejs" }
foreach ($dir in $nodeDir, "$env:APPDATA\npm") {
    if (($env:Path -split ';') -notcontains $dir) { $env:Path = "$dir;$env:Path" }
}

# Parsed JSON file, or $null when missing; throws on invalid JSON so a user config is never overwritten
function Read-JsonFile($path) {
    if (-not (Test-Path $path)) { return $null }
    $text = [IO.File]::ReadAllText($path)
    if (-not $text.Trim()) { return $null }
    try { $text | ConvertFrom-Json } catch { throw "Invalid JSON in $path, fix or remove it: $($_.Exception.Message)" }
}

# UTF-8 without BOM (PowerShell 5.1 Set-Content/Out-File would add a BOM or use ANSI)
function Write-JsonFile($path, $object) {
    New-Item -ItemType Directory -Force (Split-Path $path) | Out-Null
    [IO.File]::WriteAllText($path, ($object | ConvertTo-Json -Depth 20), (New-Object Text.UTF8Encoding($false)))
}

# OpenCode v1 loads plugins from "plugin"; any version of the fallback plugin counts
function Test-PluginEntry($config) {
    foreach ($entry in @($config.plugin)) { if ("$entry" -match '^opencode-runtime-fallback(@|$)') { return $true } }
    $false
}

function Test-Cli { [bool](Get-Command opencode -ErrorAction SilentlyContinue) }
function Test-Config {
    $config = Read-JsonFile $configFile
    $config -and $config.model -eq $model -and (Test-PluginEntry $config)
}
function Test-Fallback {
    $fallback = Read-JsonFile $fallbackFile
    $fallback -and (@($fallback.fallback_models) -join ',') -eq ($fallbackModels -join ',')
}
function Test-Key {
    if (-not $apiKey) { return $true }
    $auth = Read-JsonFile $authFile
    $auth -and $auth.google.key -ceq $apiKey
}

if ((Test-Cli) -and (Test-Config) -and (Test-Fallback) -and (Test-Key)) {
    # OpenCode is updated with: npm i -g --allow-scripts=opencode-ai opencode-ai@latest
    Write-Host 'OpenCode is already set up, skipped'
    $global:SetupStepSkipped = $true
    return
}

if (-not (Test-Cli)) {
    if ($UserScope) {
        # 1. Node.js: user-level zip install (the MSI installers need admin)
        if (-not (Test-Path "$nodeDir\node.exe")) {
            Write-Host "[1/5] Node.js: user-level zip install ($nodeDir)"
            $index = Invoke-RestMethod 'https://nodejs.org/dist/index.json' -UseBasicParsing
            $release = $index | Where-Object { $_.lts -and $_.files -contains 'win-x64-zip' } | Select-Object -First 1
            if (-not $release) { throw 'no Node.js LTS release with win-x64-zip found' }
            $url = "https://nodejs.org/dist/$($release.version)/node-$($release.version)-win-x64.zip"
            $zip = "$env:TEMP\node-$($release.version)-win-x64.zip"
            $extract = "$env:TEMP\node-extract"
            Invoke-WebRequest $url -OutFile $zip -UseBasicParsing
            Remove-Item $extract -Recurse -Force -ErrorAction SilentlyContinue
            Expand-Archive $zip $extract -Force
            $inner = "$extract\node-$($release.version)-win-x64"
            if (-not (Test-Path "$inner\node.exe")) { throw "node.exe not found in $zip" }
            Remove-Item $nodeDir -Recurse -Force -ErrorAction SilentlyContinue
            New-Item -ItemType Directory -Force (Split-Path $nodeDir) | Out-Null
            Move-Item $inner $nodeDir
            Remove-Item $extract, $zip -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "Node.js $(& "$nodeDir\node.exe" --version) installed"
        }
        # opencode.cmd lands in the npm global bin, which is not on PATH by default
        foreach ($dir in $nodeDir, "$env:APPDATA\npm") {
            $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
            $entries = @($userPath -split ';' | Where-Object { $_ })
            if ($entries -notcontains $dir) {
                [Environment]::SetEnvironmentVariable('Path', (($entries + $dir) -join ';'), 'User')
                Write-Host "Added to user PATH: $dir"
            }
        }
    } else {
        # 1. Node.js: install, or upgrade to the newest release
        $winget = "$env:LOCALAPPDATA\Microsoft\WindowsApps\winget.exe"
        if (-not (Test-Path $winget)) { $winget = (Get-Command winget -ErrorAction SilentlyContinue).Source }
        if (-not $winget) { throw 'winget not found. Run setup-winget.ps1 first' }
        & $winget list --id OpenJS.NodeJS --exact --accept-source-agreements | Out-Null
        $verb = if ($LASTEXITCODE -eq 0) { 'upgrade' } else { 'install' }
        Write-Host "[1/5] Node.js: winget $verb"
        & $winget $verb --id OpenJS.NodeJS --exact -s winget --silent --accept-package-agreements --accept-source-agreements
        # -1978335189 (0x8A15002B): no newer version, -1978335135 (0x8A150061): already installed
        if ($LASTEXITCODE -notin 0, -1978335189, -1978335135) { throw "Node.js $verb failed: exit code $LASTEXITCODE" }
        & node --version
    }

    # 2. OpenCode CLI (latest); its install script fetches the platform binary, so it must be allowed
    Write-Host '[2/5] Installing the OpenCode CLI (npm, latest)'
    & npm install -g --allow-scripts=opencode-ai opencode-ai@latest --loglevel error --logs-dir $logDir
    if ($LASTEXITCODE -ne 0) { throw "npm install opencode-ai failed: exit code $LASTEXITCODE" }
    if (-not (Test-Cli)) { throw "opencode not found after install (npm global bin: $env:APPDATA\npm)" }
    & opencode --version
}

# 3. Default model and fallback plugin; other keys in an existing config are kept
if (-not (Test-Config)) {
    Write-Host "[3/5] Setting the default model to $model with the $plugin plugin ($configFile)"
    $config = Read-JsonFile $configFile
    if (-not $config) { $config = [pscustomobject]@{ '$schema' = 'https://opencode.ai/config.json' } }
    $config | Add-Member -NotePropertyName model -NotePropertyValue $model -Force
    if (-not (Test-PluginEntry $config)) {
        $plugins = @(@($config.plugin) | Where-Object { $_ }) + $plugin
        $config | Add-Member -NotePropertyName plugin -NotePropertyValue $plugins -Force
    }
    Write-JsonFile $configFile $config
}

# 4. Global fallback chain read by the plugin; other keys in an existing file are kept
if (-not (Test-Fallback)) {
    Write-Host "[4/5] Setting the fallback models to $($fallbackModels -join ', ') ($fallbackFile)"
    $fallback = Read-JsonFile $fallbackFile
    if (-not $fallback) { $fallback = [pscustomobject]@{} }
    $fallback | Add-Member -NotePropertyName fallback_models -NotePropertyValue $fallbackModels -Force
    Write-JsonFile $fallbackFile $fallback
}

# 5. Gemini API key, saved the way "opencode auth login" does; written directly because piping it
#    from PowerShell 5.1 prepends a BOM to the key. Other saved credentials are kept.
if (-not $apiKey) {
    Write-Host "[5/5] GEMINI_API_KEY is empty in $envFile. Add the key and run this step again to use Gemini."
} elseif (-not (Test-Key)) {
    Write-Host "[5/5] Saving the Gemini API key ($authFile)"
    $auth = Read-JsonFile $authFile
    if (-not $auth) { $auth = [pscustomobject]@{} }
    $auth | Add-Member -NotePropertyName google -NotePropertyValue ([pscustomobject]@{ type = 'api'; key = $apiKey }) -Force
    Write-JsonFile $authFile $auth
}

Write-Host "OpenCode setup done: run 'opencode' in a new terminal (default model $model)"
