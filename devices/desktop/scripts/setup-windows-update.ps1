# Install all available Windows updates, including drivers, with the built-in Windows Update API. Run as admin.
# Feature upgrades (new Windows versions) and updates that need user input are left out.
# Does not reboot: when a reboot is required, reboot and run the setup again (installed updates are skipped).
#
# Progress: a background runspace searches, downloads and installs the updates one by one, so all
# Windows Update COM objects stay on that one thread. This thread only reports: a progress bar,
# "[i/N]" lines and a heartbeat line every minute (also written to the setup log).

$ErrorActionPreference = 'Stop'

$heartbeatSeconds = 60

if ((New-Object -ComObject Microsoft.Update.SystemInfo).RebootRequired) {
    Write-Warning 'A reboot is pending from earlier updates. Reboot, then run the setup again to continue updating.'
    $global:SetupStepSkipped = $true
    return
}

# Shared with the worker; Messages is drained and printed by this thread
$state = [hashtable]::Synchronized(@{
    Phase    = 'Searching'
    Index    = 0
    Total    = 0
    Title    = ''
    Messages = [System.Collections.ArrayList]::Synchronized((New-Object System.Collections.ArrayList))
    Failed   = 0
    Reboot   = $false
    UpToDate = $false
})

$worker = {
    param($state)
    $ErrorActionPreference = 'Stop'

    # Windows Update classification ID of feature upgrades
    $upgradesCategory = '3689bdc8-b205-4af4-8d4a-a63924c5e9d5'
    # Per update result codes: 2 succeeded, 3 succeeded with errors, 4 failed, 5 aborted
    $resultNames = @{ 0 = 'NotStarted'; 1 = 'InProgress'; 2 = 'Succeeded'; 3 = 'SucceededWithErrors'; 4 = 'Failed'; 5 = 'Aborted' }

    $session = New-Object -ComObject Microsoft.Update.Session
    $session.ClientApplicationID = 'silent_sdk'
    $search = $session.CreateUpdateSearcher().Search('IsInstalled=0 and IsHidden=0')

    $updates = @()
    foreach ($u in $search.Updates) {
        $isUpgrade = @($u.Categories | Where-Object CategoryID -eq $upgradesCategory).Count -gt 0
        if ($isUpgrade -or $u.InstallationBehavior.CanRequestUserInput) {
            [void]$state.Messages.Add("Left out: $($u.Title)")
            continue
        }
        if (-not $u.EulaAccepted) { $u.AcceptEula() }
        $updates += $u
    }
    $state.Total = $updates.Count
    if (-not $updates) {
        $state.UpToDate = $true
        return
    }
    [void]$state.Messages.Add("Found $($updates.Count) updates:")
    foreach ($u in $updates) { [void]$state.Messages.Add("  $($u.Title)") }

    # One update per call, so progress can be reported per update
    foreach ($phase in 'Downloading', 'Installing') {
        $state.Phase = $phase
        for ($i = 0; $i -lt $updates.Count; $i++) {
            $u = $updates[$i]
            $state.Index = $i + 1
            $state.Title = $u.Title
            if ($phase -eq 'Downloading' -and $u.IsDownloaded) { continue }

            $one = New-Object -ComObject Microsoft.Update.UpdateColl
            [void]$one.Add($u)
            $started = Get-Date
            if ($phase -eq 'Downloading') {
                $job = $session.CreateUpdateDownloader()
                $job.Updates = $one
                $code = $job.Download().ResultCode
            } else {
                $job = $session.CreateUpdateInstaller()
                $job.Updates = $one
                $result = $job.Install()
                $code = $result.ResultCode
                if ($result.RebootRequired) { $state.Reboot = $true }
                if ($code -notin 2, 3) { $state.Failed++ }
            }
            $took = ((Get-Date) - $started).ToString('mm\:ss')
            [void]$state.Messages.Add("[$($i + 1)/$($updates.Count)] $phase $($resultNames[[int]$code]) ($took): $($u.Title)")
        }
    }
}

$ps = [powershell]::Create().AddScript($worker).AddArgument($state)
$handle = $ps.BeginInvoke()
$start = Get-Date
$lastBeat = $start
Write-Host 'Searching for updates (software and drivers)...'

# Report until the worker finishes
function Write-WorkerMessages {
    while ($state.Messages.Count) {
        Write-Host $state.Messages[0]
        $state.Messages.RemoveAt(0)
    }
}
while (-not $handle.IsCompleted) {
    Start-Sleep -Seconds 2
    Write-WorkerMessages
    $elapsed = ((Get-Date) - $start).ToString('hh\:mm\:ss')
    $status = if ($state.Total) { "$($state.Phase) [$($state.Index)/$($state.Total)] $($state.Title)" } else { $state.Phase }
    $percent = 0
    if ($state.Total) {
        $offset = if ($state.Phase -eq 'Installing') { 50 } else { 0 }
        $percent = [Math]::Min(100, $offset + [int](50 * ($state.Index - 1) / $state.Total))
    }
    Write-Progress -Activity "Windows Update (elapsed $elapsed)" -Status $status -PercentComplete $percent
    if (((Get-Date) - $lastBeat).TotalSeconds -ge $heartbeatSeconds) {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] still working: $status (elapsed $elapsed)"
        $lastBeat = Get-Date
    }
}
Write-Progress -Activity 'Windows Update' -Completed

try {
    $ps.EndInvoke($handle) | Out-Null
} catch {
    # Show the worker's own error instead of the EndInvoke wrapper
    throw "Windows Update failed: $($_.Exception.GetBaseException().Message)"
} finally {
    Write-WorkerMessages
    $ps.Dispose()
}

if ($state.UpToDate) {
    Write-Host 'Windows is up to date, skipped'
    $global:SetupStepSkipped = $true
    return
}
if ($state.Reboot) {
    Write-Warning 'Reboot required to finish the updates. Reboot, then run the setup again to install any remaining updates.'
}
if ($state.Failed) { throw "$($state.Failed) of $($state.Total) updates failed to install" }
Write-Host "Windows updates installed: $($state.Total)"
