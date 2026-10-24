# Setup Telegram notifications for Claude Code: a Stop/Notification hook that messages a Telegram bot. Run as admin.
# Installs claude-telegram-notify.sh to ~/.claude/hooks/telegram-notify.sh, writes ~/.claude/telegram.env
# from devices/desktop/.env, and adds the hooks to ~/.claude/settings.json (other settings are kept).
# Skipped when TELEGRAM_BOT_TOKEN or TELEGRAM_CHAT_ID is empty in .env (see .env.example).

$ErrorActionPreference = 'Stop'

$envFile = Join-Path (Split-Path $PSScriptRoot) '.env'
$claudeDir = Join-Path $env:USERPROFILE '.claude'
$hookSrc = Join-Path $PSScriptRoot 'claude-telegram-notify.sh'
$hookDst = Join-Path $claudeDir 'hooks\telegram-notify.sh'
$confDst = Join-Path $claudeDir 'telegram.env'
$settingsFile = Join-Path $claudeDir 'settings.json'
$command = 'bash ~/.claude/hooks/telegram-notify.sh'
$events = 'Stop', 'Notification'
# Claude Code runs command hooks with Git Bash on Windows
$bash = "$env:ProgramFiles\Git\bin\bash.exe"

# Read KEY=VALUE lines from .env (comments and blank lines ignored, optional quotes removed)
$values = @{}
if (Test-Path $envFile) {
    foreach ($line in Get-Content $envFile) {
        if ($line -match '^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*?)\s*$') {
            $values[$Matches[1]] = $Matches[2].Trim('"', "'")
        }
    }
}
$token = $values['TELEGRAM_BOT_TOKEN']
$chatId = $values['TELEGRAM_CHAT_ID']
if (-not $token -or -not $chatId) {
    Write-Host "TELEGRAM_BOT_TOKEN or TELEGRAM_CHAT_ID is empty in $envFile, skipped"
    $global:SetupStepSkipped = $true
    return
}
if ($chatId -notmatch '^-?\d+$') { throw "TELEGRAM_CHAT_ID must be a number: $chatId" }

$conf = "# Written by silent_sdk devices/desktop/scripts/setup-claude-telegram.ps1 from devices/desktop/.env`n" +
    "TELEGRAM_BOT_TOKEN=$token`nTELEGRAM_CHAT_ID=$chatId`n"
$utf8 = New-Object Text.UTF8Encoding($false)

function Test-HookRegistered($settings, $eventName) {
    if (-not $settings -or -not $settings.hooks -or -not $settings.hooks.$eventName) { return $false }
    foreach ($entry in @($settings.hooks.$eventName)) {
        foreach ($hook in @($entry.hooks)) {
            if ($hook.command -eq $command) { return $true }
        }
    }
    return $false
}

$settings = $null
if (Test-Path $settingsFile) {
    $raw = [IO.File]::ReadAllText($settingsFile)
    if ($raw.Trim()) { $settings = $raw | ConvertFrom-Json }
}

$hookOk = (Test-Path $hookDst) -and (Get-FileHash $hookDst).Hash -eq (Get-FileHash $hookSrc).Hash
$confOk = (Test-Path $confDst) -and [IO.File]::ReadAllText($confDst) -eq $conf
$missing = @($events | Where-Object { -not (Test-HookRegistered $settings $_) })
if ($hookOk -and $confOk -and -not $missing) {
    Write-Host 'Claude Code Telegram notifications are already set up, skipped'
    $global:SetupStepSkipped = $true
    return
}

if (-not (Test-Path $bash)) { throw "Git Bash not found: $bash (run the git step first)" }

if (-not $hookOk) {
    New-Item -ItemType Directory -Force (Split-Path $hookDst) | Out-Null
    Copy-Item $hookSrc $hookDst -Force
    Write-Host "Hook script installed: $hookDst"
}
if (-not $confOk) {
    [IO.File]::WriteAllText($confDst, $conf, $utf8)
    Write-Host "Bot settings written: $confDst"
}
if ($missing) {
    # Add only the missing hook entries; everything else in settings.json stays as it is
    if (-not $settings) { $settings = New-Object PSObject }
    if (-not $settings.hooks) { $settings | Add-Member -NotePropertyName hooks -NotePropertyValue (New-Object PSObject) }
    foreach ($eventName in $missing) {
        $entry = [PSCustomObject]@{
            hooks = @([PSCustomObject]@{ type = 'command'; command = $command; timeout = 15; async = $true })
        }
        $list = @($settings.hooks.$eventName | Where-Object { $_ }) + $entry
        $settings.hooks | Add-Member -NotePropertyName $eventName -NotePropertyValue $list -Force
    }
    if (Test-Path $settingsFile) { Copy-Item $settingsFile "$settingsFile.bak" -Force }
    [IO.File]::WriteAllText($settingsFile, ($settings | ConvertTo-Json -Depth 20), $utf8)
    Write-Host "Hooks added to $settingsFile ($($missing -join ', '))"
}

Write-Host 'Claude Code Telegram notifications set up. Restart Claude Code or open /hooks to load them.'
