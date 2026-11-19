# Point Claude Code directly at the Codyssey public API (~/.claude/settings.json).
# An existing ANTHROPIC_API_KEY is validated against <base>/v1/models: 200 keeps it,
# 401/403 asks for a new key, other or network errors keep it with a warning.
# A new key is validated before saving. Other settings keys are kept.
# Skips when Claude Code is not installed (~/.claude missing).

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$claudeHome = "$HOME\.claude"
$settingsPath = "$claudeHome\settings.json"
$baseUrl = 'https://copa.codyssey.kr'
$model = 'claude-opus-4-8'
$smallModel = 'claude-haiku-4'
$defaultOpus = 'claude-opus-4-8'
$defaultSonnet = 'claude-sonnet-4'
$defaultHaiku = 'claude-haiku-4'

if (-not (Test-Path $claudeHome)) {
    Write-Host "Claude Code is not installed ($claudeHome not found), skipped. Run this step again after installing it."
    $global:SetupStepSkipped = $true
    return
}

# Parsed JSON object; $null for a missing or empty file; throws on invalid JSON so the file is never overwritten
function Read-JsonFile($path) {
    if (-not (Test-Path $path)) { return $null }
    $text = [IO.File]::ReadAllText($path)
    if (-not $text.Trim()) { return $null }
    try { $text | ConvertFrom-Json } catch { throw "Invalid JSON in ${path}, fix or remove it: $($_.Exception.Message)" }
}

# HTTP status for the key (200 valid, 401/403 invalid, $null when the request could not be made)
function Test-ApiKey([string]$Key) {
    try {
        Invoke-WebRequest -Uri "$baseUrl/v1/models" -Headers @{ 'x-api-key' = $Key; 'anthropic-version' = '2023-06-01' } -UseBasicParsing -TimeoutSec 10 | Out-Null
        return 200
    } catch {
        if ($_.Exception.Response) {
            try { return [int]$_.Exception.Response.StatusCode } catch { }
        }
        return $null
    }
}

$settings = Read-JsonFile $settingsPath
if (-not $settings) { $settings = [pscustomobject]@{} }
if ($settings -isnot [pscustomobject]) { throw "Invalid settings.json: top level must be an object ($settingsPath)" }
$envObj = $settings.PSObject.Properties['env']
if (-not $envObj -or $null -eq $envObj.Value) {
    $settings | Add-Member -NotePropertyName env -NotePropertyValue ([pscustomobject]@{}) -Force
    $envObj = $settings.PSObject.Properties['env']
}
if ($envObj.Value -isnot [pscustomobject]) { throw "Invalid settings.json: env must be an object ($settingsPath)" }

$apiKey = $envObj.Value.ANTHROPIC_API_KEY
$hasKey = $apiKey -and $apiKey -notmatch '[<>]'
$needPrompt = $false
if ($hasKey) {
    $status = Test-ApiKey $apiKey
    if ($status -eq 200) {
        Write-Host "Existing API key is valid for $baseUrl"
    } elseif ($status -eq 401 -or $status -eq 403) {
        Write-Host "Existing API key is not valid for $baseUrl, entering a new key"
        $needPrompt = $true
    } else {
        if ($status) {
            Write-Host "Could not verify the existing API key (HTTP $status), keeping it"
        } else {
            Write-Host 'Could not verify the existing API key (network error), keeping it'
        }
    }
} else {
    $needPrompt = $true
}

if ($needPrompt) {
    while ($true) {
        try {
            $secure = Read-Host 'Paste the Codyssey Anthropic API key (Enter to skip)' -AsSecureString
        } catch {
            Write-Host 'No interactive terminal, skipped'
            $global:SetupStepSkipped = $true
            return
        }
        $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
        try { $newKey = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr) } finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
        if (-not $newKey) {
            Write-Host 'No API key entered, skipped'
            $global:SetupStepSkipped = $true
            return
        }
        $status = Test-ApiKey $newKey
        if ($status -eq 200) {
            $apiKey = $newKey
            break
        }
        if ($status -eq 401 -or $status -eq 403) {
            Write-Host 'The API key is not valid, try again.'
        } else {
            Write-Host 'Could not verify the API key (network), try again or press Ctrl+C.'
        }
    }
}

$desired = [ordered]@{
    ANTHROPIC_BASE_URL = $baseUrl
    ANTHROPIC_MODEL = $model
    ANTHROPIC_SMALL_FAST_MODEL = $smallModel
    ANTHROPIC_DEFAULT_OPUS_MODEL = $defaultOpus
    ANTHROPIC_DEFAULT_SONNET_MODEL = $defaultSonnet
    ANTHROPIC_DEFAULT_HAIKU_MODEL = $defaultHaiku
}
if ($apiKey) { $desired['ANTHROPIC_API_KEY'] = $apiKey }

$changes = @()
foreach ($name in $desired.Keys) {
    $current = $envObj.Value.PSObject.Properties[$name]
    if (-not $current -or $current.Value -ne $desired[$name]) {
        $changes += $name
    }
}
if (-not $changes) {
    Write-Host "Claude Code Codyssey settings are already set, skipped: $settingsPath"
    $global:SetupStepSkipped = $true
    return
}
foreach ($name in $changes) {
    $envObj.Value | Add-Member -NotePropertyName $name -NotePropertyValue $desired[$name] -Force
    Write-Host "Claude Code: set $name"
}

# UTF-8 without BOM; Claude Code reformats the file when it saves its own settings
[IO.File]::WriteAllText($settingsPath, ($settings | ConvertTo-Json -Depth 20), (New-Object Text.UTF8Encoding($false)))
Write-Host "Claude Code Codyssey settings updated: $settingsPath"
