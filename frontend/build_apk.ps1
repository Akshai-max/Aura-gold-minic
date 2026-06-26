# Build release APK for installing on another Android phone (same Wi-Fi as backend PC).
param(
    [string]$ApiBaseUrl = "http://192.168.0.9:8000/api/v1"
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

Write-Host "Building release APK..." -ForegroundColor Cyan
Write-Host "API: $ApiBaseUrl" -ForegroundColor DarkGray

flutter build apk --release `
    --dart-define=API_BASE_URL=$ApiBaseUrl `
    --dart-define=API_LOGS_ONLY=false

$apk = Join-Path $PSScriptRoot "build\app\outputs\flutter-apk\app-release.apk"
if (Test-Path $apk) {
    Write-Host ""
    Write-Host "APK ready:" -ForegroundColor Green
    Write-Host $apk
    Write-Host ""
    Write-Host "Copy this file to the other phone and install it." -ForegroundColor Cyan
    Write-Host "Both phones must use the same Wi-Fi; backend must run on 192.168.0.9:8000" -ForegroundColor DarkGray
} else {
    Write-Error "APK was not created."
}
