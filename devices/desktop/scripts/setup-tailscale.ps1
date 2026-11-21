# Connect Tailscale (Windows app) to the tailnet using a one-off auth key from Vaultwarden.
# Run as admin, after the Bitwarden CLI step (setup-bitwarden-cli.ps1) configures bw.
# The auth key is read from the "Tailscale Auth Key" Vaultwarden item and never stored.
# Installs Tailscale via winget when it is missing.
# Docs: https://tailscale.com/kb/

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$logDir = if ($env:SILENT_SDK_LOG_DIR) { $env:SILENT_SDK_LOG_DIR } else { $env:TEMP }
New-Item -ItemType Directory -Force $logDir | Out-Null

$deviceDir = Split-Path $PSScriptRoot
$envFile = Join-Path $deviceDir '.env'
$envExample = Join-Path $deviceDir '.env.example'
$placeholder = 'https://<vaultwarden-example>.duckdns.org'

# Possible locations of the Tailscale CLI on Windows
$candidatePaths = @(
    "$env:ProgramFiles\Tailscale\tailscale.exe",
    "$(${env:'ProgramFiles(x86)'})\Tailscale\tailscale.exe",
    "$env:LOCALAPPDATA\Programs\Tailscale\tailscale.exe"
)
$tailscaleExe = $null
foreach ($p in $candidatePaths) { if (Test-Path $p) { $tailscaleExe = $p; break } }

# Install Tailscale via winget when it is missing (winget is prepared by the WinGet step)
if (-not $tailscaleExe) {
    Write-Host 'Tailscale is not installed. Installing via winget (tailscale.tailscale)'
    $winget = (Get-Command winget.exe -ErrorAction SilentlyContinue).Source
    if (-not $winget) { throw 'winget not found. Run scripts/setup-winget.ps1 first' }
    $installLog = Join-Path $logDir 'tailscale-install.log'
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        & $winget install --id tailscale.tailscale --source winget --accept-package-agreements --accept-source-agreements --log $installLog 2>&1 | Tee-Object -FilePath $installLog
    } finally {
        $ErrorActionPreference = $previous
    }
    if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne 3010) {
        throw "winget install tailscale.tailscale failed: exit code $LASTEXITCODE (log: $installLog)"
    }
    foreach ($p in $candidatePaths) { if (Test-Path $p) { $tailscaleExe = $p; break } }
}
if (-not $tailscaleExe) { throw 'tailscale.exe not found after install' }

# Already connected?
$statusRaw = & $tailscaleExe status --json 2>$null
if ($LASTEXITCODE -eq 0) {
    $parsed = $statusRaw | ConvertFrom-Json -ErrorAction SilentlyContinue
    if ($parsed -and $parsed.BackendState -eq 'Running') {
        Write-Host 'Tailscale is already connected, skipped'
        $global:SetupStepSkipped = $true
        return
    }
}

# Login requires an interactive terminal (the user may need to confirm in the Tailscale app)
if ([Console]::IsInputRedirected -or [Console]::IsOutputRedirected) {
    Write-Host 'Tailscale login requires an interactive terminal.'
    $global:SetupStepSkipped = $true
    return
}

# Bitwarden CLI required to fetch the one-off auth key
function Get-BwPath {
    foreach ($name in 'bw.cmd', 'bw.exe', 'bw') {
        $command = Get-Command $name -ErrorAction SilentlyContinue
        if ($command) { return $command.Source }
    }
    return $null
}
$bwPath = Get-BwPath
if (-not $bwPath) {
    Write-Host 'Bitwarden CLI is not installed. Run setup-bitwarden-cli.ps1 first.'
    $global:SetupStepSkipped = $true
    return
}

function Get-LastLine([string]$Text) {
    $lines = @($Text -split "`n" | Where-Object { $_.Trim() })
    if ($lines.Count) { return $lines[-1].Trim() }
    return ''
}

# Read VAULTWARDEN_URL from .env (create it from the example on first run)
if (-not (Test-Path $envFile)) {
    Copy-Item $envExample $envFile
    Write-Host "Created $envFile. Replace the example VAULTWARDEN_URL, then run this step again."
    $global:SetupStepSkipped = $true
    return
}
$values = @{}
foreach ($line in Get-Content $envFile) {
    if ($line -match '^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*?)\s*$') {
        $values[$Matches[1]] = $Matches[2].Trim('"', "'")
    }
}
$serverUrl = $values['VAULTWARDEN_URL']
if (-not $serverUrl) {
    Write-Host "VAULTWARDEN_URL is empty in $envFile. Add the Vaultwarden URL and run this step again."
    $global:SetupStepSkipped = $true
    return
}
if ($serverUrl -eq $placeholder) {
    Write-Host "Replace the example VAULTWARDEN_URL in $envFile before connecting Tailscale."
    $global:SetupStepSkipped = $true
    return
}
if ($serverUrl -notmatch '^https://') { throw 'VAULTWARDEN_URL must use HTTPS' }
$serverUrl = $serverUrl.TrimEnd('/')

# Configure the Bitwarden CLI server when needed
$current = & $bwPath config server 2>$null
if ((Get-LastLine $current) -ne $serverUrl) {
    Write-Host 'Configuring the Bitwarden CLI server'
    $set = & $bwPath config server $serverUrl 2>$null
    if ($LASTEXITCODE -ne 0) { throw "bw config server failed: exit code $LASTEXITCODE" }
    $current = & $bwPath config server 2>$null
    if ((Get-LastLine $current) -ne $serverUrl) {
        throw 'Bitwarden CLI server configuration did not match VAULTWARDEN_URL'
    }
}

# Unlock Vaultwarden interactively (master password is never stored)
$bwSession = $null
$statusRaw = & $bwPath status 2>$null
$bwState = ''
if ($statusRaw -match '"status"\s*:\s*"([^"]+)"') { $bwState = $Matches[1] }

if ($bwState -eq 'locked') {
    $password = Read-Host -AsSecureString 'Bitwarden master password'
    if (-not $password) {
        Write-Host 'Bitwarden master password was not entered.'
        $global:SetupStepSkipped = $true
        return
    }
    $passwordText = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR([Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))
    $env:BW_PASSWORD = $passwordText
    try {
        $bwSession = & $bwPath unlock --passwordenv BW_PASSWORD --raw 2>$null
    } finally {
        $env:BW_PASSWORD = ''
    }
    if ($LASTEXITCODE -ne 0 -or -not $bwSession) {
        Write-Host 'Failed to unlock the Vaultwarden account.' -ForegroundColor Red
        $global:SetupStepSkipped = $true
        return
    }
} elseif ($bwState -eq 'unauthenticated') {
    Write-Host 'Bitwarden is not authenticated. Run "bw login" first, then run this step again.'
    $global:SetupStepSkipped = $true
    return
}

# Read the one-off Tailscale Auth Key from Vaultwarden (session key is in-memory only)
if ($bwSession) { $env:BW_SESSION = $bwSession }
try {
    $authKey = & $bwPath get password 'Tailscale Auth Key' --raw 2>$null
} finally {
    $env:BW_SESSION = ''
}
if ($LASTEXITCODE -ne 0 -or -not $authKey) {
    Write-Host 'Could not read the Tailscale Auth Key item from Vaultwarden.' -ForegroundColor Red
    $global:SetupStepSkipped = $true
    return
}
$authKey = $authKey.Trim()
if (-not $authKey) {
    Write-Host 'The Tailscale Auth Key item is empty in Vaultwarden.' -ForegroundColor Red
    $global:SetupStepSkipped = $true
    return
}

# Write the key to a temp file readable only by the current user, then log in with file:
# so the key never appears on the command line
$authKeyFile = Join-Path $env:TEMP ("tailscale-auth-key-" + [guid]::NewGuid().ToString('N') + '.txt')
try {
    [System.IO.File]::WriteAllBytes($authKeyFile, [System.Text.Encoding]::UTF8.GetBytes($authKey))
    $acl = New-Object System.Security.AccessControl.FileSecurity
    $acl.SetAccessRuleProtection($true, $false)
    $user = [Security.Principal.WindowsIdentity]::GetCurrent()
    $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule($user, 'Read,Write', 'Allow')))
    (Get-Item $authKeyFile).SetAccessControl($acl)

    Write-Host 'Connecting Tailscale with the one-off key from Vaultwarden'
    & $tailscaleExe "up" "--authkey=file:$authKeyFile" >$null 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host 'Tailscale login failed. Check the Tailscale app and one-off key.' -ForegroundColor Red
        throw 'Tailscale login failed'
    }
    $statusRaw = & $tailscaleExe status --json 2>$null
    $parsed = $statusRaw | ConvertFrom-Json -ErrorAction SilentlyContinue
    if (-not $parsed -or $parsed.BackendState -ne 'Running') {
        Write-Host 'Tailscale is not connected after login.' -ForegroundColor Red
        throw 'Tailscale is not connected after login'
    }
    Write-Host 'Tailscale is connected. The temporary auth key file will be removed.'
} finally {
    $authKey = ''
    if ($authKeyFile -and (Test-Path $authKeyFile)) { Remove-Item $authKeyFile -Force }
}
