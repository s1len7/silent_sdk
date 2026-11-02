# Install Cursor extensions for the current user. Run after setup-cursor.ps1.
# Python (ms-python.python, also pulls in Pylance and the debugger).
# Remote - SSH and Remote Explorer are not included: Cursor ships its own remote support,
# so the VS Code remote extensions are not known to work here.
# Under the elevated setup the extensions still go to the same user's profile (%USERPROFILE%\.cursor\extensions).

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$extensions = @(
    'ms-python.python'
)

# Cursor command line (per-user install)
$cursor = "$env:LOCALAPPDATA\Programs\cursor\resources\app\bin\cursor.cmd"
if (-not (Test-Path $cursor)) { throw 'Cursor not found. Run setup-cursor.ps1 first' }

# Run cursor.cmd through cmd so its stderr notices do not become PowerShell errors (Windows PowerShell 5.1)
function Invoke-Cursor($arguments) {
    $out = cmd /c "`"$cursor`" $arguments 2>&1"
    if ($LASTEXITCODE -ne 0) { throw "cursor $arguments failed: exit code $LASTEXITCODE`n$($out -join "`n")" }
    $out
}

$installed = @(Invoke-Cursor '--list-extensions')
$missing = @($extensions | Where-Object { $installed -notcontains $_ })
if (-not $missing) {
    Write-Host "Cursor extensions are already installed, skipped: $($extensions -join ', ')"
    $global:SetupStepSkipped = $true
    return
}

foreach ($extension in $missing) {
    Write-Host "Installing Cursor extension $extension"
    Invoke-Cursor "--install-extension $extension" | Out-Null
}

$installed = @(Invoke-Cursor '--list-extensions')
$failed = @($extensions | Where-Object { $installed -notcontains $_ })
if ($failed) { throw "Cursor extensions not found after install: $($failed -join ', ')" }
Write-Host "Cursor extensions setup done: $($extensions -join ', ')"
