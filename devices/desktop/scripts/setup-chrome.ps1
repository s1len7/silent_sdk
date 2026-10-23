# Setup the latest Google Chrome (enterprise 64-bit MSI, machine-wide). Run as admin.

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Installer logs go to the setup log folder (TEMP when run alone)
$logDir = if ($env:SILENT_SDK_LOG_DIR) { $env:SILENT_SDK_LOG_DIR } else { $env:TEMP }

# Already installed: Chrome keeps itself up to date
$chrome = "$env:ProgramFiles\Google\Chrome\Application\chrome.exe", "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe" |
    Where-Object { Test-Path $_ } | Select-Object -First 1
if ($chrome) {
    Write-Host "Chrome is already installed, skipped: $chrome"
    $global:SetupStepSkipped = $true
    return
}

$msi = "$env:TEMP\googlechromestandaloneenterprise64.msi"
Invoke-WebRequest https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi -OutFile $msi -UseBasicParsing

$p = Start-Process msiexec.exe -ArgumentList "/i `"$msi`" /qn /norestart /l*v `"$logDir\chrome-msi.log`"" -Wait -PassThru
if ($p.ExitCode -notin 0, 3010) { throw "Chrome installer failed: exit code $($p.ExitCode)" }
Write-Host 'Chrome setup done'
