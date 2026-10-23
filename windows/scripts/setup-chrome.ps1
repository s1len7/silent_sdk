# Setup the latest Google Chrome (enterprise 64-bit MSI, machine-wide). Run as admin.

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$msi = "$env:TEMP\googlechromestandaloneenterprise64.msi"
Invoke-WebRequest https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi -OutFile $msi -UseBasicParsing

$p = Start-Process msiexec.exe -ArgumentList "/i `"$msi`" /qn /norestart" -Wait -PassThru
if ($p.ExitCode -notin 0, 3010) { throw "Chrome installer failed: exit code $($p.ExitCode)" }
Write-Host 'Chrome setup done'
