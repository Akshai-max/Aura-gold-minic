# Stream only [API] lines from the device (run while the app is starting or already open).
Write-Host "API logs only — Ctrl+C to stop" -ForegroundColor Cyan
adb logcat -c 2>$null | Out-Null
adb logcat flutter:I *:S 2>&1 | ForEach-Object {
    $line = "$_"
    if ($line -match '\[API\]') {
        Write-Output $line
    }
}
