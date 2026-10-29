# silent_sdk generic-windows setup (for borrowed PCs: per-user install, no admin needed)
#   irm https://raw.githubusercontent.com/s1len7/silent_sdk/main/devices/generic-windows/setup.ps1 | iex
# ASCII-only so it works both via `irm | iex` and `-File` on Windows PowerShell 5.1.
# Every step runs with -UserScope (no elevation); run it as the user who will use the tools.
# Cleanup: .\setup.ps1 -Cleanup [-DryRun] [-Force]

param(
    [switch]$Cleanup,
    [switch]$DryRun,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$repo = 'https://github.com/s1len7/silent_sdk'
$dir  = "$HOME\silent_sdk"

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

if ($Cleanup) {
    Write-Host "Cleanup mode: removing silent_sdk repository and related personal info" -ForegroundColor Yellow
    Write-Host "Installed programs will NOT be removed." -ForegroundColor Yellow
    Write-Host ""

    $targets = @()
    if (Test-Path $dir) {
        $targets += $dir
    }

    # Check for other silent_sdk copies in HOME
    try {
        Get-ChildItem -Path $HOME -Directory -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '^silent_sdk' -and $_.FullName -ne $dir } | ForEach-Object {
            $targets += $_.FullName
        }
    } catch {}

    # Check for .env files that might be related copies (outside repo) - be conservative
    try {
        Get-ChildItem -Path $HOME -Recurse -Force -File -ErrorAction SilentlyContinue -Filter '.env' | Where-Object { $_.FullName -notmatch '\\\.git\\' -and $_.FullName -notlike "$dir\*" } | ForEach-Object {
            $targets += $_.FullName
        }
    } catch {}

    # Bootstrap/temp logs related to this setup
    try {
        Get-ChildItem -Path $env:TEMP -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'silent_sdk.*generic-windows' } | ForEach-Object {
            $targets += $_.FullName
        }
    } catch {}

    if ($targets.Count -eq 0) {
        Write-Host "No silent_sdk related files found to clean up." -ForegroundColor Green
        exit 0
    }

    Write-Host "Targets to remove:" -ForegroundColor Cyan
    $targets | ForEach-Object { Write-Host "  $_" }
    Write-Host ""

    if ($DryRun) {
        Write-Host "DryRun: no changes made." -ForegroundColor Green
        exit 0
    }

    if (-not $Force) {
        $resp = Read-Host "Are you sure you want to delete these? This cannot be undone. (y/N)"
        if ($resp -ne 'y' -and $resp -ne 'Y') {
            Write-Host "Cancelled." -ForegroundColor Yellow
            exit 0
        }
    }

    # If we are running from inside the repo, use wrapper to self-delete
    $scriptPath = $MyInvocation.MyCommand.Definition
    if ($scriptPath -and $scriptPath -like "$dir\*") {
        $wrapper = Join-Path $env:TEMP "silent_sdk_cleanup_wrapper_$(Get-Date -Format 'yyyyMMddHHmmss').ps1"
        $targetsList = $targets | ForEach-Object { "'" + $_.Replace("'", "''") + "'" } | Join-String -Separator ','
        $wrapperContent = @"
# Cleanup wrapper
`$ErrorActionPreference = 'SilentlyContinue'
Start-Sleep -Seconds 2
$targetsList | ForEach-Object {
    `$p = [ScriptBlock]::Create(`$_).Invoke()
    if (Test-Path `$p) {
        try {
            if ((Get-Item `$p) -is [System.IO.DirectoryInfo]) {
                Remove-Item `$p -Recurse -Force -ErrorAction SilentlyContinue
            } else {
                Remove-Item `$p -Force -ErrorAction SilentlyContinue
            }
        } catch {}
    }
}
"@
        Set-Content -Path $wrapper -Value $wrapperContent -Encoding ASCII
        Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$wrapper`"" -WindowStyle Hidden
        Write-Host "Cleanup initiated. This window may close." -ForegroundColor Green
        exit 0
    }

    foreach ($t in $targets) {
        try {
            if (Test-Path $t) {
                if ((Get-Item $t) -is [System.IO.DirectoryInfo]) {
                    Remove-Item $t -Recurse -Force -ErrorAction SilentlyContinue
                } else {
                    Remove-Item $t -Force -ErrorAction SilentlyContinue
                }
                Write-Host "Removed: $t" -ForegroundColor Green
            }
        } catch {
            Write-Host "Failed to remove: $t - $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    Write-Host "Cleanup complete." -ForegroundColor Green
    exit 0
}

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$bootstrapLog = "$env:TEMP\silent_sdk-generic-windows-$stamp.log"
Start-Transcript -Path $bootstrapLog | Out-Null

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
try {
    # Per-user Git (the installer adds it to the user PATH); an existing Git of any kind is reused
    $git = @("$env:LOCALAPPDATA\Programs\Git\cmd\git.exe", "$env:ProgramFiles\Git\cmd\git.exe") |
        Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $git) {
        $gitCmd = Get-Command git -ErrorAction SilentlyContinue
        if (-not $gitCmd) {
            $gitSetup = Invoke-RestMethod 'https://raw.githubusercontent.com/s1len7/silent_sdk/main/devices/generic-windows/scripts/setup-git.ps1' -UseBasicParsing
            & ([scriptblock]::Create($gitSetup)) -UserScope | Out-Host
            $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
            $git = "$env:LOCALAPPDATA\Programs\Git\cmd\git.exe"
            if (-not (Test-Path $git)) { throw "git not found after install: $git" }
        } else {
            $git = $gitCmd.Source
        }
    }
    if (Test-Path "$dir\.git") {
        & $git -C $dir pull --ff-only | Out-Host
        if ($LASTEXITCODE -ne 0) { throw "git pull failed: exit code $LASTEXITCODE" }
    } else {
        $new = "$dir.new"
        $old = "$dir.old"
        Remove-Item $new, $old -Recurse -Force -ErrorAction SilentlyContinue
        & $git clone $repo $new | Out-Host
        if ($LASTEXITCODE -ne 0) { throw "git clone failed: exit code $LASTEXITCODE" }
        Set-Location $env:TEMP
        if (Test-Path $dir) { Rename-Item $dir (Split-Path $old -Leaf) }
        try {
            Move-Item $new $dir
        } catch {
            if (Test-Path $old) { Rename-Item $old (Split-Path $dir -Leaf) }
            throw
        }
        if (Test-Path $old) {
            if (Test-Path "$old\logs") { Copy-Item "$old\logs\*" "$dir\logs" -Recurse -Force }
            Get-ChildItem $old -Recurse -Force -File -Filter '.env' | ForEach-Object {
                $target = Join-Path $dir $_.FullName.Substring($old.Length)
                New-Item -ItemType Directory -Force (Split-Path $target) | Out-Null
                Copy-Item $_.FullName $target -Force
            }
            try { Remove-Item $old -Recurse -Force } catch { Write-Warning "Could not remove $old`: $($_.Exception.Message)" }
        }
    }
} catch {
    Write-Host "ERROR: getting the repo failed: $($_.Exception.Message)" -ForegroundColor Red
    if (-not (Test-Path "$dir\devices\generic-windows\scripts\lib-log.ps1")) {
        Stop-Transcript | Out-Null
        Read-Host "Setup aborted. Log: $bootstrapLog. Press Enter to exit"
        exit 1
    }
    Write-Warning "Continuing with the existing files in $dir"
}

. "$dir\devices\generic-windows\scripts\lib-log.ps1"
$logDir = Start-SetupLog $dir 'generic-windows' $stamp $bootstrapLog

$d = "$dir\devices\generic-windows\scripts"
$results = @()
$results += Invoke-Step 'git'      { & "$d\setup-git.ps1" }
$results += Invoke-Step 'vscode'   { & "$d\setup-vscode.ps1" }
# opencode step installs Node.js with winget, so install winget first (missing on LTSC / some Windows 10)
$results += Invoke-Step 'winget'   { & "$d\setup-winget.ps1" }
$results += Invoke-Step 'opencode' { & "$d\setup-opencode.ps1" }

Write-SetupSummary $results $logDir
Stop-Transcript | Out-Null
Read-Host 'Done. Press Enter to exit'
