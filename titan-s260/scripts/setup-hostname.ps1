# Rename this computer to titan-s260 if it has a different name. Run as admin. Reboot to apply.

$ErrorActionPreference = 'Stop'

$name = 'titan-s260'

# COMPUTERNAME is upper case; -eq compares case-insensitively
if ($env:COMPUTERNAME -eq $name) {
    Write-Host "Computer name is already $name, skipped"
    $global:SetupStepSkipped = $true
    return
}

# Renamed in an earlier run but not rebooted yet: the pending name is stored here
$pending = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName').ComputerName
if ($pending -eq $name) {
    Write-Host "Computer is already renamed to $name (reboot pending), skipped"
    $global:SetupStepSkipped = $true
    return
}

Rename-Computer -NewName $name -Force
Write-Host "Computer renamed: $env:COMPUTERNAME -> $name (reboot to apply)"
