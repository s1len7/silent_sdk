# Show the classic desktop icons (This PC, user's files, Network, Control Panel, Recycle Bin) for the current user. Run as admin.
# Same setting as Settings > Personalization > Themes > Desktop icon settings. Refresh the desktop (F5) or sign in again to see them.

$ErrorActionPreference = 'Stop'

# Desktop icon CLSIDs; value 0 under HideDesktopIcons\NewStartPanel means "show"
$icons = [ordered]@{
    'This PC'       = '{20D04FE0-3AEA-1069-A2D8-08002B30309D}'
    "User's Files"  = '{59031a47-3f72-44a7-89c5-5595fe6b30ee}'
    'Network'       = '{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}'
    'Control Panel' = '{5399E694-6CE5-4D6C-8FCE-1D8870FDCBA0}'
    'Recycle Bin'   = '{645FF040-5081-101B-9F08-00AA002F954E}'
}
$key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel'

$current = Get-ItemProperty $key -ErrorAction SilentlyContinue
$hidden = @($icons.Keys | Where-Object { $current.($icons[$_]) -ne 0 })
if (-not $hidden) {
    Write-Host 'Desktop icons are already shown, skipped'
    $global:SetupStepSkipped = $true
    return
}

if (-not (Test-Path $key)) { New-Item $key -Force | Out-Null }
foreach ($name in $hidden) {
    Set-ItemProperty $key $icons[$name] 0 -Type DWord
    Write-Host "Desktop icon shown: $name"
}
Write-Host 'Refresh the desktop (F5) or sign in again to see the icons'
