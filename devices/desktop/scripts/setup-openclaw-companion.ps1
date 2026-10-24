# Setup the OpenClaw Companion tray app (winget) and connect it to the local Gateway from setup-openclaw.ps1. Run as admin.
# The tray app has no command-line option for adding a gateway, so this writes the connection into its
# gateways.json (URL + the local Gateway token), restarts the app, and approves only the pairing requests
# whose device ID matches the key the app created for that connection (operator, then node).
# Other connections already in gateways.json are kept; the local one becomes the active connection.

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$packageId = 'OpenClaw.OpenClawCompanion'
$trayExe = "$env:LOCALAPPDATA\OpenClawTray\OpenClaw.Tray.WinUI.exe"
$trayProcess = 'OpenClaw.Tray.WinUI'
$trayData = "$env:APPDATA\OpenClawTray"
$gatewaysFile = "$trayData\gateways.json"
$localUrl = 'ws://localhost:18789'
$openclawConfig = "$env:USERPROFILE\.openclaw\openclaw.json"
$waitSeconds = 90

foreach ($dir in "$env:ProgramFiles\nodejs", "$env:APPDATA\npm") {
    if (($env:Path -split ';') -notcontains $dir) { $env:Path = "$dir;$env:Path" }
}
if (-not (Get-Command openclaw -ErrorAction SilentlyContinue) -or -not (Test-Path $openclawConfig)) {
    throw 'Local OpenClaw Gateway is not set up. Run setup-openclaw.ps1 first'
}

# Parsed JSON output of an openclaw command (log lines before the JSON are ignored)
function Get-OpenClawJson {
    $out = (& openclaw @args 2>$null) -join "`n"
    if ($LASTEXITCODE -ne 0) { throw "openclaw $($args -join ' ') failed: exit code $LASTEXITCODE" }
    $out.Substring($out.IndexOf('{')) | ConvertFrom-Json
}

# The local connection in gateways.json, or $null
function Get-LocalGateway($data) {
    @($data.gateways | Where-Object { $_.url -match '^ws://(localhost|127\.0\.0\.1):18789/?$' })[0]
}

# Device ID the tray app created for a connection, or $null before its first connect
function Get-TrayDeviceId($gateway) {
    $keyFile = "$trayData\gateways\$($gateway.identityDirName)\device-key-ed25519.json"
    if (Test-Path $keyFile) { (Get-Content $keyFile -Raw | ConvertFrom-Json).DeviceId }
}

# True when the device is paired with the operator and node roles and its node is approved
function Test-Paired($deviceId) {
    if (-not $deviceId) { return $false }
    $device = @((Get-OpenClawJson devices list --json).paired | Where-Object deviceId -eq $deviceId)[0]
    $node = @((Get-OpenClawJson nodes list --json).paired | Where-Object nodeId -eq $deviceId)[0]
    $device -and $device.roles -contains 'operator' -and $device.roles -contains 'node' -and $node
}

$winget = "$env:LOCALAPPDATA\Microsoft\WindowsApps\winget.exe"
if (-not (Test-Path $winget)) { $winget = (Get-Command winget -ErrorAction SilentlyContinue).Source }
if (-not $winget) { throw 'winget not found. Run setup-winget.ps1 first' }

$installed = Test-Path $trayExe
$data = if (Test-Path $gatewaysFile) { Get-Content $gatewaysFile -Raw | ConvertFrom-Json } else { $null }
$gateway = if ($data) { Get-LocalGateway $data } else { $null }
if ($installed -and $gateway -and $data.activeId -eq $gateway.id -and (Test-Paired (Get-TrayDeviceId $gateway))) {
    Write-Host 'OpenClaw Companion is already installed and paired with the local Gateway, skipped'
    $global:SetupStepSkipped = $true
    return
}

# 1. Install the tray app
if (-not $installed) {
    Write-Host "[1/3] Installing OpenClaw Companion ($packageId)"
    & $winget install --id $packageId --exact -s winget --silent --accept-package-agreements --accept-source-agreements
    # -1978335189 (0x8A15002B): already installed / no newer version, treated as success
    if ($LASTEXITCODE -notin 0, -1978335189) { throw "OpenClaw Companion setup failed: exit code $LASTEXITCODE" }
    if (-not (Test-Path $trayExe)) { throw "OpenClaw Companion not found after install: $trayExe" }
}

# 2. Write the local connection (the app rewrites gateways.json, so it is stopped first)
Write-Host "[2/3] Connecting OpenClaw Companion to the local Gateway ($localUrl)"
Get-Process $trayProcess -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 2
$token = (Get-Content $openclawConfig -Raw | ConvertFrom-Json).gateway.auth.token
if (-not $token -or $token -isnot [string]) { throw "Local Gateway token not found in $openclawConfig" }
if (-not $data) {
    New-Item -ItemType Directory -Force $trayData | Out-Null
    $data = [pscustomobject]@{ gateways = @(); activeId = $null }
}
if (-not $gateway) {
    # Same fields the app writes when a gateway is added in its UI
    $id = [guid]::NewGuid().ToString()
    $gateway = [pscustomobject][ordered]@{
        id = $id; url = $localUrl; friendlyName = $null; sharedGatewayToken = $token; bootstrapToken = $null
        lastConnected = $null; isLocal = $false; requiresV2Signature = $false; setupManagedDistroName = $null
        nativePackageFamilyName = $null; nativeRuntimeContract = $null; sshTunnel = $null
        browserControlPort = $null; identityDirName = $id
    }
    $data.gateways = @($data.gateways) + $gateway
} else {
    $gateway.sharedGatewayToken = $token
}
$data.activeId = $gateway.id
[IO.File]::WriteAllText($gatewaysFile, ($data | ConvertTo-Json -Depth 10), (New-Object Text.UTF8Encoding($false)))

# Start the app as the signed-in user, not elevated like this script (explorer.exe launches it unelevated)
Start-Process explorer.exe $trayExe

# 3. Approve the app's own pairing requests: operator (device) first, then node
Write-Host "[3/3] Approving the pairing requests of OpenClaw Companion (waiting up to $waitSeconds s)"
$deadline = (Get-Date).AddSeconds($waitSeconds)
$deviceId = $null
while (-not ($deviceId = Get-TrayDeviceId $gateway) -and (Get-Date) -lt $deadline) { Start-Sleep -Seconds 2 }
if (-not $deviceId) { throw "OpenClaw Companion did not create a device key for $localUrl. Open the app and check the connection" }

$approved = @()
while (-not (Test-Paired $deviceId) -and (Get-Date) -lt $deadline) {
    foreach ($request in @((Get-OpenClawJson devices list --json).pending | Where-Object deviceId -eq $deviceId)) {
        & openclaw devices approve $request.requestId | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "Approving device request $($request.requestId) failed: exit code $LASTEXITCODE" }
        $approved += "device $($request.requestId)"
    }
    foreach ($request in @((Get-OpenClawJson nodes list --json).pending | Where-Object nodeId -eq $deviceId)) {
        & openclaw nodes approve $request.requestId | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "Approving node request $($request.requestId) failed: exit code $LASTEXITCODE" }
        $approved += "node $($request.requestId)"
    }
    Start-Sleep -Seconds 3
}
if (-not (Test-Paired $deviceId)) {
    throw "OpenClaw Companion was not paired within $waitSeconds s (approved: $($approved -join ', ')). Run this step again"
}
Write-Host "OpenClaw Companion paired with the local Gateway (device $deviceId)"
