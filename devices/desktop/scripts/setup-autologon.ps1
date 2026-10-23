# Set up automatic logon for the currently signed-in local account with Sysinternals Autologon. Run as admin.
# Needs Sysinternals Suite (setup-sysinternals.ps1) installed first.
# Autologon stores the password encrypted as an LSA secret, not as plain text in the registry.
# Asks for the password; skips when there is no console to ask or when the password is left empty.

$ErrorActionPreference = 'Stop'

$winlogon = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'

# Quote one command-line argument by the Windows rules, so quotes and backslashes in the password survive
function ConvertTo-Argument([string]$value) {
    '"' + (($value -replace '(\\*)"', '$1$1\"') -replace '(\\+)$', '$1$1') + '"'
}

# Console user (DOMAIN\user); falls back to the account running this script
$account = (Get-CimInstance Win32_ComputerSystem).UserName
if (-not $account) { $account = "$env:USERDOMAIN\$env:USERNAME" }
$domain, $user = $account -split '\\', 2

# Already enabled for this account
$current = Get-ItemProperty $winlogon -ErrorAction SilentlyContinue
if ($current.AutoAdminLogon -eq '1' -and $current.DefaultUserName -eq $user -and $current.DefaultDomainName -eq $domain) {
    Write-Host "Autologon is already enabled for $account, skipped"
    $global:SetupStepSkipped = $true
    return
}

# Only local accounts: the password check below and Autologon need the local account password
$localUser = Get-LocalUser -Name $user -ErrorAction SilentlyContinue
if ($domain -ne $env:COMPUTERNAME -or -not $localUser -or $localUser.PrincipalSource -ne 'Local') {
    Write-Warning "Autologon setup supports local accounts only: $account. Skipped."
    $global:SetupStepSkipped = $true
    return
}

if (-not [Environment]::UserInteractive) {
    Write-Warning "No console to ask for the password, autologon skipped"
    $global:SetupStepSkipped = $true
    return
}

$exe = if ([Environment]::Is64BitOperatingSystem) { 'Autologon64.exe' } else { 'Autologon.exe' }
$exe = Join-Path "$env:ProgramFiles\Sysinternals" $exe
if (-not (Test-Path $exe)) { throw "Autologon not found: $exe (run setup-sysinternals.ps1 first)" }

# Autologon does not verify the password, so check it here to avoid a failing logon at boot
Add-Type -AssemblyName System.DirectoryServices.AccountManagement
$context = New-Object System.DirectoryServices.AccountManagement.PrincipalContext('Machine')
$password = $null
for ($i = 1; $i -le 3; $i++) {
    $secure = Read-Host "Password for $account (Enter to skip autologon)" -AsSecureString
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try { $plain = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr) }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }

    if (-not $plain) {
        Write-Host "No password entered, autologon skipped"
        $context.Dispose()
        $global:SetupStepSkipped = $true
        return
    }
    if ($context.ValidateCredentials($user, $plain)) { $password = $plain; break }
    Write-Host "Wrong password ($i/3)"
}
$context.Dispose()
if (-not $password) { throw "Wrong password 3 times, autologon not set" }

# Autologon is a GUI tool: if it waits on a dialog, stop it after 30 seconds and check the registry instead
$arguments = '/accepteula', (ConvertTo-Argument $user), (ConvertTo-Argument $domain), (ConvertTo-Argument $password)
$process = Start-Process $exe -ArgumentList $arguments -PassThru
$arguments = $null
$password = $null
if (-not $process.WaitForExit(30000)) {
    $process.Kill()
    Write-Warning "Autologon did not exit within 30 seconds and was stopped"
}

$result = Get-ItemProperty $winlogon
if ($result.AutoAdminLogon -ne '1' -or $result.DefaultUserName -ne $user) {
    throw "Autologon was not enabled (AutoAdminLogon=$($result.AutoAdminLogon), DefaultUserName=$($result.DefaultUserName))"
}
Write-Host "Autologon enabled for $account (applies from the next boot; hold Shift at boot to bypass)"
