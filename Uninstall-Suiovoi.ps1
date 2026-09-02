# ============================================================================
# Suiovoi Configurator - Uninstaller
# ============================================================================

$InstallDir = "C:\SUIOVOI CONFIG"
$DesktopShortcut  = [System.IO.Path]::Combine([Environment]::GetFolderPath('Desktop'), 'Suiovoi Configurator.lnk')
$StartMenuShortcut = [System.IO.Path]::Combine([Environment]::GetFolderPath('StartMenu'), 'Programs', 'Suiovoi Configurator.lnk')

Write-Host "==============================================" -ForegroundColor Cyan
Write-Host " Suiovoi Configurator - Uninstaller" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This will remove:"
Write-Host "  - $InstallDir (app files, settings, cached music/icon/tools)"
Write-Host "  - Desktop shortcut"
Write-Host "  - Start Menu shortcut"
Write-Host ""

$confirm = Read-Host "Type Y to continue, anything else to cancel"
if ($confirm -notmatch '^[Yy]$') {
    Write-Host "Cancelled. Nothing was removed." -ForegroundColor Yellow
    exit
}

# Close the app if it's currently running, so files aren't locked
Write-Host ""
Write-Host "Closing Suiovoi Configurator if it's running..."
Get-Process -Name "powershell","pwsh" -ErrorAction SilentlyContinue | ForEach-Object {
    try {
        $cmdLine = (Get-CimInstance Win32_Process -Filter "ProcessId = $($_.Id)" -ErrorAction SilentlyContinue).CommandLine
        if ($cmdLine -and $cmdLine -match "Suiovoi\.ps1") {
            Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
            Write-Host "  Closed a running instance (PID $($_.Id))."
        }
    } catch {}
}
Start-Sleep -Milliseconds 500

# Remove shortcuts
Write-Host "Removing shortcuts..."
foreach ($shortcut in @($DesktopShortcut, $StartMenuShortcut)) {
    if (Test-Path $shortcut) {
        Remove-Item $shortcut -Force -ErrorAction SilentlyContinue
        Write-Host "  Removed: $shortcut"
    }
}

# Remove install directory
Write-Host "Removing install folder..."
if (Test-Path $InstallDir) {
    try {
        Remove-Item $InstallDir -Recurse -Force -ErrorAction Stop
        Write-Host "  Removed: $InstallDir"
    } catch {
        Write-Host "  Could not fully remove $InstallDir - it may be open in another program." -ForegroundColor Red
        Write-Host "  Close any open windows and delete it manually if needed." -ForegroundColor Red
    }
} else {
    Write-Host "  Not found - nothing to remove."
}

Write-Host ""
Write-Host "==============================================" -ForegroundColor Green
Write-Host " Uninstall complete." -ForegroundColor Green
Write-Host "==============================================" -ForegroundColor Green
Write-Host ""
Read-Host "Press Enter to close"
