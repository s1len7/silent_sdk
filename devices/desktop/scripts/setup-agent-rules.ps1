# Point the global instruction file of every AI agent on this PC at the shared silent_sdk rules (AGENTS.md in the repo root).
# Only agents that are installed (their config folder exists) are handled; the instruction file is created when missing.
# OpenCode does not follow references inside AGENTS.md by itself, so its opencode.json "instructions" also lists the rules.
# To cover a new agent, add one entry to $agents below.
# The block is English because .ps1 files here are ASCII-only (Windows PowerShell 5.1 misreads non-ASCII files without a BOM).

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Repo root AGENTS.md (this script is in <repo>\devices\desktop\scripts), forward slashes so every agent reads it as a path
$rulesPath = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\AGENTS.md')).Path.Replace('\', '/')

# OpenClaw workspace: config value, or the default when unset or when the CLI is not usable
$openClawWorkspace = "$HOME\.openclaw\workspace"
if (Get-Command openclaw -ErrorAction SilentlyContinue) {
    # An unset path is reported on stderr, which 'Stop' turns into an error in Windows PowerShell 5.1
    try {
        $configured = ((& openclaw config get agents.defaults.workspace 2>$null) -join '').Trim().Trim('"')
        if ($LASTEXITCODE -eq 0 -and $configured) { $openClawWorkspace = $configured }
    } catch { }
}

# Home: the agent's config folder (missing = not installed), File: its global instruction file,
# Import: how the file refers to the rules (Claude Code loads @path imports; the others read the path when told to),
# Config: optional opencode.json-style config whose "instructions" array must list the rules
$agents = @(
    @{ Name = 'Claude Code'; Home = "$HOME\.claude"; File = "$HOME\.claude\CLAUDE.md"; Import = $true }
    @{ Name = 'OpenCode'; Home = "$HOME\.config\opencode"; File = "$HOME\.config\opencode\AGENTS.md"; Import = $false; Config = "$HOME\.config\opencode\opencode.json" }
    @{ Name = 'OpenClaw'; Home = "$HOME\.openclaw"; File = "$openClawWorkspace\AGENTS.md"; Import = $false }
)

function Get-RulesBlock($agent) {
    $reference = if ($agent.Import) { "@$rulesPath" } else {
        "Read and follow ``$rulesPath`` before starting any task."
    }
    "## silent_sdk rules`n`nShared rules for every AI agent on this PC:`n`n$reference`n"
}

# True when the file already mentions the rules path
function Test-RuleReference($file) {
    (Test-Path $file) -and ([IO.File]::ReadAllText($file).IndexOf($rulesPath, [StringComparison]::OrdinalIgnoreCase) -ge 0)
}

# Parsed JSON config, or $null when missing; throws on invalid JSON so a user config is never overwritten
function Read-JsonFile($path) {
    if (-not (Test-Path $path)) { return $null }
    $text = [IO.File]::ReadAllText($path)
    if (-not $text.Trim()) { return $null }
    try { $text | ConvertFrom-Json } catch { throw "Invalid JSON in $path, fix or remove it: $($_.Exception.Message)" }
}

# True when the agent has no config to update, or its "instructions" already list the rules
function Test-ConfigInstruction($agent) {
    if (-not $agent.Config) { return $true }
    $config = Read-JsonFile $agent.Config
    $config -and (@($config.instructions) -contains $rulesPath)
}

function Test-Agent($agent) { (Test-RuleReference $agent.File) -and (Test-ConfigInstruction $agent) }

$installed = @($agents | Where-Object { Test-Path $_.Home })
foreach ($agent in $agents | Where-Object { -not (Test-Path $_.Home) }) {
    Write-Host "$($agent.Name) is not installed ($($agent.Home) not found), skipped. Run this step again after installing it."
}
if (-not ($installed | Where-Object { -not (Test-Agent $_) })) {
    Write-Host "Agent instruction files already refer to $rulesPath, skipped"
    $global:SetupStepSkipped = $true
    return
}

$utf8NoBom = New-Object Text.UTF8Encoding($false)
foreach ($agent in $installed) {
    if (Test-RuleReference $agent.File) {
        Write-Host "$($agent.Name): $($agent.File) already refers to the rules"
    } else {
        New-Item -ItemType Directory -Force (Split-Path $agent.File) | Out-Null
        $existing = if (Test-Path $agent.File) { [IO.File]::ReadAllText($agent.File) } else { '' }
        # Keep the existing content and add the block at the end, separated by a blank line
        $separator = if (-not $existing) { '' } elseif ($existing.EndsWith("`n")) { "`n" } else { "`n`n" }
        [IO.File]::WriteAllText($agent.File, $existing + $separator + (Get-RulesBlock $agent), $utf8NoBom)
        Write-Host "$($agent.Name): added the rules reference to $($agent.File)"
    }

    # Other keys in an existing config are kept; written as UTF-8 without BOM
    if (-not (Test-ConfigInstruction $agent)) {
        $config = Read-JsonFile $agent.Config
        if (-not $config) { $config = [pscustomobject]@{ '$schema' = 'https://opencode.ai/config.json' } }
        $instructions = @(@($config.instructions) | Where-Object { $_ }) + $rulesPath
        $config | Add-Member -NotePropertyName instructions -NotePropertyValue $instructions -Force
        [IO.File]::WriteAllText($agent.Config, ($config | ConvertTo-Json -Depth 20), $utf8NoBom)
        Write-Host "$($agent.Name): added the rules to the instructions in $($agent.Config)"
    }
}

Write-Host "Agent instruction files now refer to $rulesPath"
