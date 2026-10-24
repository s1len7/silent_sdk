# Setup the OpenClaw Companion tray app (winget) and connect it to a remote Gateway (e.g. the b150m-am2 VM). Run as admin.
# No Gateway or OpenClaw CLI runs on this PC. The app's pairing requests are approved by running openclaw on the
# Gateway host over ssh: a CLI connecting from here with --url/--token is itself a new device that needs pairing.
# Values come from devices/desktop/.env (skipped when any is empty):
#   OPENCLAW_GATEWAY_URL   (ws:// or wss:// URL the app connects to)
#   OPENCLAW_GATEWAY_TOKEN (gateway.auth.token of the Gateway)
#   OPENCLAW_GATEWAY_SSH   (user@host of the Gateway host; key-based ssh login must work, used only during setup)
# Like setup-openclaw-companion.ps1, this writes the connection into the app's gateways.json, restarts the app,
# and approves only the requests whose device ID matches the key the app created for that connection.
# Other connections already in gateways.json are kept; the remote one becomes the active connection.
# Needs winget: setup-winget.ps1 runs before this step and installs it when missing.

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$envFile = Join-Path (Split-Path $PSScriptRoot) '.env'
$packageId = 'OpenClaw.OpenClawCompanion'
$trayExe = "$env:LOCALAPPDATA\OpenClawTray\OpenClaw.Tray.WinUI.exe"
$trayProcess = 'OpenClaw.Tray.WinUI'
$trayData = "$env:APPDATA\OpenClawTray"
$gatewaysFile = "$trayData\gateways.json"
# Windows built-in OpenSSH client
$ssh = "$env:WINDIR\System32\OpenSSH\ssh.exe"
$waitSeconds = 90

# Read KEY=VALUE lines from .env (comments and blank lines ignored, optional quotes removed)
$values = @{}
if (Test-Path $envFile) {
    foreach ($line in Get-Content $envFile) {
        if ($line -match '^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*?)\s*$') {
            $values[$Matches[1]] = $Matches[2].Trim('"', "'")
        }
    }
}
$url = "$($values['OPENCLAW_GATEWAY_URL'])".TrimEnd('/')
$token = $values['OPENCLAW_GATEWAY_TOKEN']
$sshTarget = $values['OPENCLAW_GATEWAY_SSH']
if (-not $url -or -not $token -or -not $sshTarget) {
    Write-Host "OPENCLAW_GATEWAY_URL, OPENCLAW_GATEWAY_TOKEN or OPENCLAW_GATEWAY_SSH is empty in $envFile, skipped"
    $global:SetupStepSkipped = $true
    return
}
if ($url -notmatch '^wss?://') { throw "OPENCLAW_GATEWAY_URL must start with ws:// or wss://: $url" }
if ($sshTarget -notmatch '^[A-Za-z0-9._-]+@[A-Za-z0-9.-]+$') { throw "OPENCLAW_GATEWAY_SSH must look like user@host: $sshTarget" }
if (-not (Test-Path $ssh)) { throw "OpenSSH client not found: $ssh (Settings > Apps > Optional features > OpenSSH Client)" }

# Run openclaw on the Gateway host and return its output; throws on a non-zero exit code.
# BatchMode makes ssh fail instead of asking for a password; a new host key is accepted on first connect.
function Invoke-RemoteOpenClaw {
    $out = (& $ssh -o BatchMode=yes -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new $sshTarget "openclaw $($args -join ' ')" 2>$null) -join "`n"
    if ($LASTEXITCODE -ne 0) { throw "ssh $sshTarget 'openclaw $($args -join ' ')' failed: exit code $LASTEXITCODE (check key-based ssh login)" }
    $out
}

# Parsed JSON output of a remote openclaw list command (log lines before the JSON are ignored)
function Get-RemoteJson {
    $out = Invoke-RemoteOpenClaw @args --json
    if ($out.IndexOf('{') -lt 0) { throw "No JSON from 'openclaw $($args -join ' ')' on $sshTarget" }
    $out.Substring($out.IndexOf('{')) | ConvertFrom-Json
}

# The connection to $url in gateways.json, or $null
function Get-RemoteGateway($data) {
    @($data.gateways | Where-Object { "$($_.url)".TrimEnd('/') -eq $url })[0]
}

# Device ID the tray app created for a connection, or $null before its first connect
function Get-TrayDeviceId($gateway) {
    $keyFile = "$trayData\gateways\$($gateway.identityDirName)\device-key-ed25519.json"
    if (Test-Path $keyFile) { (Get-Content $keyFile -Raw | ConvertFrom-Json).DeviceId }
}

# True when the device is paired with the operator and node roles and its node is approved
function Test-Paired($deviceId) {
    if (-not $deviceId) { return $false }
    $device = @((Get-RemoteJson devices list).paired | Where-Object deviceId -eq $deviceId)[0]
    $node = @((Get-RemoteJson nodes list).paired | Where-Object nodeId -eq $deviceId)[0]
    $device -and $device.roles -contains 'operator' -and $device.roles -contains 'node' -and $node
}

$installed = Test-Path $trayExe
$data = if (Test-Path $gatewaysFile) { Get-Content $gatewaysFile -Raw | ConvertFrom-Json } else { $null }
$gateway = if ($data) { Get-RemoteGateway $data } else { $null }
if ($installed -and $gateway -and $data.activeId -eq $gateway.id -and $gateway.sharedGatewayToken -eq $token -and
    (Test-Paired (Get-TrayDeviceId $gateway))) {
    Write-Host "OpenClaw Companion is already installed and paired with $url, skipped"
    $global:SetupStepSkipped = $true
    return
}

# 1. Check ssh access to the Gateway host first, so the app is not changed when approval cannot work
Write-Host "[1/4] Checking ssh access to the Gateway host ($sshTarget)"
Get-RemoteJson devices list | Out-Null

# 2. Install the tray app
if (-not $installed) {
    $winget = "$env:LOCALAPPDATA\Microsoft\WindowsApps\winget.exe"
    if (-not (Test-Path $winget)) { $winget = (Get-Command winget -ErrorAction SilentlyContinue).Source }
    if (-not $winget) { throw 'winget not found. Run setup-winget.ps1 first' }
    Write-Host "[2/4] Installing OpenClaw Companion ($packageId)"
    & $winget install --id $packageId --exact -s winget --silent --accept-package-agreements --accept-source-agreements
    # -1978335189 (0x8A15002B): already installed / no newer version, treated as success
    if ($LASTEXITCODE -notin 0, -1978335189) { throw "OpenClaw Companion setup failed: exit code $LASTEXITCODE" }
    if (-not (Test-Path $trayExe)) { throw "OpenClaw Companion not found after install: $trayExe" }
}

# 3. Write the remote connection (the app rewrites gateways.json, so it is stopped first)
Write-Host "[3/4] Connecting OpenClaw Companion to $url"
Get-Process $trayProcess -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 2
if (-not $data) {
    New-Item -ItemType Directory -Force $trayData | Out-Null
    $data = [pscustomobject]@{ gateways = @(); activeId = $null }
}
if (-not $gateway) {
    # Same fields the app writes when a gateway is added in its UI
    $id = [guid]::NewGuid().ToString()
    $gateway = [pscustomobject][ordered]@{
        id = $id; url = $url; friendlyName = $null; sharedGatewayToken = $token; bootstrapToken = $null
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

# 4. Approve the app's own pairing requests on the Gateway host: operator (device) first, then node
Write-Host "[4/4] Approving the pairing requests of OpenClaw Companion on $sshTarget (waiting up to $waitSeconds s)"
$deadline = (Get-Date).AddSeconds($waitSeconds)
$deviceId = $null
while (-not ($deviceId = Get-TrayDeviceId $gateway) -and (Get-Date) -lt $deadline) { Start-Sleep -Seconds 2 }
if (-not $deviceId) { throw "OpenClaw Companion did not create a device key for $url. Open the app and check the connection" }

$approved = @()
while (-not (Test-Paired $deviceId) -and (Get-Date) -lt $deadline) {
    foreach ($request in @((Get-RemoteJson devices list).pending | Where-Object deviceId -eq $deviceId)) {
        Invoke-RemoteOpenClaw devices approve $request.requestId | Out-Null
        $approved += "device $($request.requestId)"
    }
    foreach ($request in @((Get-RemoteJson nodes list).pending | Where-Object nodeId -eq $deviceId)) {
        Invoke-RemoteOpenClaw nodes approve $request.requestId | Out-Null
        $approved += "node $($request.requestId)"
    }
    Start-Sleep -Seconds 3
}
if (-not (Test-Paired $deviceId)) {
    throw "OpenClaw Companion was not paired within $waitSeconds s (approved: $($approved -join ', ')). Run this step again"
}
Write-Host "OpenClaw Companion paired with $url (device $deviceId)"
