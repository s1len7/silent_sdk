# Set VS Code user settings for the current user. Run after setup-vscode.ps1.
# Telemetry off (telemetry.telemetryLevel). It is an application-wide setting that VS Code ignores in
# workspace settings and in non-default profiles, so it goes to the default profile's user settings.json.
# settings.json allows comments, so only the listed keys are replaced or added as text; every other line is kept.

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Key and its value as JSON text
$settings = [ordered]@{
    'telemetry.telemetryLevel' = '"off"'
}

$code = "$env:ProgramFiles\Microsoft VS Code\Code.exe", "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe" |
    Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $code) { throw 'VS Code not found. Run setup-vscode.ps1 first' }

# Under the elevated setup APPDATA is still the same user's folder
$path = "$env:APPDATA\Code\User\settings.json"

# A key written on its own line (commented-out lines do not match); group 1 is the current value
function Get-KeyPattern($key) {
    '(?m)^(\s*"' + [regex]::Escape($key) + '"\s*:\s*)("(?:[^"\\]|\\.)*"|true|false|null|-?\d+(?:\.\d+)?)'
}

$text = if (Test-Path $path) { [IO.File]::ReadAllText($path) } else { '' }
$pending = @($settings.Keys | Where-Object {
    $match = [regex]::Match($text, (Get-KeyPattern $_))
    -not $match.Success -or $match.Groups[2].Value -ne $settings[$_]
})
if (-not $pending) {
    Write-Host "VS Code user settings are already set, skipped: $($settings.Keys -join ', ')"
    $global:SetupStepSkipped = $true
    return
}

foreach ($key in $pending) {
    $pattern = Get-KeyPattern $key
    if ([regex]::IsMatch($text, $pattern)) {
        $text = [regex]::Replace($text, $pattern, { param($m) $m.Groups[1].Value + $settings[$key] })
        Write-Host "VS Code setting $key changed to $($settings[$key])"
    } elseif ($text -match '^\s*(\{\s*\})?\s*$') {
        # Missing or empty file
        $text = "{`n    `"$key`": $($settings[$key])`n}`n"
        Write-Host "VS Code setting $key added: $($settings[$key])"
    } else {
        # Added as the first property, so the comma never depends on the last one
        $brace = $text.IndexOf('{')
        if ($brace -lt 0) { throw "Not a JSON object, fix or remove it: $path" }
        $text = $text.Insert($brace + 1, "`n    `"$key`": $($settings[$key]),")
        Write-Host "VS Code setting $key added: $($settings[$key])"
    }
}

New-Item -ItemType Directory -Force (Split-Path $path) | Out-Null
[IO.File]::WriteAllText($path, $text, (New-Object Text.UTF8Encoding($false)))
Write-Host "VS Code user settings setup done: $path"
