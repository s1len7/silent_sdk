<#
.SYNOPSIS
    titan-s260 bootstrap: fetch this repo and run the full setup (scripts\setup.ps1).

.DESCRIPTION
    Clones with git if available (pulls if already cloned), otherwise downloads the GitHub zip.
    Kept ASCII-only so it works both via `irm | iex` and `-File` on Windows PowerShell 5.1.
    Remote run:
        irm https://raw.githubusercontent.com/s1len7/titan-s260/main/install.ps1 | iex
#>
param(
    [string]$InstallDir = 'C:\titan-s260'
)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$repoUrl = 'https://github.com/s1len7/titan-s260'
$zipUrl  = "$repoUrl/archive/refs/heads/main.zip"

if (Get-Command git -ErrorAction SilentlyContinue) {
    if (Test-Path (Join-Path $InstallDir '.git')) {
        Write-Host "Updating existing repo: $InstallDir"
        git -C $InstallDir pull --ff-only
    } else {
        Write-Host "Cloning $repoUrl -> $InstallDir"
        git clone $repoUrl $InstallDir
    }
    if ($LASTEXITCODE -ne 0) { throw 'git command failed.' }
} else {
    Write-Host "git not found, downloading zip: $zipUrl"
    $tmp = Join-Path $env:TEMP "titan-s260-$([guid]::NewGuid())"
    New-Item -ItemType Directory -Path $tmp | Out-Null
    $zip = Join-Path $tmp 'repo.zip'
    Invoke-WebRequest -Uri $zipUrl -OutFile $zip -UseBasicParsing
    Expand-Archive -Path $zip -DestinationPath $tmp
    New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
    Copy-Item -Path (Join-Path $tmp 'titan-s260-main\*') -Destination $InstallDir -Recurse -Force
    Remove-Item -Recurse -Force $tmp
}

$setup = Join-Path $InstallDir 'scripts\setup.ps1'
Write-Host "Running full setup: $setup"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File $setup
