# Enable Remote Desktop (RDP, TCP/UDP 3389) with Network Level Authentication and open the firewall. Run as admin.
# Windows Home editions cannot host RDP, so this step is skipped there.

$ErrorActionPreference = 'Stop'

$edition = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').EditionID
if ($edition -like 'Core*') {
    Write-Warning "Remote Desktop host is not supported on Windows Home ($edition), skipped"
    return
}

$ts = 'HKLM:\System\CurrentControlSet\Control\Terminal Server'
Set-ItemProperty $ts fDenyTSConnections 0 -Type DWord
Set-ItemProperty "$ts\WinStations\RDP-Tcp" UserAuthentication 1 -Type DWord

# Built-in "Remote Desktop" rule group; the resource ID works on any display language
Enable-NetFirewallRule -Group '@FirewallAPI.dll,-28752'
Write-Host 'Remote Desktop enabled (port 3389)'
