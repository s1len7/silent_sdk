# Setup Python for the current user (NOT added to PATH; use the py launcher) and data analysis packages.
# Installs the newest patch of $minor that still ships a Windows installer
# (security-only releases are source-only on python.org).

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Installer logs go to the setup log folder (TEMP when run alone)
$logDir = if ($env:SILENT_SDK_LOG_DIR) { $env:SILENT_SDK_LOG_DIR } else { $env:TEMP }

$minor    = '3.12'  # Most used Python version by package downloads (pypistats)
$packages = 'tqdm', 'pandas', 'matplotlib', 'seaborn', 'scikit-learn', 'ipykernel', 'openpyxl', 'requests'

# Per-user default install folder (same user even when setup.ps1 runs elevated via UAC)
$dir    = "$env:LOCALAPPDATA\Programs\Python\Python$($minor -replace '\.', '')"
$python = "$dir\python.exe"

# Packages from $packages that pip does not list as installed (compared like pip: case and _/- insensitive)
function Get-MissingPackages {
    $installed = & $python -m pip list --format=freeze --disable-pip-version-check |
        ForEach-Object { ($_ -split '==')[0].ToLower().Replace('_', '-') }
    @($packages | Where-Object { $installed -notcontains $_.ToLower() })
}

if (Test-Path $python) {
    $missing = Get-MissingPackages
    if (-not $missing) {
        # Python itself is not upgraded here
        Write-Host "Python $minor and all packages are already installed, skipped: $dir"
        $global:SetupStepSkipped = $true
        return
    }
    Write-Host "Python $minor is already installed, installing missing packages: $($missing -join ', ')"
} else {
    $base = 'https://www.python.org/ftp/python'
    $html = (Invoke-WebRequest "$base/" -UseBasicParsing).Content
    $versions = [regex]::Matches($html, "href=""($([regex]::Escape($minor))\.\d+)/""") |
        ForEach-Object { [version]$_.Groups[1].Value } | Sort-Object -Descending -Unique

    $version = $null
    foreach ($v in $versions) {
        try {
            Invoke-WebRequest "$base/$v/python-$v-amd64.exe" -Method Head -UseBasicParsing | Out-Null
            $version = $v
            break
        } catch {
            # No Windows installer for this patch, try the previous one
        }
    }
    if (-not $version) { throw "No Windows installer found for Python $minor" }

    $exe = "$env:TEMP\python-$version-amd64.exe"
    Invoke-WebRequest "$base/$version/python-$version-amd64.exe" -OutFile $exe -UseBasicParsing

    $installArgs = "/quiet InstallAllUsers=0 InstallLauncherAllUsers=0 TargetDir=`"$dir`" PrependPath=0 AppendPath=0 Include_test=0 /log `"$logDir\python-install.log`""
    $p = Start-Process $exe -ArgumentList $installArgs -Wait -PassThru
    if ($p.ExitCode -notin 0, 3010) { throw "Python installer failed: exit code $($p.ExitCode)" }
    Write-Host "Python $version setup done: $dir (not in PATH, run with: py -$minor)"
}

& $python -m pip install --disable-pip-version-check --log "$logDir\pip-install.log" @packages
if ($LASTEXITCODE -ne 0) { throw "pip install failed: exit code $LASTEXITCODE" }
Write-Host "Python packages installed: $($packages -join ', ')"
