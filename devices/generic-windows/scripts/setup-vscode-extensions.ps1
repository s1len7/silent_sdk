# Install VS Code extensions for the current user (verified Microsoft publisher only). Run after setup-vscode.ps1.
# Python (ms-python.python, also pulls in Pylance and the debugger), Remote - SSH, Remote Explorer.
# Under the elevated setup the extensions still go to the same user's profile (%USERPROFILE%\.vscode\extensions).

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$extensions = @(
    'ms-python.python'
    'ms-vscode-remote.remote-ssh'
    'ms-vscode.remote-explorer'
)

# VS Code command line (system or per-user install)
$code = "$env:ProgramFiles\Microsoft VS Code\bin\code.cmd", "$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin\code.cmd" |
    Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $code) { throw 'VS Code not found. Run setup-vscode.ps1 first' }

# Run code.cmd through cmd so its stderr notices do not become PowerShell errors (Windows PowerShell 5.1)
function Invoke-Code($arguments) {
    $out = cmd /c "`"$code`" $arguments 2>&1"
    if ($LASTEXITCODE -ne 0) { throw "code $arguments failed: exit code $LASTEXITCODE`n$($out -join "`n")" }
    $out
}

$installed = @(Invoke-Code '--list-extensions')
$missing = @($extensions | Where-Object { $installed -notcontains $_ })
if (-not $missing) {
    Write-Host "VS Code extensions are already installed, skipped: $($extensions -join ', ')"
    $global:SetupStepSkipped = $true
    return
}

foreach ($extension in $missing) {
    Write-Host "Installing VS Code extension $extension"
    Invoke-Code "--install-extension $extension" | Out-Null
}

$installed = @(Invoke-Code '--list-extensions')
$failed = @($extensions | Where-Object { $installed -notcontains $_ })
if ($failed) { throw "VS Code extensions not found after install: $($failed -join ', ')" }
Write-Host "VS Code extensions setup done: $($extensions -join ', ')"
