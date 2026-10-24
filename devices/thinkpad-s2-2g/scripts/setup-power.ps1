# Laptop power settings for when it runs plugged in (AC): closing the lid does nothing,
# and it never sleeps or hibernates. Battery (DC) settings keep the Windows defaults. Run as admin.

$ErrorActionPreference = 'Stop'

# Power setting GUIDs (powercfg /aliases); the lid setting is listed only on devices with a lid
$settings = @(
    @{ Name = 'Lid close action'; Sub = '4f971e89-eebd-4455-a8de-9e59040e7347'; Setting = '5ca83367-6e45-459f-a27b-476b1d01c936'; Value = 0 }  # SUB_BUTTONS LIDACTION, 0 = do nothing
    @{ Name = 'Sleep after';      Sub = '238c9fa8-0aad-41ed-83f4-97be242c8f20'; Setting = '29f6c1db-86da-48c5-9fdb-f2b67b1f44da'; Value = 0 }  # SUB_SLEEP STANDBYIDLE, 0 = never
    @{ Name = 'Hibernate after';  Sub = '238c9fa8-0aad-41ed-83f4-97be242c8f20'; Setting = '9d7815a6-7ee4-497e-8888-515a05f02364'; Value = 0 }  # SUB_SLEEP HIBERNATEIDLE, 0 = never
)

# Current AC value of a setting in the active plan.
# powercfg /q labels are localized, but the last two hex values are always the AC and DC indexes.
function Get-AcValue($s) {
    $hex = @(powercfg /q SCHEME_CURRENT $s.Sub $s.Setting | Select-String '0x([0-9a-fA-F]{8})\s*$' |
        ForEach-Object { $_.Matches[0].Groups[1].Value })
    if ($LASTEXITCODE -ne 0 -or $hex.Count -lt 2) { throw "Power setting not found: $($s.Name)" }
    [Convert]::ToInt64($hex[-2], 16)
}

$missing = @($settings | Where-Object { (Get-AcValue $_) -ne $_.Value })
if (-not $missing) {
    Write-Host 'Power settings are already applied, skipped'
    $global:SetupStepSkipped = $true
    return
}

foreach ($s in $missing) {
    powercfg /setacvalueindex SCHEME_CURRENT $s.Sub $s.Setting $s.Value
    if ($LASTEXITCODE -ne 0) { throw "powercfg failed for $($s.Name): exit code $LASTEXITCODE" }
    Write-Host "$($s.Name) on AC set to $($s.Value)"
}
# Re-apply the active plan so the new values take effect now
powercfg /setactive SCHEME_CURRENT
if ($LASTEXITCODE -ne 0) { throw "powercfg /setactive failed: exit code $LASTEXITCODE" }
Write-Host 'Power settings applied'
