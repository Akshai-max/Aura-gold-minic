# Run on device; terminal shows ONLY [API] lines (no FlutterJNI / install noise).
param(
    [string]$Device = "192.168.0.12:42889",
    [string]$ApiBaseUrl = "http://192.168.0.9:8000/api/v1"
)

& (Join-Path $PSScriptRoot "..\run.ps1") -Device $Device -ApiBaseUrl $ApiBaseUrl

