# Rename this computer. Run as admin. Reboot to apply.
# Asks for the new name with -Default as the suggestion; Enter accepts the suggestion.
#   devices\windows\setup.ps1     -Default silent-desktop
#   devices\titan-s260\setup.ps1  -Default titan-s260

param(
    [Parameter(Mandatory)]
    [string]$Default
)

$ErrorActionPreference = 'Stop'

# NetBIOS computer name rules: 1-15 letters, digits or hyphens, not only digits, no hyphen at either end
function Test-ComputerName([string]$value) {
    $value -match '^(?!-)(?!\d+$)[A-Za-z0-9-]{1,15}(?<!-)$'
}

if (-not (Test-ComputerName $Default)) { throw "Invalid default computer name: $Default" }

while ($true) {
    $name = Read-Host "Computer name [$Default] (current: $env:COMPUTERNAME, Enter accepts $Default)"
    if (-not $name) { $name = $Default }
    if (Test-ComputerName $name) { break }
    Write-Host "Invalid name: $name (1-15 letters, digits or hyphens, not only digits, no hyphen at either end)"
}

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
