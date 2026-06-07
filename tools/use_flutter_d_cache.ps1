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

$flutterGradleSettings = Join-Path $flutterRoot "packages\flutter_tools\gradle\settings.gradle.kts"
if (Test-Path $flutterGradleSettings) {
    $settingsText = Get-Content $flutterGradleSettings -Raw
    $settingsText = $settingsText.Replace(
        "repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)",
        "repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)"
    )
    Set-Content -Path $flutterGradleSettings -Value $settingsText -NoNewline
}

Set-Location $projectRoot
& (Join-Path $flutterRoot "bin\flutter.bat") --no-version-check pub get
& (Join-Path $flutterRoot "bin\flutter.bat") --no-version-check doctor -v
