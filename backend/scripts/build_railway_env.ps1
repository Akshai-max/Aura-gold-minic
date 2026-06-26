# Builds backend/.env.railway from backend/.env for Railway Variables (RAW editor).
# Usage:  cd backend; .\scripts\build_railway_env.ps1

$ErrorActionPreference = "Stop"
$backendRoot = Split-Path $PSScriptRoot -Parent
$source = Join-Path $backendRoot ".env"
$target = Join-Path $backendRoot ".env.railway"

if (-not (Test-Path $source)) {
    Write-Error "Missing .env - copy .env.example to .env first."
}

$skipKeys = @(
    "POSTGRES_SERVER", "POSTGRES_USER", "POSTGRES_PASSWORD",
    "POSTGRES_DB", "POSTGRES_PORT", "DATABASE_URL",
    "RUN_SMOKE_TESTS", "SIGNUP_OTP_DEV_CODE"
)

$lines = Get-Content $source
$out = New-Object System.Collections.Generic.List[string]
$out.Add("# Generated for Railway - do NOT commit.")
$out.Add("# Add PostgreSQL in Railway, then set DATABASE_URL = Postgres reference.")
$out.Add("")
$out.Add("ENVIRONMENT=production")
$out.Add("PAYMENT_DEV_MOCK=false")
$out.Add("TRUSTED_PROXY=true")
$out.Add("")

$secretKey = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 48 | ForEach-Object { [char]$_ })

foreach ($line in $lines) {
    $trimmed = $line.Trim()
    if ($trimmed -eq "" -or $trimmed.StartsWith("#")) { continue }
    $eq = $trimmed.IndexOf("=")
    if ($eq -lt 1) { continue }
    $key = $trimmed.Substring(0, $eq)
    if ($skipKeys -contains $key) { continue }
    if ($key -eq "SECRET_KEY") {
        $out.Add("SECRET_KEY=$secretKey")
        continue
    }
    if ($key -eq "ENVIRONMENT") { continue }
    $out.Add($trimmed)
}

$out | Set-Content -Path $target -Encoding utf8
Write-Host "Wrote $target"
Write-Host "Railway: API service -> Variables -> RAW -> paste .env.railway"
Write-Host "Then add DATABASE_URL referencing your Postgres service."
