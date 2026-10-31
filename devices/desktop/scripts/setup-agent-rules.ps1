# Point the global instruction file of every AI agent on this PC at the shared silent_sdk rules (AGENTS.md in the repo root).
# Only agents that are installed (their config folder exists) are handled; the instruction file is created when missing.
# OpenCode does not follow references inside AGENTS.md by itself, so its opencode.json "instructions" also lists the rules.
# Repo skills live in <repo>\.agents\skills, the folder OpenCode, Codex and Gemini CLI read in the repo.
# Claude Code reads only <repo>\.claude\skills, so that path is made a junction to .agents\skills.
# Agents that cannot read the repo skills get copies of the shared skills in their own skills folder; a changed skill is copied again.
# Copies carry a marker file, so a skill dropped from $sharedSkills is removed and skills from elsewhere are never touched.
# The repo skills are local only (.agents/ is not in git), so without that folder the junction and skill copying are skipped.
# To cover a new agent, add one entry to $agents below.
# The block is English because .ps1 files here are ASCII-only (Windows PowerShell 5.1 misreads non-ASCII files without a BOM).

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Repo root AGENTS.md (this script is in <repo>\devices\desktop\scripts), forward slashes so every agent reads it as a path
$rulesPath = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\AGENTS.md')).Path.Replace('\', '/')
$skillsSource = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..\.agents\skills'))
$claudeSkills = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..\.claude\skills'))
$hasSkills = Test-Path $skillsSource
# Repo skills also useful outside the repo (operations, model and open source checks)
$sharedSkills = @('oss-review', 'openclaw-ops', 'free-model-check')
# Marks a skill folder as a copy made by this script
$marker = '.silent-sdk-managed'

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
# Config: optional opencode.json-style config whose "instructions" array must list the rules,
# Skills: optional skills folder that gets the shared skills (only for agents that cannot read the repo skills)
$agents = @(
    @{ Name = 'Claude Code'; Home = "$HOME\.claude"; File = "$HOME\.claude\CLAUDE.md"; Import = $true }
    @{ Name = 'OpenCode'; Home = "$HOME\.config\opencode"; File = "$HOME\.config\opencode\AGENTS.md"; Import = $false; Config = "$HOME\.config\opencode\opencode.json" }
    @{ Name = 'OpenClaw'; Home = "$HOME\.openclaw"; File = "$openClawWorkspace\AGENTS.md"; Import = $false; Skills = "$HOME\.openclaw\skills" }
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

# Relative path and hash of every file in a folder (marker excluded), to compare a copied skill with its source
function Get-FolderFingerprint($dir) {
    if (-not (Test-Path $dir)) { return '' }
    (Get-ChildItem $dir -Recurse -File | Where-Object Name -ne $marker | Sort-Object FullName | ForEach-Object {
        $_.FullName.Substring($dir.Length) + ':' + (Get-FileHash $_.FullName -Algorithm SHA256).Hash
    }) -join '|'
}

function Test-Managed($dir) { Test-Path (Join-Path $dir $marker) }

# Shared skills whose copy is missing, differs from the repo, or has no marker yet
function Get-StaleSkill($agent) {
    if (-not $agent.Skills -or -not $hasSkills) { return @() }
    @($sharedSkills | Where-Object {
        $target = Join-Path $agent.Skills $_
        -not (Test-Managed $target) -or
            (Get-FolderFingerprint $target) -ne (Get-FolderFingerprint (Join-Path $skillsSource $_))
    })
}

# Copies made by this script for skills no longer in $sharedSkills (renamed or dropped)
function Get-RetiredSkill($agent) {
    # Without the repo skills, existing copies are kept rather than treated as dropped
    if (-not $agent.Skills -or -not $hasSkills -or -not (Test-Path $agent.Skills)) { return @() }
    @(Get-ChildItem $agent.Skills -Directory |
        Where-Object { (Test-Managed $_.FullName) -and $sharedSkills -notcontains $_.Name } | ForEach-Object Name)
}

# True when there is nothing to link, or .claude\skills already points at .agents\skills.
# A real folder there is left alone (warned about below) so local Claude-only skills are never lost.
function Test-ClaudeSkillsLink {
    if (-not $hasSkills -or -not (Test-Path $claudeSkills)) { return -not $hasSkills }
    $item = Get-Item $claudeSkills -Force
    ($item.LinkType -ne 'Junction') -or (@($item.Target) -contains $skillsSource)
}

function Test-Agent($agent) {
    (Test-RuleReference $agent.File) -and (Test-ConfigInstruction $agent) -and
        -not (Get-StaleSkill $agent) -and -not (Get-RetiredSkill $agent)
}

if (-not $hasSkills) {
    Write-Host "Repo skills not found ($skillsSource), skill link and copying skipped"
}
$installed = @($agents | Where-Object { Test-Path $_.Home })
$linkReady = Test-ClaudeSkillsLink
if ($hasSkills -and (Test-Path $claudeSkills) -and (Get-Item $claudeSkills -Force).LinkType -ne 'Junction') {
    Write-Warning "Claude Code: $claudeSkills is a real folder, left as is. Move its skills to $skillsSource and remove it to link the repo skills"
}
foreach ($agent in $agents | Where-Object { -not (Test-Path $_.Home) }) {
    Write-Host "$($agent.Name) is not installed ($($agent.Home) not found), skipped. Run this step again after installing it."
}
if ($linkReady -and -not ($installed | Where-Object { -not (Test-Agent $_) })) {
    Write-Host "Agent instruction files already refer to $rulesPath and shared skills are current, skipped"
    $global:SetupStepSkipped = $true
    return
}

$utf8NoBom = New-Object Text.UTF8Encoding($false)
if (-not $linkReady) {
    # A junction pointing elsewhere is replaced; removing a junction does not touch its target
    if (Test-Path $claudeSkills) { (Get-Item $claudeSkills -Force).Delete() }
    New-Item -ItemType Directory -Force (Split-Path $claudeSkills) | Out-Null
    New-Item -ItemType Junction -Path $claudeSkills -Target $skillsSource | Out-Null
    Write-Host "Claude Code: linked $claudeSkills to $skillsSource"
}
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

    # A changed skill is replaced as a whole so removed files do not linger
    foreach ($skill in Get-StaleSkill $agent) {
        $source = Join-Path $skillsSource $skill
        $target = Join-Path $agent.Skills $skill
        if ((Test-Path $target) -and -not (Test-Managed $target)) {
            # Same content without a marker: a copy from before markers existed, so take it over
            if ((Get-FolderFingerprint $target) -ne (Get-FolderFingerprint $source)) {
                Write-Warning "$($agent.Name): $target was not copied by this script, left as is. Remove it to get the repo skill $skill"
                continue
            }
        } else {
            if (Test-Path $target) { Remove-Item $target -Recurse -Force }
            New-Item -ItemType Directory -Force $agent.Skills | Out-Null
            Copy-Item $source $target -Recurse
        }
        [IO.File]::WriteAllText((Join-Path $target $marker),
            "Copied by silent_sdk devices/desktop/scripts/setup-agent-rules.ps1 from .agents/skills/$skill. Local edits are overwritten.`n", $utf8NoBom)
        Write-Host "$($agent.Name): skill $skill is current in $target"
    }

    foreach ($skill in Get-RetiredSkill $agent) {
        Remove-Item (Join-Path $agent.Skills $skill) -Recurse -Force
        Write-Host "$($agent.Name): removed skill $skill (no longer shared)"
    }
}

if ($installed | Where-Object { Get-StaleSkill $_ }) {
    Write-Host "Agent instruction files now refer to $rulesPath; some shared skills were left as is (see the warnings above)"
} else {
    Write-Host "Agent instruction files now refer to $rulesPath and shared skills are current"
}
