# Enable Remote Desktop (RDP, TCP/UDP 3389) with Network Level Authentication and open the firewall. Run as admin.
# Windows Home editions cannot host RDP, so this step is skipped there.

$ErrorActionPreference = 'Stop'

$edition = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').EditionID
if ($edition -like 'Core*') {
    Write-Warning "Remote Desktop host is not supported on Windows Home ($edition), skipped"
    $global:SetupStepSkipped = $true
    return
}

$ts = 'HKLM:\System\CurrentControlSet\Control\Terminal Server'
$group = '@FirewallAPI.dll,-28752'
$done = (Get-ItemProperty $ts).fDenyTSConnections -eq 0 -and
    (Get-ItemProperty "$ts\WinStations\RDP-Tcp").UserAuthentication -eq 1 -and
    -not (Get-NetFirewallRule -Group $group | Where-Object Enabled -ne 'True')
if ($done) {
    Write-Host 'Remote Desktop is already enabled, skipped'
    $global:SetupStepSkipped = $true
    return
}

Set-ItemProperty $ts fDenyTSConnections 0 -Type DWord
Set-ItemProperty "$ts\WinStations\RDP-Tcp" UserAuthentication 1 -Type DWord

# Built-in "Remote Desktop" rule group; the resource ID works on any display language
Enable-NetFirewallRule -Group $group
Write-Host 'Remote Desktop enabled (port 3389)'
