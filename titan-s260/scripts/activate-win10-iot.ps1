<#
.SYNOPSIS
    Windows 10 IoT 정품 인증 스크립트 (titan-s260)

.DESCRIPTION
    1. 제품 키를 -ProductKey 인자로 받거나, 없으면 펌웨어(BIOS/UEFI)에 내장된 OEM 키(OA3)를 읽는다.
    2. slmgr 로 키를 설치하고 온라인 인증을 시도한다.
    3. 인증 결과를 출력한다.

.EXAMPLE
    .\activate-win10-iot.ps1
    .\activate-win10-iot.ps1 -ProductKey XXXXX-XXXXX-XXXXX-XXXXX-XXXXX
#>
param(
    [string]$ProductKey,
    [switch]$NoPause  # 전체 Setup 에서 호출할 때 종료 대기 생략
)

$ErrorActionPreference = 'Stop'

function Wait-Exit {
    if (-not $NoPause) { Read-Host '엔터를 누르면 종료합니다' | Out-Null }
}

# 관리자 권한 확인 → 없으면 관리자 권한으로 재실행
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $argList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`"")
    if ($ProductKey) { $argList += @('-ProductKey', $ProductKey) }
    Start-Process powershell.exe -Verb RunAs -ArgumentList $argList
    exit
}

$slmgr = "$env:SystemRoot\System32\slmgr.vbs"

function Get-ActivationStatus {
    Get-CimInstance SoftwareLicensingProduct -Filter "ApplicationID='55c92734-d682-4d71-983e-d6ec3f16059f' AND PartialProductKey IS NOT NULL" |
        Select-Object -First 1 Name, Description, PartialProductKey, LicenseStatus
}

$os = Get-CimInstance Win32_OperatingSystem
Write-Host "OS: $($os.Caption) ($($os.Version))"

$status = Get-ActivationStatus
if ($status -and $status.LicenseStatus -eq 1) {
    Write-Host "이미 인증되어 있습니다. ($($status.Name), 키 끝자리 $($status.PartialProductKey))" -ForegroundColor Green
    Wait-Exit
    exit 0
}

if (-not $ProductKey) {
    $ProductKey = (Get-CimInstance SoftwareLicensingService).OA3xOriginalProductKey
    if ($ProductKey) {
        Write-Host '펌웨어에 내장된 OEM 제품 키를 찾았습니다.'
    } else {
        $ProductKey = Read-Host '펌웨어에 내장된 키가 없습니다. 제품 키를 입력하세요 (XXXXX-XXXXX-XXXXX-XXXXX-XXXXX)'
    }
}

if ($ProductKey -notmatch '^[A-Z0-9]{5}(-[A-Z0-9]{5}){4}$') {
    Write-Host "제품 키 형식이 올바르지 않습니다: $ProductKey" -ForegroundColor Red
    Wait-Exit
    exit 1
}

Write-Host '제품 키 설치 중...'
cscript.exe //nologo $slmgr /ipk $ProductKey

Write-Host '온라인 인증 중...'
cscript.exe //nologo $slmgr /ato

$status = Get-ActivationStatus
if ($status -and $status.LicenseStatus -eq 1) {
    Write-Host "인증 완료 ($($status.Name))" -ForegroundColor Green
    $code = 0
} else {
    Write-Host '인증에 실패했습니다. 인터넷 연결과 제품 키를 확인하세요. 상세: slmgr /dlv' -ForegroundColor Red
    $code = 1
}

Wait-Exit
exit $code
