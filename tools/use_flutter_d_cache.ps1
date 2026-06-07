$ErrorActionPreference = "Stop"

$flutterRoot = "D:\flutter"
$projectRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)

$env:FLUTTER_ROOT = $flutterRoot
$env:PUB_CACHE = Join-Path $flutterRoot ".pub-cache"
$env:GRADLE_USER_HOME = Join-Path $flutterRoot ".gradle"
$env:APPDATA = Join-Path $flutterRoot ".dart_appdata"
$env:LOCALAPPDATA = Join-Path $flutterRoot ".dart_localappdata"

$requiredDirs = @(
    $env:PUB_CACHE,
    $env:GRADLE_USER_HOME,
    $env:APPDATA,
    $env:LOCALAPPDATA
)

foreach ($dir in $requiredDirs) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
}

$oldPubCache = Join-Path $projectRoot ".pub-cache"
if (Test-Path $oldPubCache) {
    robocopy $oldPubCache $env:PUB_CACHE /E /R:1 /W:1 /NFL /NDL /NJH /NJS /NP
    if ($LASTEXITCODE -gt 7) {
        throw "robocopy failed while copying Pub cache with exit code $LASTEXITCODE"
    }
}

$oldGradleCache = Join-Path $projectRoot ".gradle"
if (Test-Path $oldGradleCache) {
    robocopy $oldGradleCache $env:GRADLE_USER_HOME /E /XF "*.lock" /R:1 /W:1 /NFL /NDL /NJH /NJS /NP
    if ($LASTEXITCODE -gt 7) {
        throw "robocopy failed while copying Gradle cache with exit code $LASTEXITCODE"
    }
}

Set-Location $projectRoot
& (Join-Path $flutterRoot "bin\flutter.bat") --no-version-check pub get
& (Join-Path $flutterRoot "bin\flutter.bat") --no-version-check doctor -v
