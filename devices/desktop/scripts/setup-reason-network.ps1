# Setup Reason Network: install the Reason CLI per user, join (or create) a network, and register
# the Reason Network MCP server with the agents the Reason CLI does not set up itself.
# The Reason CLI registers Claude Code, Codex, Cursor, Gemini CLI, Copilot CLI, opencode and Pi;
# Kilo, Cline CLI and OpenClaw are added here.
# Run as admin. Opens the browser to sign in on the first run; later runs only check the agent configs.
# Docs: https://reasonmachines.com/network

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

$logDir = if ($env:SILENT_SDK_LOG_DIR) { $env:SILENT_SDK_LOG_DIR } else { $env:TEMP }
New-Item -ItemType Directory -Force $logDir | Out-Null

# Reason refuses to run when NO_PROXY (or its lowercase form) is inherited from
# the environment, so clear it for this process and its children only.
$env:NO_PROXY = $null
$env:no_proxy = $null

$reasonDir = Join-Path $env:LOCALAPPDATA 'Reason\bin'
$reasonExe = Join-Path $reasonDir 'reason.exe'
$engineExe = Join-Path $env:USERPROFILE '.reason\bin\reason-network.exe'
$networkDir = Join-Path $env:USERPROFILE '.reason\network'
$utf8NoBom = New-Object Text.UTF8Encoding($false)

# Account shown by 'reason status', or $null when the output says signed out or has no account line
function Get-SignedInAccount([string]$status) {
    foreach ($line in $status -split "`r?`n") {
        if ($line -match '^\s*Account:\s*(.+?)\s*$') {
            if ($Matches[1] -eq 'signed out') { return $null }
            return $Matches[1]
        }
    }
    return $null
}

# Index of the brace closing the object opened at $open, or -1.
# Quoted strings, line comments and block comments are skipped, so JSONC files can be edited too.
function Get-ObjectEnd([string]$text, [int]$open) {
    $depth = 0
    $i = $open
    while ($i -lt $text.Length) {
        $c = $text[$i]
        if ($c -eq '"') {
            $i++
            while ($i -lt $text.Length -and $text[$i] -ne '"') {
                if ($text[$i] -eq [char]'\') { $i++ }
                $i++
            }
        } elseif ($c -eq [char]'/' -and $i + 1 -lt $text.Length -and $text[$i + 1] -eq [char]'/') {
            $end = $text.IndexOf("`n", $i)
            $i = if ($end -lt 0) { $text.Length } else { $end }
            continue
        } elseif ($c -eq [char]'/' -and $i + 1 -lt $text.Length -and $text[$i + 1] -eq [char]'*') {
            $end = $text.IndexOf('*/', $i)
            $i = if ($end -lt 0) { $text.Length } else { $end + 1 }
            continue
        } elseif ($c -eq [char]'{') {
            $depth++
        } elseif ($c -eq [char]'}') {
            $depth--
            if ($depth -eq 0) { return $i }
        }
        $i++
    }
    return -1
}

# Index of the first character that is not whitespace or a comment, or -1
function Get-FirstToken([string]$text) {
    $i = 0
    while ($i -lt $text.Length) {
        if ([char]::IsWhiteSpace($text[$i])) { $i++; continue }
        if ($text[$i] -eq [char]'/' -and $i + 1 -lt $text.Length -and $text[$i + 1] -eq [char]'/') {
            $end = $text.IndexOf("`n", $i)
            $i = if ($end -lt 0) { $text.Length } else { $end + 1 }
            continue
        }
        if ($text[$i] -eq [char]'/' -and $i + 1 -lt $text.Length -and $text[$i + 1] -eq [char]'*') {
            $end = $text.IndexOf('*/', $i)
            $i = if ($end -lt 0) { $text.Length } else { $end + 2 }
            continue
        }
        return $i
    }
    return -1
}

# Whitespace before the line that contains $index
function Get-LineIndent([string]$text, [int]$index) {
    $start = $text.LastIndexOf("`n", [Math]::Max($index - 1, 0))
    $line = $text.Substring($start + 1, $index - $start - 1)
    ([regex]::Match($line, '^[ \t]*')).Value
}

# JSON object with the given properties, indented at $indent
function Format-JsonObject([string]$indent, [string[]]$properties) {
    $lines = @('{')
    $lines += $properties | ForEach-Object { "$indent  $_" }
    $lines += "$indent}"
    $lines -join "`n"
}

# Adds a server to the object named $objectName ("mcp", "mcpServers") of a JSON or JSONC config,
# keeping comments, formatting and other keys. A missing config file is created.
# An existing entry without REASON_NETWORK_AGENT (written by an older version of this script) is
# rewritten. Returns $true when the file changed.
function Add-JsonMcpServer([string]$path, [string]$objectName, [string]$name, [string[]]$properties) {
    if (-not (Test-Path -LiteralPath $path)) {
        New-Item -ItemType Directory -Force (Split-Path $path) | Out-Null
        [IO.File]::WriteAllText($path, "{`n}`n", $utf8NoBom)
    }
    $text = [IO.File]::ReadAllText($path)
    $existing = [regex]::Match($text, '"' + [regex]::Escape($name) + '"\s*:\s*\{')
    if (-not $existing.Success -and $text -match ('"' + [regex]::Escape($name) + '"\s*:')) {
        throw "The `"$name`" entry in $path is not an object, fix or remove it by hand"
    }
    if ($existing.Success) {
        $open = $existing.Index + $existing.Length - 1
        $close = Get-ObjectEnd $text $open
        if ($close -lt 0) { throw "Unbalanced braces in $path" }
        if ($text.Substring($open, $close - $open + 1) -match 'REASON_NETWORK_AGENT') { return $false }
        $text = $text.Substring(0, $open) + (Format-JsonObject (Get-LineIndent $text $open) $properties) + $text.Substring($close + 1)
    } else {
        $owner = [regex]::Match($text, '"' + [regex]::Escape($objectName) + '"\s*:\s*\{')
        if (-not $owner.Success -and $text -match ('"' + [regex]::Escape($objectName) + '"\s*:')) {
            throw "The `"$objectName`" key in $path is not an object, add the server by hand"
        }
        if ($owner.Success) {
            # Inside the existing object, after its last entry
            $open = $owner.Index + $owner.Length - 1
            $indent = Get-LineIndent $text $owner.Index
            $server = "$indent  `"$name`": " + (Format-JsonObject "$indent  " $properties)
        } else {
            # A new section, before the closing brace of the root object
            $root = Get-FirstToken $text
            if ($root -lt 0 -or $text[$root] -ne [char]'{') { throw "No JSON object in $path" }
            $open = $root
            $indent = (Get-LineIndent $text $root) + '  '
            $server = "$indent`"$objectName`": {`n$indent  `"$name`": " + (Format-JsonObject "$indent  " $properties) + "`n$indent}"
        }
        $close = Get-ObjectEnd $text $open
        if ($close -lt 0) { throw "Unbalanced braces in $path" }
        $at = $close
        while ($at -gt $open + 1 -and [char]::IsWhiteSpace($text[$at - 1])) { $at-- }
        if ($at -eq $open + 1) {
            # Empty object: the whitespace between the braces is replaced
            $text = $text.Substring(0, $open + 1) + "`n$server`n" + (Get-LineIndent $text $close) + $text.Substring($close)
        } else {
            $text = $text.Insert($at, ",`n$server")
        }
    }
    if (-not $text.EndsWith("`n")) { $text += "`n" }
    [IO.File]::WriteAllText($path, $text, $utf8NoBom)
    return $true
}

# Registers with OpenClaw through its own CLI, which validates the entry. Returns $true when it changed.
function Add-OpenClawMcpServer([string]$command, [string]$agent) {
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        & openclaw mcp show reason-network *> $null
        if ($LASTEXITCODE -eq 0) { return $false }
        $output = & openclaw mcp add reason-network --command $command --arg mcp --env "REASON_NETWORK_AGENT=$agent" --no-probe 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0) { throw "openclaw mcp add failed: exit code $LASTEXITCODE ($($output.Trim()))" }
        return $true
    } finally {
        $ErrorActionPreference = $previous
    }
}

# Signed in only when the CLI answers and names an account; any error means signing in again
$signedIn = $false
if (Test-Path -LiteralPath $reasonExe) {
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $status = & $reasonExe status 2>&1 | Out-String
        if ($LASTEXITCODE -eq 0) { $signedIn = [bool](Get-SignedInAccount $status) }
    } catch {
        $signedIn = $false
    } finally {
        $ErrorActionPreference = $previous
    }
}
$needSetup = -not ((Test-Path -LiteralPath $reasonExe) -and (Test-Path -LiteralPath $networkDir) -and $signedIn)

if ($needSetup) {
    New-Item -ItemType Directory -Force $reasonDir | Out-Null

    Write-Host 'Installing Reason and joining Reason Network (browser sign-in may open)'

    $installLog = Join-Path $logDir 'reason-network-install.log'
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $wrapper = Invoke-RestMethod -Uri 'https://reasonmachines.com/network/install.ps1' -UseBasicParsing
        & ([scriptblock]::Create($wrapper)) 2>&1 | Tee-Object -FilePath $installLog
    } finally {
        $ErrorActionPreference = $previous
    }
    if ($LASTEXITCODE) { throw "Reason Network setup failed: exit code $LASTEXITCODE (log: $installLog)" }

    if (-not (Test-Path -LiteralPath $reasonExe)) {
        throw "Reason CLI not found after install: $reasonExe (log: $installLog)"
    }
    if (($env:Path -split ';') -notcontains $reasonDir) {
        $env:Path = "$env:Path;$reasonDir"
    }
}

# The agents below are registered on every run, so an agent installed after the first run
# and an entry removed by hand are picked up again without signing in once more.
$changed = $false
if (-not (Test-Path -LiteralPath $engineExe)) {
    Write-Warning "Reason Network engine not found, agent registration skipped: $engineExe"
} else {
    $engineJson = $engineExe -replace '\\', '\\'

    $kiloConfig = Join-Path $env:USERPROFILE '.config\kilo\kilo.jsonc'
    if (Test-Path -LiteralPath $kiloConfig) {
        $kiloProperties = @(
            "`"type`": `"local`","
            "`"command`": [`"$engineJson`", `"mcp`"],"
            "`"environment`": { `"REASON_NETWORK_AGENT`": `"kilo`" },"
            "`"enabled`": true"
        )
        try {
            if (Add-JsonMcpServer $kiloConfig 'mcp' 'reason-network' $kiloProperties) {
                Write-Host "Registered Reason Network MCP in Kilo Code: $kiloConfig"
                $changed = $true
            } else {
                Write-Host "Kilo Code already has the Reason Network MCP, skipped: $kiloConfig"
            }
        } catch {
            Write-Warning "Kilo MCP registration skipped: $($_.Exception.Message)"
        }
    }

    $clineHome = Join-Path $env:USERPROFILE '.cline'
    if (Test-Path -LiteralPath $clineHome) {
        $clineConfig = Join-Path $clineHome 'data\settings\cline_mcp_settings.json'
        $clineProperties = @(
            "`"command`": `"$engineJson`","
            "`"args`": [`"mcp`"],"
            "`"env`": { `"REASON_NETWORK_AGENT`": `"cline`" },"
            "`"disabled`": false"
        )
        try {
            if (Add-JsonMcpServer $clineConfig 'mcpServers' 'reason-network' $clineProperties) {
                Write-Host "Registered Reason Network MCP in Cline CLI: $clineConfig"
                $changed = $true
            } else {
                Write-Host "Cline CLI already has the Reason Network MCP, skipped: $clineConfig"
            }
        } catch {
            Write-Warning "Cline MCP registration skipped: $($_.Exception.Message)"
        }
    }

    $openClawConfig = Join-Path $env:USERPROFILE '.openclaw\openclaw.json'
    if ((Test-Path -LiteralPath $openClawConfig) -and (Get-Command openclaw -ErrorAction SilentlyContinue)) {
        try {
            if (Add-OpenClawMcpServer $engineExe 'openclaw') {
                Write-Host 'Registered Reason Network MCP in OpenClaw'
                $changed = $true
            } else {
                Write-Host 'OpenClaw already has the Reason Network MCP, skipped'
            }
        } catch {
            Write-Warning "OpenClaw MCP registration skipped: $($_.Exception.Message)"
        }
    }
}

if (-not $needSetup -and -not $changed) {
    Write-Host "Reason Network is already set up, skipped: $reasonExe"
    $global:SetupStepSkipped = $true
    return
}

Write-Host "Reason Network setup done: $reasonExe"
Write-Host "Run 'reason network who' to see the team. Use 'reason network invite' to share the join line."
