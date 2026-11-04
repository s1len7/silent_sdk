# Send a Telegram notification through the notify-only bot.
# Config in devices/desktop/.env: TELEGRAM_NOTIFY_BOT_TOKEN and TELEGRAM_NOTIFY_CHAT_ID
# (falls back to TELEGRAM_ALLOW_FROM when the chat id is empty).
# The bot only sends: never call getUpdates with this token (a poller causes 409 conflicts).
# Usage: .\notify-telegram.ps1 -Text "setup finished" [-Agent opencode] [-HostName <host>]
#   .\notify-telegram.ps1 "setup finished" opencode
# Message format: [<host>][<agent>] <text>, truncated to 4096 characters.
# A failed notification only prints a warning and exits 0, so callers keep their own result.

[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)][string]$Text,
    [Parameter(Position = 1)][string]$Agent = 'manual',
    [Parameter(Position = 2)][string]$HostName = $env:COMPUTERNAME
)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$envFile = Join-Path (Split-Path $PSScriptRoot) '.env'

# Read KEY=VALUE lines from .env (comments and blank lines ignored, optional quotes removed)
$values = @{}
if (Test-Path $envFile) {
    foreach ($line in Get-Content $envFile) {
        if ($line -match '^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*?)\s*$') {
            $values[$Matches[1]] = $Matches[2].Trim('"', "'")
        }
    }
}
$token = $values['TELEGRAM_NOTIFY_BOT_TOKEN']
$chatId = $values['TELEGRAM_NOTIFY_CHAT_ID']
if (-not $chatId) { $chatId = $values['TELEGRAM_ALLOW_FROM'] }

if (-not $token -or -not $chatId) {
    Write-Warning "TELEGRAM_NOTIFY_BOT_TOKEN or TELEGRAM_NOTIFY_CHAT_ID is empty in $envFile, notification skipped"
    return
}
if ($chatId -notmatch '^-?\d+$') {
    Write-Warning "TELEGRAM_NOTIFY_CHAT_ID must be a number, notification skipped"
    return
}

$message = "[$HostName][$Agent] $Text"
if ($message.Length -gt 4096) { $message = $message.Substring(0, 4093) + '...' }

# Send UTF-8 JSON bytes: passing a hashtable to -Body form-encodes it and breaks non-ASCII
# text on Windows PowerShell 5.1, while UTF-8 JSON bytes arrive intact.
$body = @{ chat_id = $chatId; text = $message } | ConvertTo-Json -Compress
$bytes = [Text.Encoding]::UTF8.GetBytes($body)
try {
    $response = Invoke-RestMethod -Uri "https://api.telegram.org/bot$token/sendMessage" -Method Post `
        -ContentType 'application/json; charset=utf-8' -Body $bytes -TimeoutSec 30
    if (-not $response.ok) { throw 'Telegram returned ok=false' }
    Write-Host "Notification sent (message_id $($response.result.message_id))"
} catch {
    Write-Warning "Notification failed: $($_.Exception.Message)"
}
