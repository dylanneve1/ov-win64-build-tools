
param(
    [string]$Tag = "",
    [Parameter(Mandatory = $true)]
    [string]$BuildPath,
    [string]$OutDir = ""
)

$ErrorActionPreference = "Stop"

Write-Host "Finding out..."

$ScriptRoot = $PSScriptRoot
$RepoRoot = Join-Path $ScriptRoot "openvino"

if (-not (Test-Path (Join-Path $RepoRoot "CMakeLists.txt"))) {
    throw "OpenVINO repo not found at expected path: $RepoRoot"
}

if ([string]::IsNullOrWhiteSpace($OutDir)) {
    $OutDir = $ScriptRoot
}
New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

$HeaderFile = Join-Path $RepoRoot "src/core/include/openvino/core/version.hpp"
if (-not (Test-Path $HeaderFile)) {
    throw "version.hpp not found at: $HeaderFile"
}

$OVMAJ = Select-String -Path $HeaderFile -Pattern "#define OPENVINO_VERSION_MAJOR" | ForEach-Object { ($_ -split "\s+")[-1] }
if ($OVMAJ.Length -ge 4) { $OVMAJ = $OVMAJ.Substring(2,2) }

$OVMIN = Select-String -Path $HeaderFile -Pattern "#define OPENVINO_VERSION_MINOR" | ForEach-Object { ($_ -split "\s+")[-1] }

$now = Get-Date
$WW = [System.Globalization.CultureInfo]::InvariantCulture.Calendar.GetWeekOfYear(
    $now,
    [System.Globalization.CalendarWeekRule]::FirstFourDayWeek,
    [DayOfWeek]::Monday
)
$D = [int]$now.DayOfWeek
if ($D -eq 0) { $D = 7 }
$STAMP = "$WW.$D"

Push-Location $RepoRoot
try { $GITHEAD = (git rev-parse --short HEAD).Trim() }
finally { Pop-Location }

if (-not [string]::IsNullOrEmpty($Tag)) { $Tag = "_$Tag" }

$FNAME = "OV${OVMAJ}${OVMIN}_NPUW_WW${STAMP}_${GITHEAD}$Tag.zip"
$DestZip = Join-Path $OutDir $FNAME

Write-Host "Compressing $DestZip..."
if (-not (Test-Path $BuildPath)) { throw "BuildPath does not exist: $BuildPath" }

Compress-Archive -Path $BuildPath -DestinationPath $DestZip -Force
Write-Host "Packaging complete: $DestZip"
exit 0
