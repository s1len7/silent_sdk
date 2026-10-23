# Show the touch keyboard button on the taskbar (Windows 10, current user). Sign out or reboot to apply.

$ErrorActionPreference = 'Stop'

$key = 'HKCU:\Software\Microsoft\TabletTip\1.7'
if ((Get-ItemProperty $key -ErrorAction SilentlyContinue).TipbandDesiredVisibility -eq 1) {
    Write-Host 'Touch keyboard button is already enabled, skipped'
    $global:SetupStepSkipped = $true
    return
}

if (-not (Test-Path $key)) { New-Item $key -Force | Out-Null }
Set-ItemProperty $key TipbandDesiredVisibility 1 -Type DWord
Write-Host 'Touch keyboard button enabled on the taskbar (sign out or reboot to apply)'
