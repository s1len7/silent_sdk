# Install third-party skills and plugins for Claude Code, OpenCode, Kilo and OpenClaw.
# Run as admin after the agents are installed.
# Claude Code uses the official plugin marketplaces; OpenCode uses its plugin manager for
# Superpowers and Ponytail; Kilo uses its plugin manager for Ponytail; OpenClaw uses ClawHub
# for Ponytail. Superpowers has no Kilo or OpenClaw plugin, so those agents get its skills
# only. OpenCode, Kilo and OpenClaw get the Anthropic document and example skills through
# the skills CLI. Claude Code gets the same sets from the Anthropic marketplace.
# Docs: https://github.com/obra/superpowers, https://github.com/anthropics/skills,
# https://github.com/DietrichGebert/ponytail

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$logDir = if ($env:SILENT_SDK_LOG_DIR) { $env:SILENT_SDK_LOG_DIR } else { $env:TEMP }
New-Item -ItemType Directory -Force $logDir | Out-Null
$installLog = Join-Path $logDir 'agent-skills-install.log'
# The skills and ClawHub CLIs send anonymous usage data unless these are set.
$env:DISABLE_TELEMETRY = '1'
$env:CLAWHUB_DISABLE_TELEMETRY = '1'

# Node.js and the npm global bin in this session too (a fresh install only updates PATH for new processes)
foreach ($dir in "$env:ProgramFiles\nodejs", "$env:LOCALAPPDATA\Programs\nodejs", "$env:APPDATA\npm") {
    if ((Test-Path $dir) -and (($env:Path -split ';') -notcontains $dir)) { $env:Path = "$dir;$env:Path" }
}

$claudeHome = "$HOME\.claude"
$openCodeHome = "$HOME\.config\opencode"
# The skills CLI installs global skills to ~\.agents\skills. OpenCode and Kilo both read it.
$agentsSkills = "$HOME\.agents\skills"
$kiloHome = "$HOME\.config\kilo"
$openClawHome = "$HOME\.openclaw"
$openClawSkills = "$openClawHome\skills"

# Skills installed by each source. A missing SKILL.md means that source is not fully installed.
$superpowersSkills = @(
    'brainstorming', 'diagnosing-superpowers', 'dispatching-parallel-agents',
    'executing-plans', 'finishing-a-development-branch', 'receiving-code-review',
    'requesting-code-review', 'subagent-driven-development', 'systematic-debugging',
    'test-driven-development', 'using-git-worktrees', 'using-superpowers',
    'verification-before-completion', 'writing-plans', 'writing-skills'
)
$ponytailSkills = @(
    'ponytail', 'ponytail-audit', 'ponytail-debt', 'ponytail-gain', 'ponytail-help',
    'ponytail-review'
)
$ponytailOwner = 'dietrichgebert'
# The two skill sets in anthropics/skills: document-skills and example-skills
$anthropicSkills = @(
    'xlsx', 'docx', 'pptx', 'pdf',
    'algorithmic-art', 'brand-guidelines', 'canvas-design', 'doc-coauthoring',
    'frontend-design', 'internal-comms', 'mcp-builder', 'skill-creator',
    'slack-gif-creator', 'theme-factory', 'web-artifacts-builder', 'webapp-testing'
)

$script:didWork = $false
$failures = @()

function Get-CommandPath {
    param([string]$Name)
    foreach ($candidate in @("$Name.cmd", "$Name.exe", $Name)) {
        $command = Get-Command $candidate -ErrorAction SilentlyContinue
        if ($command) { return $command.Source }
    }
    return $null
}

# Run a command and capture stdout and stderr separately (UTF-8 or UTF-16 with BOM)
function Invoke-Captured {
    param([string]$File, [string[]]$Arguments)
    $stdout = [IO.Path]::GetTempFileName()
    $stderr = [IO.Path]::GetTempFileName()
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        & $File @Arguments 1> $stdout 2> $stderr
        $code = $LASTEXITCODE
        $outText = if (Test-Path $stdout) { Get-Content $stdout -Raw -ErrorAction SilentlyContinue } else { '' }
        $errText = if (Test-Path $stderr) { Get-Content $stderr -Raw -ErrorAction SilentlyContinue } else { '' }
        [pscustomobject]@{ Code = $code; Out = "$outText"; Err = "$errText" }
    } finally {
        $ErrorActionPreference = $previous
        Remove-Item $stdout, $stderr -Force -ErrorAction SilentlyContinue
    }
}

# Run an installer, show its output, and append it to the install log
function Invoke-Logged {
    param([string]$File, [string[]]$Arguments)
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        & $File @Arguments 2>&1 | ForEach-Object {
            Write-Host $_
            $_ | Out-File -FilePath $installLog -Append -Encoding utf8
        }
        return $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previous
    }
}

function Assert-ExitCode {
    param([int]$Code, [string]$What)
    if ($Code -ne 0) { throw "$What failed: exit code $Code (log: $installLog)" }
}

function Test-SkillSet {
    param([string]$Dir, [string[]]$Names)
    foreach ($name in $Names) {
        if (-not (Test-Path (Join-Path $Dir "$name\SKILL.md"))) { return $false }
    }
    return $true
}

# Parsed JSON config, or $null when missing; throws on invalid JSON so a user config is never overwritten
function Read-JsonFile {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return $null }
    $text = [IO.File]::ReadAllText($Path)
    if (-not $text.Trim()) { return $null }
    try { $text | ConvertFrom-Json } catch { throw "Invalid JSON in ${Path}, fix or remove it: $($_.Exception.Message)" }
}

# True when a config already lists a plugin entry; JSONC files are checked as text
function Test-PluginEntry {
    param([string[]]$Paths, [string[]]$Keys, [string]$Pattern)
    foreach ($path in $Paths) {
        if (-not (Test-Path $path)) { continue }
        $text = [IO.File]::ReadAllText($path)
        try {
            $config = $text | ConvertFrom-Json
            foreach ($key in $Keys) {
                foreach ($entry in @($config.$key)) {
                    if ("$entry" -match $Pattern) { return $true }
                    if (($entry | ConvertTo-Json -Compress -Depth 10) -match $Pattern) { return $true }
                }
            }
        } catch {
            if ($text -match $Pattern) { return $true }
        }
    }
    return $false
}

# Add one entry to a JSON plugin array; only used for OpenCode V1, which has no plugin add command
function Add-PluginEntry {
    param([string]$Path, [string]$Key, [string]$Entry)
    $config = Read-JsonFile $Path
    if (-not $config) { $config = [pscustomobject]@{ '$schema' = 'https://opencode.ai/config.json' } }
    $entries = @(@($config.$Key) | Where-Object { $_ }) + $Entry
    $config | Add-Member -NotePropertyName $Key -NotePropertyValue $entries -Force
    New-Item -ItemType Directory -Force (Split-Path $Path) | Out-Null
    [IO.File]::WriteAllText($Path, ($config | ConvertTo-Json -Depth 20), (New-Object Text.UTF8Encoding($false)))
}

function Get-MajorVersion {
    param([string]$File)
    $result = Invoke-Captured $File @('--version')
    if ($result.Code -ne 0) { return 0 }
    if ($result.Out -match '(\d+)\.') { return [int]$Matches[1] }
    return 0
}

function Get-ClaudePluginId {
    param([string]$Claude)
    $result = Invoke-Captured $Claude @('plugin', 'list', '--json')
    if ($result.Code -ne 0) { throw "claude plugin list failed: $($result.Err.Trim())" }
    $text = $result.Out.Trim()
    if (-not $text) { return @() }
    try {
        $items = $text | ConvertFrom-Json
        @($items | ForEach-Object { "$($_.id)" })
    } catch {
        throw "Could not parse claude plugin list --json: $($_.Exception.Message)"
    }
}

function Install-ClaudePlugin {
    param([string]$Claude, [string]$Id, [string]$Marketplace)
    if (@(Get-ClaudePluginId $Claude) -contains $Id) {
        Write-Host "Claude Code: plugin $Id is already installed"
        return
    }
    $code = Invoke-Logged $Claude @('plugin', 'marketplace', 'add', $Marketplace)
    Assert-ExitCode $code "claude plugin marketplace add $Marketplace"
    # -y is needed because setup runs without a TTY when a plugin declares an install command
    $code = Invoke-Logged $Claude @('plugin', 'install', $Id, '-y')
    Assert-ExitCode $code "claude plugin install $Id"
    if (-not (@(Get-ClaudePluginId $Claude) -contains $Id)) {
        throw "plugin $Id was not listed after install"
    }
    $script:didWork = $true
    Write-Host "Claude Code: installed plugin $Id"
}

function Install-OpenCodePlugin {
    param([string]$OpenCode, [string]$Entry)
    $major = Get-MajorVersion $OpenCode
    if ($major -ge 2) {
        $code = Invoke-Logged $OpenCode @('plugin', 'add', $Entry)
        Assert-ExitCode $code "opencode plugin add $Entry"
    } else {
        # OpenCode V1 has no plugin add command and reads the older "plugin" key
        $configPath = "$openCodeHome\opencode.json"
        if (-not (Test-Path $configPath) -and (Test-Path "$openCodeHome\opencode.jsonc")) {
            throw "V1 uses $openCodeHome\opencode.jsonc; add this entry to its plugin array by hand: $Entry"
        }
        Add-PluginEntry $configPath 'plugin' $Entry
    }
    $script:didWork = $true
    Write-Host "OpenCode: installed plugin $Entry"
}

function Install-SkillSet {
    param([string]$Npx, [string]$Agent, [string]$Source, [string[]]$SkillArgs)
    $arguments = @('--yes', 'skills@latest', 'add', $Source, '-g', '-a', $Agent, '-y') + $SkillArgs
    $code = Invoke-Logged $Npx $arguments
    Assert-ExitCode $code "npx skills add $Source for $Agent"
    $script:didWork = $true
}

# Install one skill set for one agent; skip when already present and record any failure
function Ensure-SkillSet {
    param([string]$Label, [string]$Dir, [string]$Agent, [string]$Source, [string]$SetName, [string[]]$Names)
    if (Test-SkillSet $Dir $Names) {
        Write-Host "$Label`: $SetName skills are already installed"
        return
    }
    if (-not $npx) {
        $script:failures += "$Label`: npx not found. Run setup-opencode.ps1 first to install Node.js"
        return
    }
    try {
        $skillArgs = @()
        foreach ($skill in $Names) { $skillArgs += @('--skill', $skill) }
        Install-SkillSet $npx $Agent $Source $skillArgs
        if (-not (Test-SkillSet $Dir $Names)) {
            throw "$SetName skills were not all found in $Dir"
        }
        Write-Host "$Label`: installed $SetName skills"
    } catch {
        $script:failures += "$Label`: $($_.Exception.Message)"
    }
}

function Install-ClawHub {
    $clawhub = Get-CommandPath 'clawhub'
    if ($clawhub) { return $clawhub }
    $npm = Get-CommandPath 'npm'
    if (-not $npm) { throw 'npm not found. Run setup-opencode.ps1 first to install Node.js' }
    $code = Invoke-Logged $npm @('install', '-g', 'clawhub@latest', '--loglevel', 'error', '--logs-dir', $logDir)
    Assert-ExitCode $code 'npm install clawhub'
    $clawhub = Get-CommandPath 'clawhub'
    if (-not $clawhub) { throw "clawhub not found after install (npm global bin: $env:APPDATA\npm)" }
    $script:didWork = $true
    return $clawhub
}

function Install-ClawHubSkill {
    param([string]$ClawHub, [string]$Name)
    # ClawHub stores owner-qualified skills under @owner\name, so the bare slug is ambiguous
    $slug = "@$ponytailOwner/$Name"
    $skillDir = Join-Path $openClawSkills "@$ponytailOwner\$Name"
    if (Test-Path (Join-Path $skillDir 'SKILL.md')) {
        Write-Host "OpenClaw: skill $slug is already installed"
        return
    }
    $code = Invoke-Logged $ClawHub @('install', $slug, '--workdir', $openClawHome, '--dir', 'skills', '--no-input')
    Assert-ExitCode $code "clawhub install $slug"
    if (-not (Test-Path (Join-Path $skillDir 'SKILL.md'))) {
        throw "$slug was not found after install: $skillDir"
    }
    $script:didWork = $true
    Write-Host "OpenClaw: installed skill $slug"
}

$npx = Get-CommandPath 'npx'

# Claude Code: install the three plugin sets at user scope
if (Test-Path $claudeHome) {
    $claude = Get-CommandPath 'claude'
    if (-not $claude) {
        Write-Warning "Claude Code config exists but the claude command was not found, skipped"
    } else {
        $claudePlugins = @(
            @{ Id = 'superpowers@claude-plugins-official'; Marketplace = 'anthropics/claude-plugins-official' }
            @{ Id = 'ponytail@ponytail'; Marketplace = 'DietrichGebert/ponytail' }
            @{ Id = 'document-skills@anthropic-agent-skills'; Marketplace = 'anthropics/skills' }
            @{ Id = 'example-skills@anthropic-agent-skills'; Marketplace = 'anthropics/skills' }
        )
        foreach ($plugin in $claudePlugins) {
            try {
                Install-ClaudePlugin $claude $plugin.Id $plugin.Marketplace
            } catch {
                $failures += "Claude Code: $($_.Exception.Message)"
            }
        }
    }
} else {
    Write-Host "Claude Code is not installed ($claudeHome not found), skipped"
}

# OpenCode: Superpowers and Ponytail as plugins, Anthropic skills through the skills CLI
if (Test-Path $openCodeHome) {
    $openCode = Get-CommandPath 'opencode'
    if (-not $openCode) {
        Write-Warning "OpenCode config exists but the opencode command was not found, skipped"
    } else {
        $configPaths = @("$openCodeHome\opencode.json", "$openCodeHome\opencode.jsonc")
        $configKeys = @('plugins', 'plugin')
        foreach ($plugin in @(
            @{ Entry = 'superpowers@git+https://github.com/obra/superpowers.git'; Pattern = '^superpowers(@|$)' }
            @{ Entry = '@dietrichgebert/ponytail'; Pattern = '^@dietrichgebert/ponytail(@|$)' }
        )) {
            if (Test-PluginEntry $configPaths $configKeys $plugin.Pattern) {
                Write-Host "OpenCode: plugin $($plugin.Entry) is already configured"
                continue
            }
            try {
                Install-OpenCodePlugin $openCode $plugin.Entry
                if (-not (Test-PluginEntry $configPaths $configKeys $plugin.Pattern)) {
                    throw "$($plugin.Entry) was not found in the config after install"
                }
            } catch {
                $failures += "OpenCode: $($_.Exception.Message)"
            }
        }
    }
    Ensure-SkillSet 'OpenCode' $agentsSkills 'opencode' 'anthropics/skills' 'Anthropic' $anthropicSkills
} else {
    Write-Host "OpenCode is not installed ($openCodeHome not found), skipped"
}

# Kilo: Ponytail as a plugin, Superpowers and Anthropic skills through the skills CLI
if (Test-Path $kiloHome) {
    $kilo = Get-CommandPath 'kilo'
    $kiloConfigs = @(
        "$kiloHome\kilo.jsonc", "$kiloHome\kilo.json",
        "$kiloHome\opencode.json", "$kiloHome\opencode.jsonc",
        "$kiloHome\tui.json", "$kiloHome\tui.jsonc"
    )
    $ponytailPattern = '^@dietrichgebert/ponytail(@|$)'
    if (Test-PluginEntry $kiloConfigs @('plugin') $ponytailPattern) {
        Write-Host 'Kilo: plugin @dietrichgebert/ponytail is already configured'
    } elseif (-not $kilo) {
        $failures += 'Kilo: kilo command not found. Run setup-kilo-cli.ps1 first'
    } else {
        try {
            $code = Invoke-Logged $kilo @('plugin', '@dietrichgebert/ponytail', '--global')
            Assert-ExitCode $code 'kilo plugin @dietrichgebert/ponytail'
            if (-not (Test-PluginEntry $kiloConfigs @('plugin') $ponytailPattern)) {
                throw 'ponytail was not found in the config after install'
            }
            $script:didWork = $true
            Write-Host 'Kilo: installed plugin @dietrichgebert/ponytail'
        } catch {
            $failures += "Kilo: $($_.Exception.Message)"
        }
    }
    Ensure-SkillSet 'Kilo' $agentsSkills 'kilo' 'obra/superpowers' 'Superpowers' $superpowersSkills
    Ensure-SkillSet 'Kilo' $agentsSkills 'kilo' 'anthropics/skills' 'Anthropic' $anthropicSkills
} else {
    Write-Host "Kilo is not installed ($kiloHome not found), skipped"
}

# OpenClaw: Ponytail from ClawHub, Superpowers and Anthropic skills through the skills CLI
if (Test-Path $openClawHome) {
    $missingPonytail = @($ponytailSkills | Where-Object { -not (Test-Path (Join-Path $openClawSkills "@$ponytailOwner\$_\SKILL.md")) })
    if (-not $missingPonytail) {
        Write-Host 'OpenClaw: Ponytail skills are already installed'
    } else {
        try {
            $clawhub = Install-ClawHub
            foreach ($skill in $missingPonytail) {
                try { Install-ClawHubSkill $clawhub $skill }
                catch { $failures += "OpenClaw: $($_.Exception.Message)" }
            }
        } catch {
            $failures += "OpenClaw: $($_.Exception.Message)"
        }
    }
    Ensure-SkillSet 'OpenClaw' $openClawSkills 'openclaw' 'obra/superpowers' 'Superpowers' $superpowersSkills
    Ensure-SkillSet 'OpenClaw' $openClawSkills 'openclaw' 'anthropics/skills' 'Anthropic' $anthropicSkills
} else {
    Write-Host "OpenClaw is not installed ($openClawHome not found), skipped"
}

if ($failures) {
    throw ($failures -join '; ')
}
if (-not $script:didWork) {
    Write-Host 'Third-party agent skills and plugins are already set up, skipped'
    $global:SetupStepSkipped = $true
    return
}
Write-Host "Third-party agent skills and plugins setup done (log: $installLog)"
