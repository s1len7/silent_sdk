# Install and run the Claude Code proxy (unified Anthropic + OpenAI proxy to the Codyssey gateway).
# Reads COPA_API_KEY from devices/desktop/.env (skipped when empty).
# Installs the codyssey-proxy tool (pip, editable from the repo), writes ~/.codyssey-proxy/.env,
# registers an auto-start entry, and points Claude Code (~/.claude/settings.json) at the proxy.
# Claude Code must be installed (~/.claude exists) for the settings update; proxy still installs otherwise.

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$envFile = Join-Path (Split-Path $PSScriptRoot) '.env'
$values = @{}
if (Test-Path $envFile) {
    foreach ($line in Get-Content $envFile) {
        if ($line -match '^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*?)\s*$') {
            $values[$Matches[1]] = $Matches[2].Trim('"', "'")
        }
    }
}
$copaKey = $values['COPA_API_KEY']

if (-not $copaKey) {
    Write-Host "COPA_API_KEY is empty in $envFile, skipped. Add it and run again."
    $global:SetupStepSkipped = $true
    return
}

# Python must be available (run setup-python.ps1 first)
$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) {
    Write-Host "python not found, skipped. Run setup-python first."
    $global:SetupStepSkipped = $true
    return
}

$proxyDir = Join-Path $HOME '.codyssey-proxy'
if (-not (Test-Path $proxyDir)) { New-Item -ItemType Directory -Path $proxyDir -Force | Out-Null }

# Install the tool (editable from repo)
$prevEAP = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
& python -m pip install -e (Join-Path $repo 'tools\codyssey-proxy') --quiet 2>$null | Out-Null
$pipExit = $LASTEXITCODE
$ErrorActionPreference = $prevEAP
if ($pipExit -ne 0) { throw "pip install codyssey-proxy failed (exit $pipExit)" }

# Write .env
$envPath = Join-Path $proxyDir '.env'
$envContent = @"
OPENAI_API_BASE=https://copa.codyssey.kr/v1
OPENAI_API_KEY=$copaKey
BIG_MODEL=claude-sonnet-4
SMALL_MODEL=claude-haiku-4
PROXY_HOST=127.0.0.1
PROXY_PORT=8082
"@
[IO.File]::WriteAllText($envPath, $envContent, (New-Object Text.UTF8Encoding($false)))

# Launcher that runs the proxy hidden
$launcher = Join-Path $proxyDir 'run-proxy.ps1'
$launcherContent = @"
`$env:PYTHONIOENCODING = 'utf-8'
Set-Location '$proxyDir'
& python -m codyssey_proxy 2>&1 | Out-Null
"@
[IO.File]::WriteAllText($launcher, $launcherContent, (New-Object Text.UTF8Encoding($false)))

# Auto-start via Startup folder
$startup = [Environment]::GetFolderPath('Startup')
$shortcutPath = Join-Path $startup 'Codyssey Proxy.lnk'
$ws = New-Object -ComObject WScript.Shell
$sc = $ws.CreateShortcut($shortcutPath)
$sc.TargetPath = 'powershell.exe'
$sc.Arguments = "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$launcher`""
$sc.WorkingDirectory = $proxyDir
$sc.Save()

# Start now if not running
$running = $false
try {
    $t = Test-NetConnection -ComputerName 127.0.0.1 -Port 8082 -WarningAction SilentlyContinue
    $running = $t.TcpTestSucceeded
} catch { $running = $false }
if (-not $running) {
    Start-Process powershell.exe -ArgumentList "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$launcher`"" -WindowStyle Hidden
    Start-Sleep -Seconds 4
}

# Update Claude Code settings to use the proxy
$claudeHome = "$HOME\.claude"
$settingsPath = "$claudeHome\settings.json"
if (Test-Path $claudeHome) {
    function Read-JsonFile($path) {
        if (-not (Test-Path $path)) { return $null }
        $text = [IO.File]::ReadAllText($path)
        if (-not $text.Trim()) { return $null }
        try { $text | ConvertFrom-Json } catch { throw "Invalid JSON in ${path}: $($_.Exception.Message)" }
    }
    $settings = Read-JsonFile $settingsPath
    if (-not $settings) { $settings = [pscustomobject]@{} }
    $envObj = $settings.PSObject.Properties['env']
    if (-not $envObj) {
        $settings | Add-Member -NotePropertyName env -NotePropertyValue ([pscustomobject]@{}) -Force
        $envObj = $settings.PSObject.Properties['env']
    }
    $envObj.Value | Add-Member -NotePropertyName ANTHROPIC_BASE_URL -NotePropertyValue 'http://localhost:8082' -Force
    $envObj.Value | Add-Member -NotePropertyName ANTHROPIC_MODEL -NotePropertyValue 'claude-sonnet-4-5' -Force
    $envObj.Value | Add-Member -NotePropertyName ANTHROPIC_SMALL_FAST_MODEL -NotePropertyValue 'claude-haiku-4-5' -Force
    $envObj.Value | Add-Member -NotePropertyName ANTHROPIC_DEFAULT_SONNET_MODEL -NotePropertyValue 'claude-sonnet-4-5' -Force
    $envObj.Value | Add-Member -NotePropertyName ANTHROPIC_DEFAULT_HAIKU_MODEL -NotePropertyValue 'claude-haiku-4-5' -Force
    $envObj.Value | Add-Member -NotePropertyName ANTHROPIC_DEFAULT_OPUS_MODEL -NotePropertyValue 'claude-opus-4-7' -Force
    [IO.File]::WriteAllText($settingsPath, ($settings | ConvertTo-Json -Depth 20), (New-Object Text.UTF8Encoding($false)))
    Write-Host "Claude Code settings updated to use the local proxy."
} else {
    Write-Host "Claude Code not installed ($claudeHome not found); settings not updated. Run setup-claude-settings after installing Claude Code."
}

Write-Host "Codyssey proxy installed and running on http://localhost:8082"