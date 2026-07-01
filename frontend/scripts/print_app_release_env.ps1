# Reads frontend/pubspec.yaml and prints backend env vars for in-app updates.
$ErrorActionPreference = "Stop"

$pubspecPath = Join-Path $PSScriptRoot "..\pubspec.yaml"
if (-not (Test-Path $pubspecPath)) {
    Write-Error "pubspec.yaml not found at $pubspecPath"
}

$versionLine = Get-Content $pubspecPath | Where-Object { $_ -match '^version:\s*' } | Select-Object -First 1
if (-not $versionLine) {
    Write-Error "version line not found in pubspec.yaml"
}

$version = ($versionLine -split '\s+', 2)[1].Trim()
$name, $code = $version.Split('+', 2)
if (-not $code) { $code = "1" }

Write-Host "Set these on Railway / backend .env after publishing a new APK:" -ForegroundColor Cyan
Write-Host ""
Write-Host "APP_ANDROID_VERSION_NAME=$name"
Write-Host "APP_ANDROID_VERSION_CODE=$code"
Write-Host "APP_ANDROID_APK_URL=https://github.com/Akshai-max/Aura-gold-minic/releases/download/v$name/app-release.apk"
Write-Host "APP_ANDROID_RELEASE_NOTES=Describe what changed in this release"
Write-Host "APP_ANDROID_FORCE_UPDATE=false"
Write-Host ""
Write-Host "Tip: bump pubspec version (+N) before each release build." -ForegroundColor DarkGray
