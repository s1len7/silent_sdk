# Setup OpenCLI (https://github.com/jackwener/OpenCLI) with OpenCLIApp, the install the project recommends for Windows.
# The app bundles the OpenCLI runtime, manages the `opencli` command and its updates, and installs the agent skills
# into ~/.agents/skills, which OpenClaw also loads. The npm package (@jackwener/opencli) is meant for CLI-only servers.
# The app only creates the `opencli` command from its System page, so a fresh install asks for that one manual step.
# Docs: https://github.com/jackwener/OpenCLI#quick-start

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$appExe = "$env:LOCALAPPDATA\OpenCLIApp\opencli-app.exe"
# The app's own update manifest: latest version and installer URL per platform
$manifestUrl = 'https://opencli.info/download/latest.json'
$extensionId = 'ildkmabpimmkaediidaifkhjpohdnifk'
$extensionUrl = "https://chromewebstore.google.com/detail/opencli/$extensionId"

function Test-Command { [bool](Get-Command opencli -ErrorAction SilentlyContinue) }

# Browser Bridge extension in any Chrome profile; only a hint, it is installed from the Chrome Web Store by hand
function Write-ExtensionHint {
    $profiles = Get-ChildItem "$env:LOCALAPPDATA\Google\Chrome\User Data" -Directory -ErrorAction SilentlyContinue
    if (-not ($profiles | Where-Object { Test-Path "$($_.FullName)\Extensions\$extensionId" })) {
        Write-Warning "OpenCLI Browser Bridge extension not found in Chrome. Install it for browser commands: $extensionUrl"
    }
}

if (Test-Command) {
    Write-Host 'OpenCLI is already set up (opencli command found), skipped. Updates: OpenCLIApp tray menu'
    Write-ExtensionHint
    $global:SetupStepSkipped = $true
    return
}

# 1. OpenCLIApp (per-user install, silent)
if (-not (Test-Path $appExe)) {
    $manifest = Invoke-RestMethod $manifestUrl -UseBasicParsing
    $url = $manifest.platforms.'windows-x86_64'.url
    if (-not $url) { throw "No Windows installer in $manifestUrl" }
    $exe = "$env:TEMP\OpenCLIApp-setup.exe"
    Write-Host "[1/2] Installing OpenCLIApp $($manifest.version)"
    Invoke-WebRequest $url -OutFile $exe -UseBasicParsing
    $p = Start-Process $exe -ArgumentList '/S' -Wait -PassThru
    if ($p.ExitCode -ne 0) { throw "OpenCLIApp installer failed: exit code $($p.ExitCode)" }
    if (-not (Test-Path $appExe)) { throw "opencli-app.exe not found after install: $appExe" }
}

# 2. The `opencli` command comes from the app's System page (no command line option for it)
Write-Host '[2/2] Starting OpenCLIApp'
if (-not (Get-Process opencli-app -ErrorAction SilentlyContinue)) { Start-Process $appExe }
Write-ExtensionHint
throw 'OpenCLIApp is installed, but the opencli command is missing. Open OpenCLIApp > System, install the opencli command, then run this step again'
