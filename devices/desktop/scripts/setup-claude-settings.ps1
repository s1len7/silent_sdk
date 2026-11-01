# Put the silent_sdk Claude Code settings into the user-level settings (~\.claude\settings.json) of the current user.
# settings.json cannot include another file, so the repo keeps the source (devices\desktop\config\claude-settings.json)
# and this step copies its top-level keys over; every other key in the user settings is kept.
# The repo root is also added to permissions.additionalDirectories so its rules and skills can be read from any project.
# An invalid settings.json is never overwritten. Claude Code must be installed (~\.claude exists).

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$claudeHome = "$HOME\.claude"
$settingsPath = "$claudeHome\settings.json"
$sourcePath = (Resolve-Path (Join-Path $PSScriptRoot '..\config\claude-settings.json')).Path
# Repo root with forward slashes, the form Claude Code documents for paths
$repoPath = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path.Replace('\', '/')

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

# Compact JSON text, to compare values regardless of formatting
function ConvertTo-Compact($value) { $value | ConvertTo-Json -Depth 20 -Compress }

$source = Read-JsonFile $sourcePath
if (-not $source) { throw "No settings in $sourcePath" }
$settings = Read-JsonFile $settingsPath
if (-not $settings) { $settings = [pscustomobject]@{} }

# Source keys whose value differs from the user settings
$pending = @($source.PSObject.Properties | Where-Object {
    $current = $settings.PSObject.Properties[$_.Name]
    -not $current -or (ConvertTo-Compact $current.Value) -ne (ConvertTo-Compact $_.Value)
} | ForEach-Object Name)
$permissions = $settings.PSObject.Properties['permissions']
$directories = if ($permissions -and $permissions.Value.PSObject.Properties['additionalDirectories']) {
    @($permissions.Value.additionalDirectories)
} else { @() }
$needsDirectory = -not ($directories | Where-Object { $_.Replace('\', '/').TrimEnd('/') -eq $repoPath })

if (-not $pending -and -not $needsDirectory) {
    Write-Host "Claude Code settings are already set, skipped: $(@($source.PSObject.Properties.Name) -join ', '), additionalDirectories"
    $global:SetupStepSkipped = $true
    return
}

foreach ($name in $pending) {
    $settings | Add-Member -NotePropertyName $name -NotePropertyValue $source.$name -Force
    Write-Host "Claude Code: set $name"
}
if ($needsDirectory) {
    if (-not $permissions) {
        $settings | Add-Member -NotePropertyName permissions -NotePropertyValue ([pscustomobject]@{})
    }
    $settings.permissions | Add-Member -NotePropertyName additionalDirectories -NotePropertyValue (@($directories) + $repoPath) -Force
    Write-Host "Claude Code: added $repoPath to permissions.additionalDirectories"
}

# UTF-8 without BOM; Claude Code reformats the file when it saves its own settings
[IO.File]::WriteAllText($settingsPath, ($settings | ConvertTo-Json -Depth 20), (New-Object Text.UTF8Encoding($false)))
Write-Host "Claude Code settings updated: $settingsPath"
