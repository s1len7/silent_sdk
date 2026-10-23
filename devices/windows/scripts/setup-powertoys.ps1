# Setup the latest PowerToys (machine-wide x64) from GitHub releases. Run as admin.

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Installer logs go to the setup log folder (TEMP when run alone)
$logDir = if ($env:SILENT_SDK_LOG_DIR) { $env:SILENT_SDK_LOG_DIR } else { $env:TEMP }

# PowerToys policies (HKLM\SOFTWARE\Policies\PowerToys, read by PowerToys at startup):
#   DoNotShowWhatsNewAfterUpdates: no "What's new" window on first run or after updates
#   ConfigureEnabledUtilityZoomIt: ZoomIt always enabled
$policy = 'HKLM:\SOFTWARE\Policies\PowerToys'
$ptData = "$env:LOCALAPPDATA\Microsoft\PowerToys"

# Already installed (machine-wide or per-user; the machine-wide installer fails over a per-user one)
$installed = (Test-Path "$env:ProgramFiles\PowerToys\PowerToys.exe") -or (Test-Path "$env:LOCALAPPDATA\PowerToys\PowerToys.exe")
$values = Get-ItemProperty $policy -ErrorAction SilentlyContinue
$configured = $values.DoNotShowWhatsNewAfterUpdates -eq 1 -and $values.ConfigureEnabledUtilityZoomIt -eq 1 -and
    (Test-Path "$ptData\oobe_settings.json")
if ($installed -and $configured) {
    # PowerToys keeps itself up to date
    Write-Host 'PowerToys is already installed and configured, skipped'
    $global:SetupStepSkipped = $true
    return
}

# Settings first, so the installer's first launch already sees them
if (-not (Test-Path $policy)) { New-Item $policy | Out-Null }
Set-ItemProperty $policy DoNotShowWhatsNewAfterUpdates 1 -Type DWord
Set-ItemProperty $policy ConfigureEnabledUtilityZoomIt 1 -Type DWord

# Skip the welcome (OOBE) window that opens on first run when this file is missing
New-Item -ItemType Directory -Force $ptData | Out-Null
Set-Content "$ptData\oobe_settings.json" '{"openedAtFirstLaunch":true}' -Encoding Ascii

if ($installed) {
    Write-Host 'PowerToys is already installed, settings applied'
    return
}

$release = Invoke-RestMethod https://api.github.com/repos/microsoft/PowerToys/releases/latest -UseBasicParsing
$asset = $release.assets | Where-Object name -match '^PowerToysSetup-[\d.]+-x64\.exe$' | Select-Object -First 1
$exe = "$env:TEMP\$($asset.name)"
Invoke-WebRequest $asset.browser_download_url -OutFile $exe -UseBasicParsing

$p = Start-Process $exe -ArgumentList "/quiet /norestart /log `"$logDir\powertoys-install.log`"" -Wait -PassThru
if ($p.ExitCode -notin 0, 3010) { throw "PowerToys installer failed: exit code $($p.ExitCode)" }
Write-Host "PowerToys $($release.tag_name) setup done"
