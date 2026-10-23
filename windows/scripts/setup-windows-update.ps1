# Install all available Windows updates, including drivers, with the built-in Windows Update API. Run as admin.
# Feature upgrades (new Windows versions) and updates that need user input are left out.
# Does not reboot: when a reboot is required, reboot and run the setup again (installed updates are skipped).

$ErrorActionPreference = 'Stop'

# Windows Update classification ID of feature upgrades
$upgradesCategory = '3689bdc8-b205-4af4-8d4a-a63924c5e9d5'

if ((New-Object -ComObject Microsoft.Update.SystemInfo).RebootRequired) {
    Write-Warning 'A reboot is pending from earlier updates. Reboot, then run the setup again to continue updating.'
    $global:SetupStepSkipped = $true
    return
}

$session = New-Object -ComObject Microsoft.Update.Session
$session.ClientApplicationID = 'silent_sdk'

Write-Host 'Searching for updates (software and drivers)...'
$search = $session.CreateUpdateSearcher().Search('IsInstalled=0 and IsHidden=0')

$updates = New-Object -ComObject Microsoft.Update.UpdateColl
foreach ($u in $search.Updates) {
    $isUpgrade = @($u.Categories | Where-Object CategoryID -eq $upgradesCategory).Count -gt 0
    if ($isUpgrade -or $u.InstallationBehavior.CanRequestUserInput) {
        Write-Host "Left out: $($u.Title)"
        continue
    }
    if (-not $u.EulaAccepted) { $u.AcceptEula() }
    [void]$updates.Add($u)
}

if ($updates.Count -eq 0) {
    Write-Host 'Windows is up to date, skipped'
    $global:SetupStepSkipped = $true
    return
}

Write-Host "Found $($updates.Count) updates:"
foreach ($u in $updates) { Write-Host "  $($u.Title)" }

Write-Host 'Downloading...'
$downloader = $session.CreateUpdateDownloader()
$downloader.Updates = $updates
[void]$downloader.Download()

Write-Host 'Installing...'
$installer = $session.CreateUpdateInstaller()
$installer.Updates = $updates
$result = $installer.Install()

# Per update result: 2 succeeded, 3 succeeded with errors, 4 failed, 5 aborted
$resultNames = @{ 0 = 'NotStarted'; 1 = 'InProgress'; 2 = 'Succeeded'; 3 = 'SucceededWithErrors'; 4 = 'Failed'; 5 = 'Aborted' }
$failed = 0
for ($i = 0; $i -lt $updates.Count; $i++) {
    $r = $installer.Updates.Item($i)
    $code = $result.GetUpdateResult($i).ResultCode
    $hresult = '0x{0:X8}' -f $result.GetUpdateResult($i).HResult
    if ($code -notin 2, 3) { $failed++ }
    Write-Host "  $($resultNames[$code]) ($hresult): $($r.Title)"
}

if ($result.RebootRequired) {
    Write-Warning 'Reboot required to finish the updates. Reboot, then run the setup again to install any remaining updates.'
}
if ($failed) { throw "$failed of $($updates.Count) updates failed to install" }
Write-Host "Windows updates installed: $($updates.Count)"
