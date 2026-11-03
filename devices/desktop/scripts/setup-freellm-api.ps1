# Setup FreeLLM API (self-hosted unified LLM proxy) on desktop.
# Requires Docker Desktop (setup-docker.ps1). Run as admin.
# Compose files live in this repository: devices/desktop/docker.
# This step installs and starts the container. Provider keys and the unified
# API key are configured later in the dashboard; their values are never printed.

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$composeDir = Join-Path $repoRoot 'devices\desktop\docker\freellmapi'
$composeFile = Join-Path $composeDir 'docker-compose.yml'
$envPath = Join-Path $composeDir '.env'

if (-not (Test-Path $composeFile)) {
    throw "FreeLLM API compose file not found: $composeFile"
}

# --- Docker ---------------------------------------------------------------
$dockerCmd = Get-Command docker -ErrorAction SilentlyContinue
if (-not $dockerCmd) {
    $dockerExe = "$env:ProgramFiles\Docker\Docker\resources\bin\docker.exe"
    if (Test-Path $dockerExe) { $dockerCmd = $dockerExe } else {
        Write-Host "Docker is not installed, skipped. Run setup-docker first."
        $global:SetupStepSkipped = $true
        return
    }
}

$docker = if ($dockerCmd -is [string]) { $dockerCmd } else { $dockerCmd.Source }

$daemonOk = $false
try { & $docker info *> $null; if ($LASTEXITCODE -eq 0) { $daemonOk = $true } } catch { }
if (-not $daemonOk) {
    $desktopExe = "$env:ProgramFiles\Docker\Docker\Docker Desktop.exe"
    if (Test-Path $desktopExe) {
        Write-Host "Docker daemon is not running, starting Docker Desktop..."
        Start-Process $desktopExe -WindowStyle Hidden | Out-Null
        for ($i = 0; $i -lt 30; $i++) {
            Start-Sleep -Seconds 2
            try { & $docker info *> $null; if ($LASTEXITCODE -eq 0) { $daemonOk = $true; break } } catch { }
        }
    }
}
if (-not $daemonOk) {
    Write-Host "Docker daemon is not available, skipped."
    $global:SetupStepSkipped = $true
    return
}

# --- Helpers -------------------------------------------------------------
function Get-EnvValue {
    param([string]$Path, [string]$Name)
    if (-not (Test-Path $Path)) { return $null }
    foreach ($line in (Get-Content $Path)) {
        if ($line -match "^\s*$([regex]::Escape($Name))\s*=\s*(.*)$") {
            return $Matches[1].Trim().Trim('"', "'")
        }
    }
    return $null
}

function Test-FreellmApi {
    param([int]$Port)
    try {
        $r = Invoke-WebRequest -Uri "http://localhost:$Port/api/ping" -UseBasicParsing -TimeoutSec 5
        return ($r.StatusCode -eq 200)
    } catch {
        return $false
    }
}

# --- Already running? -----------------------------------------------------
$port = 3001
$parsedPort = Get-EnvValue -Path $envPath -Name "PORT"
if ($parsedPort) { try { $port = [int]$parsedPort } catch { $port = 3001 } }

if ((Test-Path $envPath) -and (Test-FreellmApi -Port $port)) {
    Write-Host "FreeLLM API is already running on http://localhost:$port, skipped"
    $global:SetupStepSkipped = $true
    return
}

# --- .env (encryption key) ----------------------------------------------
if (-not (Test-Path $envPath)) {
    $bytes = New-Object byte[] 32
    [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
    $key = -join ($bytes | ForEach-Object { "{0:x2}" -f $_ })
    "ENCRYPTION_KEY=$key" | Set-Content -Path $envPath -Encoding ASCII
    "PORT=3001" | Add-Content -Path $envPath -Encoding ASCII
    "HOST_BIND=127.0.0.1" | Add-Content -Path $envPath -Encoding ASCII
    "" | Add-Content -Path $envPath -Encoding ASCII
    "# Optional unified key reference for local tooling. FreeLLM API does not read this." | Add-Content -Path $envPath -Encoding ASCII
    "# FREELLMAPI_API_KEY=freellmapi-..." | Add-Content -Path $envPath -Encoding ASCII
    Write-Host "Generated ENCRYPTION_KEY in $envPath"
} else {
    $existingKey = Get-EnvValue -Path $envPath -Name "ENCRYPTION_KEY"
    if (-not $existingKey) {
        $bytes = New-Object byte[] 32
        [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
        $key = -join ($bytes | ForEach-Object { "{0:x2}" -f $_ })
        "ENCRYPTION_KEY=$key" | Add-Content -Path $envPath -Encoding ASCII
        Write-Host "Generated missing ENCRYPTION_KEY in $envPath"
    }
    $existingPort = Get-EnvValue -Path $envPath -Name "PORT"
    if (-not $existingPort) {
        "PORT=3001" | Add-Content -Path $envPath -Encoding ASCII
    }
    $existingBind = Get-EnvValue -Path $envPath -Name "HOST_BIND"
    if (-not $existingBind) {
        "HOST_BIND=127.0.0.1" | Add-Content -Path $envPath -Encoding ASCII
    }
    if (-not (Get-EnvValue -Path $envPath -Name "FREELLMAPI_API_KEY")) {
        "" | Add-Content -Path $envPath -Encoding ASCII
        "# Optional unified key reference for local tooling. FreeLLM API does not read this." | Add-Content -Path $envPath -Encoding ASCII
        "# FREELLMAPI_API_KEY=freellmapi-..." | Add-Content -Path $envPath -Encoding ASCII
    }
}

$parsedPort = Get-EnvValue -Path $envPath -Name "PORT"
if ($parsedPort) { try { $port = [int]$parsedPort } catch { $port = 3001 } }

# --- Start container ------------------------------------------------------
Push-Location $composeDir
try {
    & $docker compose up -d
    if ($LASTEXITCODE -ne 0) { throw "docker compose up -d failed: exit code $LASTEXITCODE" }
} finally {
    Pop-Location
}

# --- Wait for dashboard ---------------------------------------------------
$ready = $false
for ($i = 0; $i -lt 30; $i++) {
    if (Test-FreellmApi -Port $port) { $ready = $true; break }
    Start-Sleep -Seconds 2
}

if ($ready) {
    Write-Host "FreeLLM API is running on http://localhost:$port"
} else {
    Write-Warning "FreeLLM API did not become ready within 60 seconds. Check: docker logs freellmapi-freellmapi-1"
}

Write-Host "Next manual steps:"
Write-Host "  1. Open http://localhost:$port and create the first account"
Write-Host "  2. Add provider keys on the Keys page"
Write-Host "  3. Copy the unified key (freellmapi-...)"
Write-Host "  4. Set FREELLMAPI_API_KEY, then run: npx freellmapi setup-claude --url http://localhost:$port --dry-run"
