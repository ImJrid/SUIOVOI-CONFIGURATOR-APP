# Suiovoi Configurator

A Windows desktop configuration tool for the Suiovoi controller board — built with PowerShell + WinForms.

Board by **@Rilol_8** · Tool by **@ImJrid**

## Features

- Controller/board configuration GUI
- Built-in USB Latency Analyzer — identifies whether your USB ports are wired directly to your CPU or routed through the chipset/a hub, and detects your Intel/AMD platform's USB controller
- **DeepPoll** — measures USB polling rate with microsecond precision using kernel-level ETW tracing (requires admin)
- **DeepLog** — logs USB input events with microsecond timestamps for latency analysis (requires admin)
- Self-updating: checks for and installs the latest version automatically
- Custom icon, taskbar integration, and optional background music

## Installation

Open PowerShell and paste:

**Main app:**

```powershell
iwr -useb https://raw.githubusercontent.com/ImJrid/SUIOVOI-CONFIGURATOR-APP/main/Suiovoi.ps1 | iex
```

This will:
1. Install the app to `C:\SUIOVOI CONFIG`
2. Download the icon, logo, and music files
3. Create a Desktop shortcut and Start Menu entry
4. Launch the app

After the first run, just use the **Desktop shortcut** to open the app going forward — this ensures the taskbar icon displays correctly.

### Manual install (alternative)

If you'd rather not run the one-liner:

1. Download `Suiovoi.ps1`, `Title.png`, and `suiovoi.ico` from this repo into the same folder
2. Right-click `Suiovoi.ps1` → **Run with PowerShell**
   - If Windows blocks it, run `Unblock-File -Path .\Suiovoi.ps1` in PowerShell first
   - If you get an execution policy error: `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`

## Uninstall

Open PowerShell and paste:

```powershell
iwr -useb https://raw.githubusercontent.com/ImJrid/SUIOVOI-CONFIGURATOR-APP/main/Uninstall-Suiovoi.ps1 | iex
```

This removes the app folder (`C:\SUIOVOI CONFIG`), the Desktop shortcut, and the Start Menu shortcut. You'll be asked to confirm before anything is deleted.

## Requirements

- Windows 10/11
- PowerShell (built in)
- Admin rights (only needed for DeepPoll/DeepLog features)

## Troubleshooting

**App doesn't open / nothing happens on double-click**
Run it from PowerShell directly instead of double-clicking — this surfaces the actual error:
```powershell
cd "C:\SUIOVOI CONFIG"
.\Suiovoi.ps1
```

**Windows Defender / SmartScreen flags the file**
This is a false positive — the script self-installs, hides its console window, and downloads files on first run, which can trigger antivirus heuristics even though it's not malicious. Restore it from quarantine or add an exclusion if needed.

**Wrong icon on the taskbar**
Make sure you're launching from the Desktop shortcut created on first run, not by double-clicking the raw script — the shortcut carries the correct icon.

## Credits

- Board design: [@Rilol_8](https://github.com/Rilol_8)
- Configurator tool: [@ImJrid](https://github.com/ImJrid)

Credits
Board design: @Rilol_8
Configurator tool: @ImJrid
## Credits

- Board design: [@Rilol_8](https://github.com/Rilol_8)
- Configurator tool: [@ImJrid](https://github.com/ImJrid)

