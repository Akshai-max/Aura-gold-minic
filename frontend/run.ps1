# Single command: flutter run on device; console shows [API] and [APP_EVENT] lines.
param(
    [string]$Device = "192.168.0.12:42889",
    [string]$ApiBaseUrl = "http://192.168.0.9:8000/api/v1"
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

flutter run `
    -d $Device `
    --dart-define=API_BASE_URL=$ApiBaseUrl `
    --dart-define=API_LOGS_ONLY=true `
    2>&1 | ForEach-Object {
        $line = "$_"
        if ($line -match '\[API\]' -or $line -match '\[APP_EVENT\]') {
            Write-Output $line
        }
    }
