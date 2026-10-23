<#
.SYNOPSIS
    Windows 10 IoT activation script (titan-s260)

.DESCRIPTION
    1. Use the product key from -ProductKey, or read the OEM key (OA3) embedded in the firmware (BIOS/UEFI).
    2. Install the key with slmgr and try online activation.
    3. Print the activation result.

.EXAMPLE
    .\activate-win10-iot.ps1
    .\activate-win10-iot.ps1 -ProductKey XXXXX-XXXXX-XXXXX-XXXXX-XXXXX
#>
param(
    [string]$ProductKey,
    [switch]$NoPause  # Skip the exit prompt when called from the full setup
)

$ErrorActionPreference = 'Stop'

function Wait-Exit {
    if (-not $NoPause) { Read-Host 'Press Enter to exit' | Out-Null }
}

# Check admin rights; if missing, re-launch as admin
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $argList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`"")
    if ($ProductKey) { $argList += @('-ProductKey', $ProductKey) }
    Start-Process powershell.exe -Verb RunAs -ArgumentList $argList
    exit
}

$slmgr = "$env:SystemRoot\System32\slmgr.vbs"

function Get-ActivationStatus {
    Get-CimInstance SoftwareLicensingProduct -Filter "ApplicationID='55c92734-d682-4d71-983e-d6ec3f16059f' AND PartialProductKey IS NOT NULL" |
        Select-Object -First 1 Name, Description, PartialProductKey, LicenseStatus
}

$os = Get-CimInstance Win32_OperatingSystem
Write-Host "OS: $($os.Caption) ($($os.Version))"

$status = Get-ActivationStatus
if ($status -and $status.LicenseStatus -eq 1) {
    Write-Host "Already activated. ($($status.Name), key ends with $($status.PartialProductKey))" -ForegroundColor Green
    $global:SetupStepSkipped = $true
    Wait-Exit
    exit 0
}

if (-not $ProductKey) {
    $ProductKey = (Get-CimInstance SoftwareLicensingService).OA3xOriginalProductKey
    if ($ProductKey) {
        Write-Host 'Found the OEM product key embedded in the firmware.'
    } else {
        $ProductKey = Read-Host 'No key embedded in the firmware. Enter a product key (XXXXX-XXXXX-XXXXX-XXXXX-XXXXX)'
    }
}

if ($ProductKey -notmatch '^[A-Z0-9]{5}(-[A-Z0-9]{5}){4}$') {
    Write-Host "Invalid product key format: $ProductKey" -ForegroundColor Red
    Wait-Exit
    exit 1
}

Write-Host 'Installing product key...'
cscript.exe //nologo $slmgr /ipk $ProductKey

Write-Host 'Activating online...'
cscript.exe //nologo $slmgr /ato

$status = Get-ActivationStatus
if ($status -and $status.LicenseStatus -eq 1) {
    Write-Host "Activation completed ($($status.Name))" -ForegroundColor Green
    $code = 0
} else {
    Write-Host 'Activation failed. Check the internet connection and the product key. Details: slmgr /dlv' -ForegroundColor Red
    $code = 1
}

Wait-Exit
exit $code
