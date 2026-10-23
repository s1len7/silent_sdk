# Change the hostname. Run as admin. Reboot to apply.
# Asks for the new hostname with -Default as the suggestion; Enter accepts the suggestion.
#   devices\windows\setup.ps1     -Default silent-desktop
#   devices\titan-s260\setup.ps1  -Default titan-s260

param(
    [Parameter(Mandatory)]
    [string]$Default
)

$ErrorActionPreference = 'Stop'

# Hostname rules (NetBIOS): 1-15 letters, digits or hyphens, not only digits, no hyphen at either end
function Test-Hostname([string]$value) {
    $value -match '^(?!-)(?!\d+$)[A-Za-z0-9-]{1,15}(?<!-)$'
}

if (-not (Test-Hostname $Default)) { throw "Invalid default hostname: $Default" }

while ($true) {
    $name = Read-Host "Hostname [$Default] (current: $env:COMPUTERNAME, Enter accepts $Default)"
    if (-not $name) { $name = $Default }
    if (Test-Hostname $name) { break }
    Write-Host "Invalid hostname: $name (1-15 letters, digits or hyphens, not only digits, no hyphen at either end)"
}

# COMPUTERNAME is upper case; -eq compares case-insensitively
if ($env:COMPUTERNAME -eq $name) {
    Write-Host "Hostname is already $name, skipped"
    $global:SetupStepSkipped = $true
    return
}

# Changed in an earlier run but not rebooted yet: the pending hostname is stored here
$pending = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName').ComputerName
if ($pending -eq $name) {
    Write-Host "Hostname is already changed to $name (reboot pending), skipped"
    $global:SetupStepSkipped = $true
    return
}

Rename-Computer -NewName $name -Force
Write-Host "Hostname changed: $env:COMPUTERNAME -> $name (reboot to apply)"
