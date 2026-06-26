# Build Android App Bundle (.aab) for Google Play Store upload.
param(
    [string]$ApiBaseUrl = "https://api.agsgold.com/api/v1"
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

Write-Host "Building app bundle (AAB)..." -ForegroundColor Cyan
Write-Host "API: $ApiBaseUrl" -ForegroundColor DarkGray

flutter build appbundle --release --dart-define=API_BASE_URL=$ApiBaseUrl

$aab = Join-Path $PSScriptRoot "build\app\outputs\bundle\release\app-release.aab"
if (Test-Path $aab) {
    Write-Host ""
    Write-Host "AAB ready:" -ForegroundColor Green
    Write-Host $aab
} else {
    Write-Error "AAB was not created."
}
