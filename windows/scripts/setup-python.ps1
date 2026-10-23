# Setup Python for all users (NOT added to PATH; use the py launcher) and data analysis packages. Run as admin.
# Installs the newest patch of $minor that still ships a Windows installer
# (security-only releases are source-only on python.org).

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$minor    = '3.12'  # Most used Python version by package downloads (pypistats)
$packages = 'tqdm', 'pandas', 'matplotlib', 'seaborn', 'scikit-learn', 'ipykernel', 'openpyxl', 'requests'

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

$dir  = "$env:ProgramFiles\Python$($minor -replace '\.', '')"
$installArgs = "/quiet InstallAllUsers=1 TargetDir=`"$dir`" PrependPath=0 AppendPath=0 Include_test=0"
$p = Start-Process $exe -ArgumentList $installArgs -Wait -PassThru
if ($p.ExitCode -notin 0, 3010) { throw "Python installer failed: exit code $($p.ExitCode)" }
Write-Host "Python $version setup done: $dir (not in PATH, run with: py -$minor)"

& "$dir\python.exe" -m pip install --disable-pip-version-check @packages
if ($LASTEXITCODE -ne 0) { throw "pip install failed: exit code $LASTEXITCODE" }
Write-Host "Python packages installed: $($packages -join ', ')"
