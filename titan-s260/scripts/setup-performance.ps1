# Setup low-spec performance tweaks for Windows 10. Run as admin. Sign out/reboot to apply visual changes.

$ErrorActionPreference = 'Stop'

function Disable-ServiceNow($name) {
    if (Get-Service $name -ErrorAction SilentlyContinue) {
        Stop-Service $name -Force -ErrorAction SilentlyContinue
        Set-Service $name -StartupType Disabled
        Write-Host "Service disabled: $name"
    }
}

function Set-Reg($path, $name, $value, $type = 'DWord') {
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-ItemProperty -Path $path -Name $name -Value $value -Type $type
}

function Get-RegValue($path, $name) {
    (Get-ItemProperty $path -ErrorAction SilentlyContinue).$name
}

# Already applied: one check per step below (the steps run in order and stop on error,
# so the last step being applied means the earlier ones were applied too)
$done = (Get-RegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' VisualFXSetting) -eq 2 -and
    -not (Get-Service WSearch, SysMain, DiagTrack -ErrorAction SilentlyContinue | Where-Object StartType -ne 'Disabled') -and
    (Get-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' AllowTelemetry) -eq 0 -and
    ((powercfg /getactivescheme) -match '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c') -and
    (Get-RegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\Power' HibernateEnabled) -eq 0
if ($done) {
    Write-Host 'Performance tweaks are already applied, skipped'
    $global:SetupStepSkipped = $true
    return
}

# 1. Visual effects: best performance, no transparency/animations, solid wallpaper
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' VisualFXSetting 2
Set-Reg 'HKCU:\Control Panel\Desktop' UserPreferencesMask ([byte[]](0x90, 0x12, 0x03, 0x80, 0x10, 0x00, 0x00, 0x00)) Binary
Set-Reg 'HKCU:\Control Panel\Desktop\WindowMetrics' MinAnimate '0' String
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' TaskbarAnimations 0
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' EnableTransparency 0
Set-Reg 'HKCU:\Control Panel\Desktop' Wallpaper '' String
Set-Reg 'HKCU:\Control Panel\Colors' Background '0 0 0' String
Write-Host 'Visual effects set to best performance'

# 2. Windows Search indexing
Disable-ServiceNow WSearch

# 3. SysMain (Superfetch)
Disable-ServiceNow SysMain

# 4. Telemetry
Disable-ServiceNow DiagTrack
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' AllowTelemetry 0

# 5. Power: High performance, never sleep / turn off display, no USB selective suspend
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
powercfg /change monitor-timeout-ac 0
powercfg /change standby-timeout-ac 0
powercfg /change hibernate-timeout-ac 0
powercfg /setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
powercfg /setactive SCHEME_CURRENT
Write-Host 'Power plan set to High performance'

# 6. Hibernation off (removes hiberfil.sys)
powercfg /hibernate off
Write-Host 'Hibernation disabled'
