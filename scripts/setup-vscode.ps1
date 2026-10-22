# Setup the latest Visual Studio Code (system installer x64, machine-wide). Run as admin.

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$exe = "$env:TEMP\VSCodeSetup-x64.exe"
Invoke-WebRequest https://update.code.visualstudio.com/latest/win32-x64/stable -OutFile $exe -UseBasicParsing

# Tasks: no launch after install, add to PATH, Explorer "Open with Code", file associations
$tasks = '!runcode,addtopath,addcontextmenufiles,addcontextmenufolders,associatewithfiles'
$p = Start-Process $exe -ArgumentList "/VERYSILENT /NORESTART /SUPPRESSMSGBOXES /MERGETASKS=$tasks" -Wait -PassThru
if ($p.ExitCode -ne 0) { throw "VS Code installer failed: exit code $($p.ExitCode)" }
Write-Host 'VS Code setup done'
