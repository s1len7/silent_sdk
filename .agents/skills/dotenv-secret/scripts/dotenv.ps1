# dotenv helper: read secrets from a .env file without printing them
# Usage:  . "<path>\dotenv.ps1"
#         $cfg = Get-DotEnvMap -Path "docs\.env"
#         $v   = Get-DotEnvValue -Path "docs\.env" -Key CODYSSEY_ID
#         Get-DotEnvKeys -Path "docs\.env"
# ASCII only on purpose: Windows PowerShell 5.1 reads a UTF-8 .ps1 without BOM as ANSI,
# and non-ASCII comments can break parsing.

function Get-DotEnvMap {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "dotenv: file not found: $Path"
    }

    $map = @{}
    foreach ($raw in Get-Content -LiteralPath $Path) {
        $line = $raw.Trim()
        if ($line -eq '' -or $line.StartsWith('#')) { continue }
        if ($line -match '^export\s+') { $line = $line -replace '^export\s+', '' }

        $ix = $line.IndexOf('=')
        if ($ix -lt 1) { continue }

        $key = $line.Substring(0, $ix).Trim()
        $val = $line.Substring($ix + 1).Trim()
        if ($val.Length -ge 2) {
            $first = $val[0]
            $last = $val[$val.Length - 1]
            if (($first -eq '"' -and $last -eq '"') -or ($first -eq "'" -and $last -eq "'")) {
                $val = $val.Substring(1, $val.Length - 2)
            }
        }
        $map[$key] = $val
    }
    return $map
}

function Get-DotEnvValue {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Key,
        [switch]$Required
    )

    $map = Get-DotEnvMap -Path $Path
    if (-not $map.ContainsKey($Key)) {
        if ($Required) { throw "dotenv: key not found: $Key" }
        return $null
    }
    $value = $map[$Key]
    if ($Required -and [string]::IsNullOrEmpty($value)) {
        throw "dotenv: key is empty: $Key"
    }
    return $value
}

function Get-DotEnvKeys {
    param([Parameter(Mandatory = $true)][string]$Path)

    $map = Get-DotEnvMap -Path $Path
    return @($map.Keys | Sort-Object)
}

function Test-DotEnvKey {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string[]]$Key
    )

    $map = Get-DotEnvMap -Path $Path
    $missing = @()
    foreach ($k in $Key) {
        if (-not $map.ContainsKey($k) -or [string]::IsNullOrEmpty($map[$k])) { $missing += $k }
    }
    return [pscustomobject]@{
        Ok      = ($missing.Count -eq 0)
        Missing = @($missing)
    }
}
