# Logging helpers for the setup entry points (devices\desktop\setup.ps1, devices\titan-s260\setup.ps1).
# Dot-source after the repo is available:
#   Start-SetupLog     move the bootstrap transcript into <repo>\logs\<platform>-<stamp>\ and write an environment header
#   Invoke-Step        run one setup step, keep going on failure, return its result (OK / SKIP / FAIL)
#                      A step reports "already set up" by setting $global:SetupStepSkipped = $true before returning
#   Write-SetupSummary print the result table

function Start-SetupLog([string]$Repo, [string]$Platform, [string]$Stamp, [string]$BootstrapLog) {
    $logDir = Join-Path $Repo "logs\$Platform-$Stamp"
    New-Item -ItemType Directory -Force $logDir | Out-Null

    # Continue the transcript started before the repo existed, now inside the repo
    $log = Join-Path $logDir 'setup.log'
    Stop-Transcript | Out-Null
    Move-Item $BootstrapLog $log -Force
    Start-Transcript -Path $log -Append | Out-Null

    # Step scripts write installer logs here (falls back to TEMP when run alone)
    $env:SILENT_SDK_LOG_DIR = $logDir

    $os = Get-CimInstance Win32_OperatingSystem
    $edition = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').EditionID
    # Full path: a session opened before Git was installed does not have it on PATH
    $git = "$env:ProgramFiles\Git\cmd\git.exe"
    $commit = 'unknown (no git)'
    if (-not (Test-Path "$Repo\.git")) {
        # Only when getting the repo failed and an older zip download is used as is
        $commit = 'not a git clone (older zip download)'
    } elseif (Test-Path $git) {
        $commit = & $git -C $Repo rev-parse --short HEAD
    }
    Write-Host "Platform:   $Platform"
    Write-Host "Hostname:   $env:COMPUTERNAME / User: $env:USERNAME"
    Write-Host "OS:         $($os.Caption) ($edition, $($os.Version))"
    $system = Get-CimInstance Win32_ComputerSystem
    $board = Get-CimInstance Win32_BaseBoard
    Write-Host "Hardware:   $($system.Manufacturer) $($system.Model) / board: $($board.Manufacturer) $($board.Product)"
    Write-Host "PowerShell: $($PSVersionTable.PSVersion)"
    Write-Host "Repo:       $Repo @ $commit"
    Write-Host "Logs:       $logDir"
    return $logDir
}

function Invoke-Step([string]$Name, [scriptblock]$Action) {
    Write-Host ''
    Write-Host "=== [$Name] started $(Get-Date -Format 'HH:mm:ss')"
    $timer = [Diagnostics.Stopwatch]::StartNew()
    $result = 'OK'
    $message = ''
    $global:SetupStepSkipped = $false
    try {
        # Route all output through the host so native tool output also lands in the transcript
        & $Action | Out-Host
        if ($global:SetupStepSkipped) { $result = 'SKIP' }
    } catch {
        $result = 'FAIL'
        $message = $_.Exception.Message
        Write-Host "ERROR: $message" -ForegroundColor Red
        Write-Host $_.ScriptStackTrace
    }
    $timer.Stop()
    $time = $timer.Elapsed.ToString('mm\:ss')
    Write-Host "=== [$Name] $result ($time)"
    [pscustomobject]@{ Step = $Name; Result = $result; Time = $time; Error = $message }
}

function Write-SetupSummary($Results, [string]$LogDir) {
    Write-Host ''
    Write-Host '=== Summary'
    $Results | Format-Table -AutoSize -Wrap | Out-String -Width 200 | Write-Host
    $failed = @($Results | Where-Object Result -eq 'FAIL').Count
    if ($failed) {
        Write-Host "$failed of $($Results.Count) steps failed. See the logs, then run the setup again (finished steps are skipped)." -ForegroundColor Red
    } else {
        Write-Host "All $($Results.Count) steps succeeded or were already set up." -ForegroundColor Green
    }
    Write-Host "Logs: $LogDir"
}
