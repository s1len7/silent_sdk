<#
.SYNOPSIS
    titan-s260 전체 Setup. 각 설정 스크립트를 순서대로 실행한다.

.DESCRIPTION
    새 설정 단계를 추가하려면 $steps 에 스크립트를 추가한다.
#>

$ErrorActionPreference = 'Stop'

# 관리자 권한 확인 → 없으면 관리자 권한으로 재실행
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`"")
    exit
}

$steps = @(
    @{ Name = 'Windows 10 IoT 인증'; Script = 'activate-win10-iot.ps1'; Args = @{ NoPause = $true } }
)

$failed = @()
foreach ($step in $steps) {
    Write-Host ''
    Write-Host "=== $($step.Name) ===" -ForegroundColor Cyan
    $stepArgs = $step.Args
    & (Join-Path $PSScriptRoot $step.Script) @stepArgs
    if ($LASTEXITCODE -ne 0) { $failed += $step.Name }
}

Write-Host ''
if ($failed) {
    Write-Host "실패한 단계: $($failed -join ', ')" -ForegroundColor Red
} else {
    Write-Host '전체 Setup 완료' -ForegroundColor Green
}
Read-Host '엔터를 누르면 종료합니다'
