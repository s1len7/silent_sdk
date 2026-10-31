# Setup a local OpenClaw Gateway (loopback only, token auth) with free models and automatic fallbacks. Run as admin.
# Node.js (winget) -> OpenClaw CLI (npm, latest) -> onboard (Gateway as the "OpenClaw Gateway" scheduled task)
# -> default model and fallbacks -> OpenRouter API key from devices/desktop/.env (OPENROUTER_API_KEY; skipped when empty)
# -> Gemini API key from the same .env (GEMINI_API_KEY; skipped when empty).
# Needs winget: setup-winget.ps1 runs before this step and installs it when missing.
# Docs: https://docs.openclaw.ai/install

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$logDir = if ($env:SILENT_SDK_LOG_DIR) { $env:SILENT_SDK_LOG_DIR } else { $env:TEMP }
$envFile = Join-Path (Split-Path $PSScriptRoot) '.env'
$taskName = 'OpenClaw Gateway'
# Packages whose npm install scripts OpenClaw needs (npm skips them unless allowed; listed by the npm warning)
$allowScripts = '@google/genai,esbuild,koffi,protobufjs,openclaw'

# Read KEY=VALUE lines from .env (comments and blank lines ignored, optional quotes removed)
$values = @{}
if (Test-Path $envFile) {
    foreach ($line in Get-Content $envFile) {
        if ($line -match '^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*?)\s*$') {
            $values[$Matches[1]] = $Matches[2].Trim('"', "'")
        }
    }
}
$apiKey = $values['OPENROUTER_API_KEY']
$geminiKey = $values['GEMINI_API_KEY']

# Models tried in order when one hits its free quota (429) or is overloaded: the first is the default, the rest are fallbacks.
# OpenRouter free models share 50 requests/day; Gemini free quotas are per model, so each Gemini model adds its own.
# All tested with free answers and tool calling (2026-10-31). OpenRouter stays first also without a key (install only).
$models = @()
if ($apiKey -or -not $geminiKey) { $models += 'openrouter/openrouter/free' }
if ($geminiKey) { $models += 'google/gemini-3.6-flash', 'google/gemini-3.5-flash', 'google/gemini-3.5-flash-lite' }
$model = $models[0]
$fallbacks = @($models | Select-Object -Skip 1)

# openclaw stores the OpenRouter router shortened (openrouter/openrouter/free -> openrouter/free)
function Get-StoredModel($id) { $id -replace '^openrouter/openrouter/', 'openrouter/' }

# Node.js and npm global bin in this session too (a fresh install only updates PATH for new processes)
foreach ($dir in "$env:ProgramFiles\nodejs", "$env:APPDATA\npm") {
    if (($env:Path -split ';') -notcontains $dir) { $env:Path = "$dir;$env:Path" }
}

# Run openclaw and return its output; throws on a non-zero exit code.
# 'Continue' here: under 'Stop', Windows PowerShell 5.1 turns any stderr line (e.g. a Node.js warning) into a terminating error
function Invoke-OpenClaw {
    $ErrorActionPreference = 'Continue'
    $out = & openclaw @args 2>&1 | ForEach-Object { "$_" }
    if ($LASTEXITCODE -ne 0) { throw "openclaw $($args -join ' ') failed: exit code $LASTEXITCODE`n$($out -join "`n")" }
    $out
}

# Save a provider API key, passed on stdin so it does not show up in process lists (output is not shown: it may echo the key)
function Save-ApiKey($provider, $key) {
    $ErrorActionPreference = 'Continue'
    $key | & openclaw models auth paste-api-key --provider $provider 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Saving the $provider API key failed: exit code $LASTEXITCODE" }
}

# Value of a config path, or '' when unset or when the CLI or config is not usable yet
function Get-OpenClawConfig($path) {
    try { ((Invoke-OpenClaw config get $path) -join '').Trim().Trim('"') } catch { '' }
}

function Test-Cli { [bool](Get-Command openclaw -ErrorAction SilentlyContinue) }
function Test-Gateway {
    schtasks /query /tn $taskName 2>&1 | Out-Null
    ($LASTEXITCODE -eq 0) -and (Get-OpenClawConfig gateway.bind) -eq 'loopback'
}
function Test-Model {
    $stored = Get-OpenClawConfig agents.defaults.model.fallbacks
    $storedFallbacks = if ($stored) { @($stored | ConvertFrom-Json) } else { @() }
    ((Get-OpenClawConfig agents.defaults.model.primary) -eq (Get-StoredModel $model)) -and
        (($storedFallbacks -join ',') -eq (($fallbacks | ForEach-Object { Get-StoredModel $_ }) -join ','))
}
# True when the provider's key is empty in .env (nothing to save) or a profile is already saved for it
function Test-Key($provider, $key) {
    if (-not $key) { return $true }
    try { (Invoke-OpenClaw models auth list --provider $provider --json) -join '' -match "`"${provider}:" } catch { $false }
}

if ((Test-Cli) -and (Test-Gateway) -and (Test-Model) -and (Test-Key openrouter $apiKey) -and (Test-Key google $geminiKey)) {
    # OpenClaw is updated with: npm i -g openclaw@latest
    Write-Host 'Local OpenClaw Gateway is already set up, skipped'
    $global:SetupStepSkipped = $true
    return
}

# 1-2. Node.js and the OpenClaw CLI only when the CLI is missing: a later step being incomplete is no reason
# to upgrade a working install (an upgrade can restart or disable the running Gateway)
if (-not (Test-Cli)) {
    # 1. Node.js: install, or upgrade to the newest release (OpenClaw requires a recent Node.js)
    $winget = "$env:LOCALAPPDATA\Microsoft\WindowsApps\winget.exe"
    if (-not (Test-Path $winget)) { $winget = (Get-Command winget -ErrorAction SilentlyContinue).Source }
    if (-not $winget) { throw 'winget not found. Run setup-winget.ps1 first' }
    & $winget list --id OpenJS.NodeJS --exact --accept-source-agreements | Out-Null
    $verb = if ($LASTEXITCODE -eq 0) { 'upgrade' } else { 'install' }
    Write-Host "[1/6] Node.js: winget $verb"
    & $winget $verb --id OpenJS.NodeJS --exact -s winget --silent --accept-package-agreements --accept-source-agreements
    # -1978335189 (0x8A15002B): no newer version, -1978335135 (0x8A150061): already installed
    if ($LASTEXITCODE -notin 0, -1978335189, -1978335135) { throw "Node.js $verb failed: exit code $LASTEXITCODE" }
    & node --version

    # 2. OpenClaw CLI (latest)
    Write-Host '[2/6] Installing the OpenClaw CLI (npm, latest)'
    & npm install -g --allow-scripts=$allowScripts openclaw@latest --loglevel error --logs-dir $logDir
    if ($LASTEXITCODE -ne 0) { throw "npm install openclaw failed: exit code $LASTEXITCODE" }
    Invoke-OpenClaw --version | Select-Object -Last 1

    # A config left by an older OpenClaw can fail validation after an install; doctor migrates it
    try { Invoke-OpenClaw config validate | Out-Null } catch {
        Write-Host 'Repairing the existing OpenClaw config (openclaw doctor --fix)'
        Invoke-OpenClaw doctor --fix --non-interactive | Out-Null
    }
}

# 3. Onboard: Gateway on loopback with token auth, installed as a scheduled task; channels and skills are set up later
if (-not (Test-Gateway)) {
    Write-Host '[3/6] Running openclaw onboard (loopback + token, scheduled task)'
    Invoke-OpenClaw onboard --non-interactive --accept-risk --mode local --flow quickstart `
        --auth-choice skip --gateway-bind loopback --gateway-auth token --install-daemon `
        --skip-channels --skip-skills --skip-search --skip-ui --suppress-gateway-token-output | Out-Null
    if (-not (Test-Gateway)) { throw "Gateway was not set up (scheduled task '$taskName', gateway.bind=loopback)" }
}

# 4. Default model and fallbacks (the list is rebuilt so the order always matches)
if (-not (Test-Model)) {
    Write-Host "[4/6] Setting the default model to $model, fallbacks: $(if ($fallbacks) { $fallbacks -join ', ' } else { 'none' })"
    Invoke-OpenClaw models set $model | Out-Null
    Invoke-OpenClaw models fallbacks clear | Out-Null
    foreach ($fallback in $fallbacks) { Invoke-OpenClaw models fallbacks add $fallback | Out-Null }
}

# 5. OpenRouter API key
if (-not $apiKey) {
    Write-Host "[5/6] OPENROUTER_API_KEY is empty in $envFile. Add the key and run this step again."
} elseif (-not (Test-Key openrouter $apiKey)) {
    Write-Host '[5/6] Saving the OpenRouter API key'
    Save-ApiKey openrouter $apiKey
}

# 6. Gemini API key: needed by the google/* default model and fallbacks set in step 4
if (-not $geminiKey) {
    Write-Host "[6/6] GEMINI_API_KEY is empty in $envFile. Add the key and run this step again to use Gemini."
} elseif (-not (Test-Key google $geminiKey)) {
    Write-Host '[6/6] Saving the Gemini API key'
    Save-ApiKey google $geminiKey
    # The running Gateway only picks up new provider settings after a restart
    Write-Host 'Restarting the Gateway to apply the Gemini provider settings'
    Invoke-OpenClaw gateway restart | Out-Null
}

Write-Host 'Local OpenClaw Gateway setup done: ws://localhost:18789 (loopback, token auth)'
