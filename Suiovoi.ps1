

# ============================================================================
# INSTALL PATHS
# ============================================================================
$script:CurrentVersion = "1"
$script:InstallDir     = "C:\SUIOVOI CONFIG"
$script:InstallPath    = "$script:InstallDir\Suiovoi.ps1"
$script:ScriptUrl      = "https://raw.githubusercontent.com/ImJrid/SUIOVOI-CONFIGURATOR-APP/main/Suiovoi.ps1"
$script:ReleasesApi    = "https://api.github.com/repos/ImJrid/SUIOVOI-CONFIGURATOR-APP/releases/latest"
$script:SettingsPath   = "$script:InstallDir\Settings.ini"
$script:MusicPath      = "$script:InstallDir\MMusic.mp3"
$script:MusicUrl       = "https://raw.githubusercontent.com/ImJrid/SUIOVOI-CONFIGURATOR-APP/main/MMusic.mp3"
$script:IconInstallPath = "$script:InstallDir\Suiovoi.ico"
$script:IconUrl         = "https://raw.githubusercontent.com/ImJrid/SUIOVOI-CONFIGURATOR-APP/main/suiovoi.ico"
$script:LogoInstallPath = "$script:InstallDir\Title.png"
$script:LogoUrl         = "https://raw.githubusercontent.com/ImJrid/SUIOVOI-CONFIGURATOR-APP/main/Title.png"

# Tracks hover state per tile control (main tiles, toolbox tiles, exit tile).
# Initialized here, at the top of the script, so it always exists before any
# control's MouseEnter/MouseLeave/Paint handler can possibly reference it.
$script:suiovoiHover = @{}



function Install-SuiovoiIcon {
    # Resolves a local path to Suiovoi.ico, trying (in order):
    #   1. Next to the running script (so a bundled .ico is picked up as-is)
    #   2. Already cached in the install dir from a previous run
    #   3. Downloaded fresh into the install dir
    # Returns the resolved path, or $null if none of those worked.
    try {
        $besideScript = $null
        if ($MyInvocation.PSCommandPath) {
            $besideScript = [System.IO.Path]::Combine((Split-Path $MyInvocation.PSCommandPath -Parent), "Suiovoi.ico")
        }
        if ($besideScript -and (Test-Path $besideScript)) {
            return $besideScript
        }

        if (Test-Path $script:IconInstallPath) {
            return $script:IconInstallPath
        }

        if (-not (Test-Path $script:InstallDir)) {
            New-Item -ItemType Directory -Path $script:InstallDir -Force | Out-Null
        }
        $wc = New-Object System.Net.WebClient
        $wc.DownloadFile($script:IconUrl, $script:IconInstallPath)
        if ((Get-Item $script:IconInstallPath -ErrorAction SilentlyContinue).Length -gt 0) {
            return $script:IconInstallPath
        }
        Remove-Item $script:IconInstallPath -Force -ErrorAction SilentlyContinue
        return $null
    } catch {
        return $null
    }
}

function Install-SuiovoiLogo {
    # Resolves a local path to Title.png, trying (in order):
    #   1. Next to the running script (so a bundled Title.png is picked up as-is)
    #   2. Already cached in the install dir from a previous run
    #   3. Downloaded fresh into the install dir
    # Returns the resolved path, or $null if none of those worked.
    try {
        $besideScript = $null
        if ($MyInvocation.PSCommandPath) {
            $besideScript = [System.IO.Path]::Combine((Split-Path $MyInvocation.PSCommandPath -Parent), "Title.png")
        }
        if ($besideScript -and (Test-Path $besideScript)) {
            return $besideScript
        }

        if (Test-Path $script:LogoInstallPath) {
            return $script:LogoInstallPath
        }

        if (-not (Test-Path $script:InstallDir)) {
            New-Item -ItemType Directory -Path $script:InstallDir -Force | Out-Null
        }
        $wc = New-Object System.Net.WebClient
        $wc.DownloadFile($script:LogoUrl, $script:LogoInstallPath)
        if ((Get-Item $script:LogoInstallPath -ErrorAction SilentlyContinue).Length -gt 0) {
            return $script:LogoInstallPath
        }
        Remove-Item $script:LogoInstallPath -Force -ErrorAction SilentlyContinue
        return $null
    } catch {
        return $null
    }
}

function Install-DesktopShortcut {
    param([string]$IconPath)
    try {
        $shortcutPath = [System.IO.Path]::Combine(
            [Environment]::GetFolderPath('Desktop'),
            'Suiovoi Configurator.lnk'
        )
        if (Test-Path $shortcutPath) { return }  # Already exists - don't recreate

        $wsh = New-Object -ComObject WScript.Shell
        $sc  = $wsh.CreateShortcut($shortcutPath)
        $sc.TargetPath       = "powershell.exe"
        $sc.Arguments        = "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$script:InstallPath`""
        $sc.WorkingDirectory = $script:InstallDir
        $sc.Description      = "Suiovoi Configurator v$script:CurrentVersion"
        if ($IconPath -and (Test-Path $IconPath)) {
            $sc.IconLocation = "$IconPath,0"
        }
        $sc.WindowStyle = 7  # Minimized - hides the PowerShell flash
        $sc.Save()
    } catch {}
}

function Install-StartMenuShortcut {
    param([string]$IconPath)
    try {
        $startMenuDir = [System.IO.Path]::Combine(
            [Environment]::GetFolderPath('StartMenu'),
            'Programs'
        )
        if (-not (Test-Path $startMenuDir)) {
            New-Item -ItemType Directory -Path $startMenuDir -Force | Out-Null
        }
        $shortcutPath = [System.IO.Path]::Combine($startMenuDir, 'Suiovoi Configurator.lnk')
        if (Test-Path $shortcutPath) { return }  # Already exists - don't recreate

        $wsh = New-Object -ComObject WScript.Shell
        $sc  = $wsh.CreateShortcut($shortcutPath)
        $sc.TargetPath       = "powershell.exe"
        $sc.Arguments        = "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$script:InstallPath`""
        $sc.WorkingDirectory = $script:InstallDir
        $sc.Description      = "Suiovoi Configurator v$script:CurrentVersion"
        if ($IconPath -and (Test-Path $IconPath)) {
            $sc.IconLocation = "$IconPath,0"
        }
        $sc.WindowStyle = 7  # Minimized - hides the PowerShell flash
        $sc.Save()
    } catch {}
}

function Invoke-SelfInstall {
    # Install script to %APPDATA%\MARIUS - uses temp file to prevent corruption
    try {
        if (-not (Test-Path $script:InstallDir)) {
            New-Item -ItemType Directory -Path $script:InstallDir -Force | Out-Null
        }
        $runningPath = $MyInvocation.ScriptName
        # If running from a real file (not via | iex), copy it directly
        if ($runningPath -and ($runningPath -ne $script:InstallPath) -and (Test-Path $runningPath)) {
            $sourceSize = (Get-Item $runningPath).Length
            if ($sourceSize -gt 10000) {
                Copy-Item -Path $runningPath -Destination $script:InstallPath -Force -ErrorAction SilentlyContinue
            }
        }
        # If AppData file still does not exist, download a clean copy
        if (-not (Test-Path $script:InstallPath)) {
            $wc = New-Object System.Net.WebClient
            $wc.Headers.Add("Cache-Control", "no-cache")
            $tempPath = "$script:InstallPath.tmp"
            $wc.DownloadFile($script:ScriptUrl, $tempPath)
            $tempSize = (Get-Item $tempPath).Length
            if ($tempSize -gt 10000) {
                Move-Item -Path $tempPath -Destination $script:InstallPath -Force
            } else {
                Remove-Item $tempPath -Force -ErrorAction SilentlyContinue
            }
        }
    } catch {}
}

# Hide PowerShell window
Add-Type -Name Window -Namespace Console -MemberDefinition '
[DllImport("Kernel32.dll")]
public static extern IntPtr GetConsoleWindow();
[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
' -ErrorAction SilentlyContinue
$consolePtr = [Console.Window]::GetConsoleWindow()
[Console.Window]::ShowWindow($consolePtr, 0) | Out-Null

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ============================================================================
# GLOBAL CRASH GUARD
# ============================================================================
# Without this, any unhandled exception inside a Button/Paint event handler
# (anywhere in the app) surfaces as the default ".NET Framework - Unhandled
# exception has occurred" dialog and can tear the whole app down. This turns
# that into a normal, readable message box instead, and lets the app keep
# running. Must be set before any Form is shown.
try {
    [System.Windows.Forms.Application]::SetUnhandledExceptionMode([System.Windows.Forms.UnhandledExceptionMode]::CatchException)
} catch {}
[System.Windows.Forms.Application]::add_ThreadException({
    param($sender, $e)
    try {
        [System.Windows.Forms.MessageBox]::Show(
            "Something went wrong, but Suiovoi Configurator will keep running.`n`n$($e.Exception.GetType().FullName)`n$($e.Exception.Message)",
            "Suiovoi Configurator - Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
    } catch {}
})

# ============================================================================
# DEVICE DATABASES FOR USB ANALYZER
# ============================================================================

$script:IntelCpuIntegrated = @{
    '8a13' = @{ Name = "Ice Lake TB3"; Platform = "10th Gen"; USB = "USB 3.2/TB3" }
    '9a13' = @{ Name = "Tiger Lake-LP TB4"; Platform = "11th Gen"; USB = "USB4/TB4" }
    '9a17' = @{ Name = "Tiger Lake-H TB4"; Platform = "11th Gen"; USB = "USB4/TB4" }
    '461e' = @{ Name = "Alder Lake-P TB4"; Platform = "12th Gen"; USB = "USB4/TB4" }
    '464e' = @{ Name = "Alder Lake-N USB 3.2"; Platform = "Alder Lake-N"; USB = "USB 3.2" }
    'a71e' = @{ Name = "Raptor Lake-P TB4"; Platform = "13th Gen"; USB = "USB4/TB4" }
    '7ec0' = @{ Name = "Meteor Lake-P TB4"; Platform = "Core Ultra"; USB = "USB4/TB4" }
    'a831' = @{ Name = "Lunar Lake TB4"; Platform = "Lunar Lake"; USB = "USB4/TB4" }
}

$script:IntelPch = @{
    '7f6e' = @{ Name = "800 Series PCH USB 3.1"; Platform = "800 Series"; USB = "USB 3.1" }
    '7a60' = @{ Name = "Raptor Lake USB 3.2 Gen 2x2"; Platform = "700 Series"; USB = "20Gbps" }
    '7ae0' = @{ Name = "Alder Lake-S USB 3.2 Gen 2x2"; Platform = "600 Series"; USB = "20Gbps" }
    '51ed' = @{ Name = "Alder Lake USB 3.2"; Platform = "600 Series"; USB = "USB 3.2" }
    '54ed' = @{ Name = "Alder Lake-N USB 3.2 Gen 2"; Platform = "Alder Lake-N"; USB = "10Gbps" }
    '7e7d' = @{ Name = "Meteor Lake USB 3.2 Gen 2"; Platform = "Meteor Lake"; USB = "USB 3.2" }
    'a0ed' = @{ Name = "Tiger Lake-LP USB 3.2 Gen 2"; Platform = "500 Series"; USB = "10Gbps" }
    '43ed' = @{ Name = "Tiger Lake-H USB 3.2 Gen 2"; Platform = "500 Series"; USB = "USB 3.2" }
    '02ed' = @{ Name = "Comet Lake USB 3.1"; Platform = "400 Series"; USB = "USB 3.1" }
    '06ed' = @{ Name = "Comet Lake USB 3.1"; Platform = "400 Series"; USB = "USB 3.1" }
    'a36d' = @{ Name = "Cannon Lake USB 3.1"; Platform = "300 Series"; USB = "USB 3.1" }
    '9ded' = @{ Name = "Cannon Point-LP USB 3.1"; Platform = "300 Series"; USB = "USB 3.1" }
    'a2af' = @{ Name = "200/Z370 USB 3.0"; Platform = "200 Series"; USB = "USB 3.0" }
    'a12f' = @{ Name = "100/C230 USB 3.0"; Platform = "100 Series"; USB = "USB 3.0" }
    '9d2f' = @{ Name = "Sunrise Point-LP USB 3.0"; Platform = "100 Series"; USB = "USB 3.0" }
    '8cb1' = @{ Name = "9 Series USB"; Platform = "9 Series"; USB = "USB 3.0" }
    '8c31' = @{ Name = "8 Series USB"; Platform = "8 Series"; USB = "USB 3.0" }
    '1e31' = @{ Name = "7 Series USB"; Platform = "7 Series"; USB = "USB 3.0" }
}

$script:IntelThunderbolt = @{
    '5782' = @{ Name = "JHL9580 TB5 (80Gbps)"; Platform = "Barlow Ridge"; USB = "USB4/TB5" }
    '5785' = @{ Name = "JHL9540 TB4 (40Gbps)"; Platform = "Barlow Ridge"; USB = "USB4/TB4" }
    '1138' = @{ Name = "TB4 [Maple Ridge 4C]"; Platform = "Maple Ridge"; USB = "USB4/TB4" }
    '1135' = @{ Name = "TB4 [Maple Ridge 2C]"; Platform = "Maple Ridge"; USB = "USB4/TB4" }
    '0b27' = @{ Name = "TB4 [Goshen Ridge]"; Platform = "Goshen Ridge"; USB = "USB4/TB4" }
    '15e9' = @{ Name = "JHL7540 TB3 [Titan Ridge]"; Platform = "Titan Ridge"; USB = "USB 3.1/TB3" }
    '15b5' = @{ Name = "DSL6340 USB 3.1 [Alpine Ridge]"; Platform = "Alpine Ridge"; USB = "USB 3.1/TB3" }
}

$script:AmdCpuIntegrated = @{
    '15b6' = @{ Name = "Raphael/Granite Ridge USB 3.1"; Platform = "Ryzen 7000/9000 (AM5)"; USB = "USB 3.1" }
    '15b7' = @{ Name = "Raphael/Granite Ridge USB 3.1"; Platform = "Ryzen 7000/9000 (AM5)"; USB = "USB 3.1" }
    '1587' = @{ Name = "Strix Halo USB 3.1"; Platform = "Strix Halo (Zen 5)"; USB = "USB 3.1" }
    '158d' = @{ Name = "Strix Halo USB4"; Platform = "Strix Halo (Zen 5)"; USB = "USB4" }
    '161a' = @{ Name = "Rembrandt USB4"; Platform = "Ryzen 6000 Mobile"; USB = "USB4" }
    '161b' = @{ Name = "Rembrandt USB4"; Platform = "Ryzen 6000 Mobile"; USB = "USB4" }
    '15c4' = @{ Name = "Phoenix USB4/TB"; Platform = "Ryzen 7040 Mobile"; USB = "USB4/TB" }
    '1639' = @{ Name = "Renoir/Cezanne USB 3.1"; Platform = "Ryzen 4000/5000 APU"; USB = "USB 3.1" }
    '15e0' = @{ Name = "Raven USB 3.1"; Platform = "Ryzen 2000 APU"; USB = "USB 3.1" }
    '149c' = @{ Name = "Matisse USB 3.0"; Platform = "Ryzen 3000/5000 Desktop"; USB = "USB 3.0" }
    '145f' = @{ Name = "Zeppelin USB 3.0"; Platform = "Ryzen 1000 (Zen)"; USB = "USB 3.0" }
    '163a' = @{ Name = "VanGogh USB0"; Platform = "Steam Deck"; USB = "USB 3.1" }
}

$script:AmdChipset = @{
    '43fc' = @{ Name = "800 Series USB 3.x"; Platform = "X870/B850 (AM5)"; USB = "USB 3.2" }
    '43f7' = @{ Name = "600 Series USB 3.2"; Platform = "X670/B650 (AM5)"; USB = "USB 3.2" }
    '43ee' = @{ Name = "500 Series USB 3.1"; Platform = "X570/B550 (AM4)"; USB = "USB 3.1" }
    '43ec' = @{ Name = "A520 USB 3.1"; Platform = "A520 (AM4)"; USB = "USB 3.1" }
    '43d5' = @{ Name = "400 Series USB 3.1"; Platform = "X470/B450 (AM4)"; USB = "USB 3.1" }
    '43b9' = @{ Name = "X370 USB 3.1"; Platform = "X370 (AM4)"; USB = "USB 3.1" }
    '43ba' = @{ Name = "X399 USB 3.1"; Platform = "X399 (TR)"; USB = "USB 3.1" }
    '7814' = @{ Name = "FCH USB XHCI"; Platform = "Legacy FCH"; USB = "USB 3.0" }
}

$script:ThirdParty = @{
    '1b21_1042' = @{ Name = "ASM1042 USB 3.0"; Vendor = "ASMedia"; USB = "USB 3.0" }
    '1b21_1142' = @{ Name = "ASM1042A USB 3.0"; Vendor = "ASMedia"; USB = "USB 3.0" }
    '1b21_1242' = @{ Name = "ASM1142 USB 3.1"; Vendor = "ASMedia"; USB = "USB 3.1 Gen 2" }
    '1b21_3242' = @{ Name = "ASM3242 USB 3.2"; Vendor = "ASMedia"; USB = "USB 3.2 Gen 2x2" }
    '1106_3483' = @{ Name = "VL805/806 USB 3.0"; Vendor = "VIA"; USB = "USB 3.0" }
    '1912_0014' = @{ Name = "uPD720201 USB 3.0"; Vendor = "Renesas"; USB = "USB 3.0" }
    '1912_0015' = @{ Name = "uPD720202 USB 3.0"; Vendor = "Renesas"; USB = "USB 3.0" }
}

# ============================================================================
# USB ANALYZER HELPER FUNCTIONS
# ============================================================================

function Get-ControllerInfo {
    param([string]$Vid, [string]$Did)
    
    $vid = $Vid.ToLower()
    $did = $Did.ToLower()
    $key = "${vid}_${did}"
    
    if ($vid -eq '8086' -and $script:IntelCpuIntegrated.ContainsKey($did)) {
        $d = $script:IntelCpuIntegrated[$did]
        return @{ Type = "CPU"; ChipCount = 0; Name = $d.Name; Platform = $d.Platform; USB = $d.USB }
    }
    if ($vid -eq '8086' -and $script:IntelThunderbolt.ContainsKey($did)) {
        $d = $script:IntelThunderbolt[$did]
        return @{ Type = "TB"; ChipCount = 0; Name = $d.Name; Platform = $d.Platform; USB = $d.USB }
    }
    if ($vid -eq '8086' -and $script:IntelPch.ContainsKey($did)) {
        $d = $script:IntelPch[$did]
        return @{ Type = "CHIPSET"; ChipCount = 1; Name = $d.Name; Platform = $d.Platform; USB = $d.USB }
    }
    if ($vid -eq '1022' -and $script:AmdCpuIntegrated.ContainsKey($did)) {
        $d = $script:AmdCpuIntegrated[$did]
        return @{ Type = "CPU"; ChipCount = 0; Name = $d.Name; Platform = $d.Platform; USB = $d.USB }
    }
    if ($vid -eq '1022' -and $script:AmdChipset.ContainsKey($did)) {
        $d = $script:AmdChipset[$did]
        return @{ Type = "CHIPSET"; ChipCount = 1; Name = $d.Name; Platform = $d.Platform; USB = $d.USB }
    }
    if ($script:ThirdParty.ContainsKey($key)) {
        $d = $script:ThirdParty[$key]
        return @{ Type = "ADDON"; ChipCount = 1; Name = $d.Name; Platform = $d.Vendor; USB = $d.USB }
    }
    
    if ($vid -eq '8086') {
        return @{ Type = "CHIPSET"; ChipCount = 1; Name = "Intel USB Controller"; Platform = "PCH"; USB = "USB 3.x" }
    }
    if ($vid -eq '1022') {
        return @{ Type = "CHIPSET"; ChipCount = 1; Name = "AMD USB Controller"; Platform = "Chipset"; USB = "USB 3.x" }
    }
    
    return @{ Type = "UNKNOWN"; ChipCount = 1; Name = "Unknown Controller"; Platform = "Unknown"; USB = "?" }
}

function Get-DeviceChain {
    param([string]$InstanceId)
    
    $result = @{ ControllerInfo = $null; HubCount = 0; ChipCount = 0 }
    $currentId = $InstanceId
    $count = 0
    
    while ($currentId -and $count -lt 15) {
        $count++
        
        try {
            $dev = Get-PnpDevice -InstanceId $currentId -ErrorAction SilentlyContinue
            
            if ($currentId -match "ROOT_HUB") {
                $parent = Get-PnpDeviceProperty -InstanceId $currentId -KeyName "DEVPKEY_Device_Parent" -ErrorAction Stop
                $ctrlId = $parent.Data
                
                if ($ctrlId -match "VEN_([0-9A-F]{4}).*DEV_([0-9A-F]{4})") {
                    $vid = $matches[1]
                    $did = $matches[2]
                    $info = Get-ControllerInfo -Vid $vid -Did $did
                    $result.ControllerInfo = $info
                    $result.ChipCount = $info.ChipCount + $result.HubCount
                    return $result
                }
            }
            
            if ($dev -and $dev.FriendlyName -match "Hub" -and $dev.FriendlyName -notmatch "Root") {
                $result.HubCount++
            }
            
            $parent = Get-PnpDeviceProperty -InstanceId $currentId -KeyName "DEVPKEY_Device_Parent" -ErrorAction Stop
            $currentId = $parent.Data
        } catch {
            break
        }
    }
    
    return $result
}

# ============================================================================
# BROWSER FUNCTIONS
# ============================================================================

function Get-DefaultBrowser {
    try {
        $userChoice = Get-ItemProperty "HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\http\UserChoice" -ErrorAction SilentlyContinue
        $progId = $userChoice.ProgId
        
        if ($progId -match "Chrome") {
            return "Chrome"
        } elseif ($progId -match "Edge") {
            return "Edge"
        } elseif ($progId -match "Brave") {
            return "Brave"
        } elseif ($progId -match "Opera") {
            return "Opera"
        } elseif ($progId -match "Vivaldi") {
            return "Vivaldi"
        } elseif ($progId -match "Arc") {
            return "Arc"
        } else {
            return "Edge"
        }
    } catch {
        return "Edge"
    }
}

function Get-BrowserPath {
    param($browserName)
    
    switch ($browserName) {
        "Edge" {
            $paths = @(
                "$env:ProgramFiles (x86)\Microsoft\Edge\Application\msedge.exe",
                "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe",
                "$env:LOCALAPPDATA\Microsoft\Edge\Application\msedge.exe"
            )
        }
        "Chrome" {
            $paths = @(
                "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
                "$env:ProgramFiles (x86)\Google\Chrome\Application\chrome.exe",
                "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
            )
        }
        "Brave" {
            $paths = @(
                "$env:ProgramFiles\BraveSoftware\Brave-Browser\Application\brave.exe",
                "$env:ProgramFiles (x86)\BraveSoftware\Brave-Browser\Application\brave.exe",
                "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\Application\brave.exe"
            )
        }
        "Opera" {
            $paths = @(
                "$env:ProgramFiles\Opera\opera.exe",
                "$env:ProgramFiles (x86)\Opera\opera.exe",
                "$env:LOCALAPPDATA\Programs\Opera\opera.exe"
            )
        }
        "Vivaldi" {
            $paths = @(
                "$env:ProgramFiles\Vivaldi\Application\vivaldi.exe",
                "$env:ProgramFiles (x86)\Vivaldi\Application\vivaldi.exe",
                "$env:LOCALAPPDATA\Vivaldi\Application\vivaldi.exe"
            )
        }
        "Arc" {
            $paths = @(
                "$env:LOCALAPPDATA\Arc\Application\arc.exe",
                "$env:ProgramFiles\Arc\Application\arc.exe"
            )
        }
        default {
            return $null
        }
    }
    
    return $paths | Where-Object { Test-Path $_ } | Select-Object -First 1
}

# ============================================================================
# USB ANALYZER WINDOW
# ============================================================================

function Show-DeepPoll {
    $script:dpExe = "$script:InstallDir\DeepPoll.exe"
    $dpUrl        = "https://github.com/MariusHeier/deeppoll/releases/latest/download/DeepPoll.exe"
    $dpApiUrl     = "https://api.github.com/repos/MariusHeier/deeppoll/releases/latest"

    # ── Check if an update is available ───────────────────────────────────
    $needDownload = $false
    if (-not (Test-Path $script:dpExe)) {
        $needDownload = $true
    } else {
        $cached = Get-IniToolVer "DeepPoll"
        $actualSize = (Get-Item $script:dpExe).Length

        if ($cached.Size -ge 0 -and $actualSize -ne $cached.Size) {
            # Exe size doesn't match what we recorded — force re-download
            $needDownload = $true
        } else {
            # Size matches (or no record yet) — check GitHub for a newer tag
            try {
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                $wcVer = New-Object System.Net.WebClient
                $wcVer.Headers.Add("User-Agent", "MARIUS-Updater")
                $json      = $wcVer.DownloadString($dpApiUrl)
                $latestTag = (($json -split '"tag_name"\s*:\s*"')[1] -split '"')[0]
                if ($latestTag.Trim() -ne $cached.Tag.Trim()) {
                    $needDownload = $true
                }
            } catch {
                # If version check fails, keep existing exe
            }
        }
    }

    # ── Download / update if needed ────────────────────────────────────────
    if ($needDownload) {

        $script:dlProgress = -1   # -1 = indeterminate, 0-100 = determinate

        # ── Outer form: frameless, yellow 2px border via BackColor ─────────
        $dlForm = New-Object System.Windows.Forms.Form
        $dlForm.Text            = ""
        $dlForm.Size            = New-Object System.Drawing.Size(360, 140)
        $dlForm.StartPosition   = "CenterScreen"
        $dlForm.FormBorderStyle = "None"
        $dlForm.BackColor       = [System.Drawing.Color]::FromArgb(255, 220, 0)
        $dlForm.TopMost         = $false

        # ── Inner dark panel ───────────────────────────────────────────────
        $dlInner = New-Object System.Windows.Forms.Panel
        $dlInner.Location  = New-Object System.Drawing.Point(2, 2)
        $dlInner.Size      = New-Object System.Drawing.Size(356, 136)
        $dlInner.BackColor = [System.Drawing.Color]::FromArgb(10, 10, 10)

        # ── Title ──────────────────────────────────────────────────────────
        $dlTitle = New-Object System.Windows.Forms.Label
        $dlTitle.Text      = "DEEPPOLL"
        $dlTitle.ForeColor = [System.Drawing.Color]::FromArgb(255, 220, 0)
        $dlTitle.Font      = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
        $dlTitle.AutoSize  = $false
        $dlTitle.Size      = New-Object System.Drawing.Size(316, 28)
        $dlTitle.Location  = New-Object System.Drawing.Point(20, 16)
        $dlTitle.TextAlign = "MiddleLeft"

        # ── Subtitle / status line ─────────────────────────────────────────
        $dlSub = New-Object System.Windows.Forms.Label
        $dlSub.Text      = if (Test-Path $script:dpExe) { "Updating DeepPoll.exe..." } else { "Downloading DeepPoll.exe..." }
        $dlSub.ForeColor = [System.Drawing.Color]::FromArgb(160, 160, 160)
        $dlSub.Font      = New-Object System.Drawing.Font("Segoe UI", 7)
        $dlSub.AutoSize  = $false
        $dlSub.Size      = New-Object System.Drawing.Size(316, 16)
        $dlSub.Location  = New-Object System.Drawing.Point(20, 50)
        $dlSub.TextAlign = "MiddleLeft"

        # ── Custom-painted progress track ──────────────────────────────────
        $dlTrack = New-Object System.Windows.Forms.Panel
        $dlTrack.Location  = New-Object System.Drawing.Point(20, 76)
        $dlTrack.Size      = New-Object System.Drawing.Size(268, 6)
        $dlTrack.BackColor = [System.Drawing.Color]::FromArgb(10, 10, 10)

        $dlTrack.Add_Paint({
            param($s, $ev)
            $g   = $ev.Graphics
            $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
            $w   = $s.Width
            $h   = $s.Height
            $pct = $script:dlProgress

            # Track background
            $bg = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(38, 38, 38))
            $g.FillRectangle($bg, 0, 0, $w, $h)
            $bg.Dispose()

            if ($pct -lt 0) {
                # Indeterminate: animated yellow pulse
                $blockW = [int]($w * 0.35)
                $tick   = [int]([System.Environment]::TickCount / 8) % ($w + $blockW)
                $x0     = $tick - $blockW
                $rect   = New-Object System.Drawing.Rectangle($x0, 0, $blockW, $h)
                try {
                    $grad = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
                        $rect,
                        [System.Drawing.Color]::FromArgb(60, 200, 160, 0),
                        [System.Drawing.Color]::FromArgb(255, 220, 0),
                        [System.Drawing.Drawing2D.LinearGradientMode]::Horizontal
                    )
                    $g.FillRectangle($grad, $rect)
                    $grad.Dispose()
                } catch {
                    $fb = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 220, 0))
                    $g.FillRectangle($fb, $rect)
                    $fb.Dispose()
                }
            } else {
                # Determinate fill
                $fillW = [int]($w * $pct / 100.0)
                if ($fillW -gt 0) {
                    $fillRect = New-Object System.Drawing.Rectangle(0, 0, $fillW, $h)
                    try {
                        $fillGrad = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
                            $fillRect,
                            [System.Drawing.Color]::FromArgb(255, 235, 30),
                            [System.Drawing.Color]::FromArgb(200, 170, 0),
                            [System.Drawing.Drawing2D.LinearGradientMode]::Vertical
                        )
                        $g.FillRectangle($fillGrad, $fillRect)
                        $fillGrad.Dispose()
                    } catch {
                        $fb2 = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 220, 0))
                        $g.FillRectangle($fb2, $fillRect)
                        $fb2.Dispose()
                    }
                }
            }
        })

        # ── Percent label (right of bar) ───────────────────────────────────
        $dlPct = New-Object System.Windows.Forms.Label
        $dlPct.Text      = ""
        $dlPct.ForeColor = [System.Drawing.Color]::FromArgb(255, 220, 0)
        $dlPct.Font      = New-Object System.Drawing.Font("Segoe UI", 7, [System.Drawing.FontStyle]::Bold)
        $dlPct.AutoSize  = $false
        $dlPct.Size      = New-Object System.Drawing.Size(48, 14)
        $dlPct.Location  = New-Object System.Drawing.Point(296, 71)
        $dlPct.TextAlign = "MiddleRight"

        # ── KB transferred label ───────────────────────────────────────────
        $dlStatus = New-Object System.Windows.Forms.Label
        $dlStatus.Text      = "Connecting..."
        $dlStatus.ForeColor = [System.Drawing.Color]::FromArgb(75, 75, 75)
        $dlStatus.Font      = New-Object System.Drawing.Font("Segoe UI", 7)
        $dlStatus.AutoSize  = $false
        $dlStatus.Size      = New-Object System.Drawing.Size(316, 14)
        $dlStatus.Location  = New-Object System.Drawing.Point(20, 96)
        $dlStatus.TextAlign = "MiddleLeft"

        # ── Marquee timer (~60 fps repaint) ───────────────────────────────
        $dlTimer = New-Object System.Windows.Forms.Timer
        $dlTimer.Interval = 16
        $dlTimer.Add_Tick({ $dlTrack.Invalidate() })

        $dlInner.Controls.AddRange(@($dlTitle, $dlSub, $dlTrack, $dlPct, $dlStatus))
        $dlForm.Controls.Add($dlInner)
        $dlForm.Show()
        $dlForm.Refresh()

        $script:dlProgress = -1
        $dlTimer.Start()

        # ── Download ───────────────────────────────────────────────────────
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            $wc = New-Object System.Net.WebClient
            $wc.Headers.Add("Cache-Control", "no-cache")

            $wc.add_DownloadProgressChanged({
                param($s, $e)
                if ($e.TotalBytesToReceive -gt 0) {
                    $script:dlProgress = $e.ProgressPercentage
                    $dlTimer.Stop()
                    $recv  = [Math]::Round($e.BytesReceived       / 1KB)
                    $total = [Math]::Round($e.TotalBytesToReceive / 1KB)
                    $dlStatus.Text = "$recv KB  /  $total KB"
                    $dlPct.Text    = "$($e.ProgressPercentage)%"
                } else {
                    $recv          = [Math]::Round($e.BytesReceived / 1KB)
                    $dlStatus.Text = "$recv KB downloaded"
                }
                $dlTrack.Invalidate()
                $dlForm.Refresh()
            })

            $wc.DownloadFile($dpUrl, $script:dpExe)

            # Save version tag + file size into Settings.ini
            try {
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                $wcTag = New-Object System.Net.WebClient
                $wcTag.Headers.Add("User-Agent", "MARIUS-Updater")
                $jsonTag  = $wcTag.DownloadString($dpApiUrl)
                $savedTag = (($jsonTag -split '"tag_name"\s*:\s*"')[1] -split '"')[0]
                $exeSize  = (Get-Item $script:dpExe).Length
                Save-IniToolVer "DeepPoll" $savedTag $exeSize
            } catch {}

            # ── Complete flash ─────────────────────────────────────────────
            $dlTimer.Stop()
            $script:dlProgress = 100
            $dlStatus.Text     = "Complete."
            $dlPct.Text        = "100%"
            $dlSub.Text        = "DeepPoll.exe ready."
            $dlSub.ForeColor   = [System.Drawing.Color]::FromArgb(255, 220, 0)
            $dlTrack.Invalidate()
            $dlForm.Refresh()
            Start-Sleep -Milliseconds 500

        } catch {
            $dlTimer.Stop()
            $dlForm.Close()
            [System.Windows.Forms.MessageBox]::Show(
                "Could not download DeepPoll.`n`nCheck your connection or grab it manually:`nhttps://github.com/MariusHeier/deeppoll/releases`n`n$_",
                "Download Failed",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )
            return
        }
        $dlForm.Close()
    }

    # ── Launch directly, elevated ──────────────────────────────────────────
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName        = "cmd.exe"
    $psi.Arguments       = "/k `"$script:dpExe`""
    $psi.WindowStyle     = [System.Diagnostics.ProcessWindowStyle]::Normal
    $psi.UseShellExecute = $true
    $psi.Verb            = "runas"
    [System.Diagnostics.Process]::Start($psi) | Out-Null
}


function Show-DeepLog {
    $script:dlgExe = "$script:InstallDir\DeepLog.exe"
    $dlgUrl        = "https://github.com/MariusHeier/deeplog/releases/latest/download/DeepLog.exe"
    $dlgApiUrl     = "https://api.github.com/repos/MariusHeier/deeplog/releases/latest"

    # ── Check if an update is available ───────────────────────────────────
    $needDownload = $false
    if (-not (Test-Path $script:dlgExe)) {
        $needDownload = $true
    } else {
        $cached = Get-IniToolVer "DeepLog"
        $actualSize = (Get-Item $script:dlgExe).Length

        if ($cached.Size -ge 0 -and $actualSize -ne $cached.Size) {
            # Exe size doesn't match what we recorded — force re-download
            $needDownload = $true
        } else {
            # Size matches (or no record yet) — check GitHub for a newer tag
            try {
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                $wcVer = New-Object System.Net.WebClient
                $wcVer.Headers.Add("User-Agent", "MARIUS-Updater")
                $json      = $wcVer.DownloadString($dlgApiUrl)
                $latestTag = (($json -split '"tag_name"\s*:\s*"')[1] -split '"')[0]
                if ($latestTag.Trim() -ne $cached.Tag.Trim()) {
                    $needDownload = $true
                }
            } catch {
                # If version check fails, keep existing exe
            }
        }
    }

    # ── Download / update if needed ────────────────────────────────────────
    if ($needDownload) {

        $script:dlProgress = -1   # -1 = indeterminate, 0-100 = determinate

        # ── Outer form: frameless, yellow 2px border via BackColor ─────────
        $dlForm = New-Object System.Windows.Forms.Form
        $dlForm.Text            = ""
        $dlForm.Size            = New-Object System.Drawing.Size(360, 140)
        $dlForm.StartPosition   = "CenterScreen"
        $dlForm.FormBorderStyle = "None"
        $dlForm.BackColor       = [System.Drawing.Color]::FromArgb(255, 220, 0)
        $dlForm.TopMost         = $false

        # ── Inner dark panel ───────────────────────────────────────────────
        $dlInner = New-Object System.Windows.Forms.Panel
        $dlInner.Location  = New-Object System.Drawing.Point(2, 2)
        $dlInner.Size      = New-Object System.Drawing.Size(356, 136)
        $dlInner.BackColor = [System.Drawing.Color]::FromArgb(10, 10, 10)

        # ── Title ──────────────────────────────────────────────────────────
        $dlTitle = New-Object System.Windows.Forms.Label
        $dlTitle.Text      = "DEEPLOG"
        $dlTitle.ForeColor = [System.Drawing.Color]::FromArgb(255, 220, 0)
        $dlTitle.Font      = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
        $dlTitle.AutoSize  = $false
        $dlTitle.Size      = New-Object System.Drawing.Size(316, 28)
        $dlTitle.Location  = New-Object System.Drawing.Point(20, 16)
        $dlTitle.TextAlign = "MiddleLeft"

        # ── Subtitle / status line ─────────────────────────────────────────
        $dlSub = New-Object System.Windows.Forms.Label
        $dlSub.Text      = if (Test-Path $script:dlgExe) { "Updating DeepLog.exe..." } else { "Downloading DeepLog.exe..." }
        $dlSub.ForeColor = [System.Drawing.Color]::FromArgb(160, 160, 160)
        $dlSub.Font      = New-Object System.Drawing.Font("Segoe UI", 7)
        $dlSub.AutoSize  = $false
        $dlSub.Size      = New-Object System.Drawing.Size(316, 16)
        $dlSub.Location  = New-Object System.Drawing.Point(20, 50)
        $dlSub.TextAlign = "MiddleLeft"

        # ── Custom-painted progress track ──────────────────────────────────
        $dlTrack = New-Object System.Windows.Forms.Panel
        $dlTrack.Location  = New-Object System.Drawing.Point(20, 76)
        $dlTrack.Size      = New-Object System.Drawing.Size(268, 6)
        $dlTrack.BackColor = [System.Drawing.Color]::FromArgb(10, 10, 10)

        $dlTrack.Add_Paint({
            param($s, $ev)
            $g   = $ev.Graphics
            $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
            $w   = $s.Width
            $h   = $s.Height
            $pct = $script:dlProgress

            # Track background
            $bg = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(38, 38, 38))
            $g.FillRectangle($bg, 0, 0, $w, $h)
            $bg.Dispose()

            if ($pct -lt 0) {
                # Indeterminate: animated yellow pulse
                $blockW = [int]($w * 0.35)
                $tick   = [int]([System.Environment]::TickCount / 8) % ($w + $blockW)
                $x0     = $tick - $blockW
                $rect   = New-Object System.Drawing.Rectangle($x0, 0, $blockW, $h)
                try {
                    $grad = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
                        $rect,
                        [System.Drawing.Color]::FromArgb(60, 200, 160, 0),
                        [System.Drawing.Color]::FromArgb(255, 220, 0),
                        [System.Drawing.Drawing2D.LinearGradientMode]::Horizontal
                    )
                    $g.FillRectangle($grad, $rect)
                    $grad.Dispose()
                } catch {
                    $fb = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 220, 0))
                    $g.FillRectangle($fb, $rect)
                    $fb.Dispose()
                }
            } else {
                # Determinate fill
                $fillW = [int]($w * $pct / 100.0)
                if ($fillW -gt 0) {
                    $fillRect = New-Object System.Drawing.Rectangle(0, 0, $fillW, $h)
                    try {
                        $fillGrad = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
                            $fillRect,
                            [System.Drawing.Color]::FromArgb(255, 235, 30),
                            [System.Drawing.Color]::FromArgb(200, 170, 0),
                            [System.Drawing.Drawing2D.LinearGradientMode]::Vertical
                        )
                        $g.FillRectangle($fillGrad, $fillRect)
                        $fillGrad.Dispose()
                    } catch {
                        $fb2 = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 220, 0))
                        $g.FillRectangle($fb2, $fillRect)
                        $fb2.Dispose()
                    }
                }
            }
        })

        # ── Percent label (right of bar) ───────────────────────────────────
        $dlPct = New-Object System.Windows.Forms.Label
        $dlPct.Text      = ""
        $dlPct.ForeColor = [System.Drawing.Color]::FromArgb(255, 220, 0)
        $dlPct.Font      = New-Object System.Drawing.Font("Segoe UI", 7, [System.Drawing.FontStyle]::Bold)
        $dlPct.AutoSize  = $false
        $dlPct.Size      = New-Object System.Drawing.Size(48, 14)
        $dlPct.Location  = New-Object System.Drawing.Point(296, 71)
        $dlPct.TextAlign = "MiddleRight"

        # ── KB transferred label ───────────────────────────────────────────
        $dlStatus = New-Object System.Windows.Forms.Label
        $dlStatus.Text      = "Connecting..."
        $dlStatus.ForeColor = [System.Drawing.Color]::FromArgb(75, 75, 75)
        $dlStatus.Font      = New-Object System.Drawing.Font("Segoe UI", 7)
        $dlStatus.AutoSize  = $false
        $dlStatus.Size      = New-Object System.Drawing.Size(316, 14)
        $dlStatus.Location  = New-Object System.Drawing.Point(20, 96)
        $dlStatus.TextAlign = "MiddleLeft"

        # ── Marquee timer (~60 fps repaint) ───────────────────────────────
        $dlTimer = New-Object System.Windows.Forms.Timer
        $dlTimer.Interval = 16
        $dlTimer.Add_Tick({ $dlTrack.Invalidate() })

        $dlInner.Controls.AddRange(@($dlTitle, $dlSub, $dlTrack, $dlPct, $dlStatus))
        $dlForm.Controls.Add($dlInner)
        $dlForm.Show()
        $dlForm.Refresh()

        $script:dlProgress = -1
        $dlTimer.Start()

        # ── Download ───────────────────────────────────────────────────────
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            $wc = New-Object System.Net.WebClient
            $wc.Headers.Add("Cache-Control", "no-cache")

            $wc.add_DownloadProgressChanged({
                param($s, $e)
                if ($e.TotalBytesToReceive -gt 0) {
                    $script:dlProgress = $e.ProgressPercentage
                    $dlTimer.Stop()
                    $recv  = [Math]::Round($e.BytesReceived       / 1KB)
                    $total = [Math]::Round($e.TotalBytesToReceive / 1KB)
                    $dlStatus.Text = "$recv KB  /  $total KB"
                    $dlPct.Text    = "$($e.ProgressPercentage)%"
                } else {
                    $recv          = [Math]::Round($e.BytesReceived / 1KB)
                    $dlStatus.Text = "$recv KB downloaded"
                }
                $dlTrack.Invalidate()
                $dlForm.Refresh()
            })

            $wc.DownloadFile($dlgUrl, $script:dlgExe)

            # Save version tag + file size into Settings.ini
            try {
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                $wcTag = New-Object System.Net.WebClient
                $wcTag.Headers.Add("User-Agent", "MARIUS-Updater")
                $jsonTag  = $wcTag.DownloadString($dlgApiUrl)
                $savedTag = (($jsonTag -split '"tag_name"\s*:\s*"')[1] -split '"')[0]
                $exeSize  = (Get-Item $script:dlgExe).Length
                Save-IniToolVer "DeepLog" $savedTag $exeSize
            } catch {}

            # ── Complete flash ─────────────────────────────────────────────
            $dlTimer.Stop()
            $script:dlProgress = 100
            $dlStatus.Text     = "Complete."
            $dlPct.Text        = "100%"
            $dlSub.Text        = "DeepLog.exe ready."
            $dlSub.ForeColor   = [System.Drawing.Color]::FromArgb(255, 220, 0)
            $dlTrack.Invalidate()
            $dlForm.Refresh()
            Start-Sleep -Milliseconds 500

        } catch {
            $dlTimer.Stop()
            $dlForm.Close()
            [System.Windows.Forms.MessageBox]::Show(
                "Could not download DeepLog.`n`nCheck your connection or grab it manually:`nhttps://github.com/MariusHeier/deeplog/releases`n`n$_",
                "Download Failed",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )
            return
        }
        $dlForm.Close()
    }

    # ── Launch directly, elevated ──────────────────────────────────────────
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName        = "cmd.exe"
    $psi.Arguments       = "/k `"$script:dlgExe`""
    $psi.WindowStyle     = [System.Diagnostics.ProcessWindowStyle]::Normal
    $psi.UseShellExecute = $true
    $psi.Verb            = "runas"
    [System.Diagnostics.Process]::Start($psi) | Out-Null
}


function Show-AutoCalibrate {
    # ── State ────────────────────────────────────────────────────────────
    $script:acFilePath = $null
    $script:acRawText  = $null
    # Each match: @{ Key='xMin'|'yMin'|'xMax'|'yMax'; Value=int; Start=int; Length=int; Stick='LEFT'|'RIGHT' }
    $script:acMatches  = New-Object System.Collections.Generic.List[object]

    $W = 720; $H = 940
    $dlg = New-Object System.Windows.Forms.Form
    $dlg.Text            = ""
    $dlg.Width           = $W
    $dlg.Height          = $H
    $dlg.StartPosition   = "CenterScreen"
    $dlg.FormBorderStyle = "None"
    $dlg.BackColor       = [System.Drawing.Color]::Yellow
    $dlg.TopMost         = $false

    $script:acDrag = $false; $script:acDX = 0; $script:acDY = 0

    $inner = New-Object System.Windows.Forms.Panel
    $inner.Location  = New-Object System.Drawing.Point(3, 3)
    $inner.Size      = New-Object System.Drawing.Size(($W - 6), ($H - 6))
    $inner.BackColor = [System.Drawing.Color]::FromArgb(10, 10, 10)
    $dlg.Controls.Add($inner)

    # ── RGB border timer (matches Troubleshooting/DeepPoll pattern) ─────────
    $script:acHue = if ($script:rgbHue) { $script:rgbHue } else { 0 }
    $acRgbTimer = New-Object System.Windows.Forms.Timer
    $acRgbTimer.Interval = 40
    $acRgbTimer.Add_Tick({
        $script:acHue = ($script:acHue + 2) % 360
        $h = $script:acHue / 360.0
        $i = [Math]::Floor($h * 6)
        $f = $h * 6 - $i
        $q = 1 - $f; $t = $f
        switch ($i % 6) {
            0 { $r = 255; $g = [int]($t*255); $b = 0 }
            1 { $r = [int]($q*255); $g = 255; $b = 0 }
            2 { $r = 0; $g = 255; $b = [int]($t*255) }
            3 { $r = 0; $g = [int]($q*255); $b = 255 }
            4 { $r = [int]($t*255); $g = 0; $b = 255 }
            5 { $r = 255; $g = 0; $b = [int]($q*255) }
        }
        $dlg.BackColor = [System.Drawing.Color]::FromArgb($r, $g, $b)
    })
    $acRgbTimer.Start()
    $dlg.Add_FormClosed({ $acRgbTimer.Stop(); $acRgbTimer.Dispose() })

    # ── Title bar ─────────────────────────────────────────────────────────
    $titleBar = New-Object System.Windows.Forms.Panel
    $titleBar.Location  = New-Object System.Drawing.Point(0, 0)
    $titleBar.Size      = New-Object System.Drawing.Size(($W - 6), 70)
    $titleBar.BackColor = [System.Drawing.Color]::FromArgb(10, 10, 10)
    $inner.Controls.Add($titleBar)
    $titleBar.Add_MouseDown({ $script:acDrag=$true; $script:acDX=[System.Windows.Forms.Cursor]::Position.X-$dlg.Left; $script:acDY=[System.Windows.Forms.Cursor]::Position.Y-$dlg.Top })
    $titleBar.Add_MouseMove({ if($script:acDrag){ $dlg.Left=[System.Windows.Forms.Cursor]::Position.X-$script:acDX; $dlg.Top=[System.Windows.Forms.Cursor]::Position.Y-$script:acDY } })
    $titleBar.Add_MouseUp({ $script:acDrag=$false })

    $picTitle = New-Object System.Windows.Forms.PictureBox
    $picTitle.Location  = New-Object System.Drawing.Point(0, 0)
    $picTitle.Size      = New-Object System.Drawing.Size(($W - 6), 70)
    $picTitle.BackColor = [System.Drawing.Color]::FromArgb(10, 10, 10)
    $picTitle.Add_Paint({
        param($sender, $e); $g=$e.Graphics
        $g.SmoothingMode=[System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $g.TextRenderingHint=[System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
        $sf=New-Object System.Drawing.Font("Impact",22,[System.Drawing.FontStyle]::Italic)
        $sb=New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(80,0,0,0))
        $tf=New-Object System.Drawing.Font("Impact",22,[System.Drawing.FontStyle]::Italic)
        $tb=New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Yellow)
        $g.DrawString("AUTO CALIBRATION",$sf,$sb,22,17)
        $g.DrawString("AUTO CALIBRATION",$tf,$tb,20,15)
        $sf.Dispose();$sb.Dispose();$tf.Dispose();$tb.Dispose()
    })
    $picTitle.Add_MouseDown({ $script:acDrag=$true; $script:acDX=[System.Windows.Forms.Cursor]::Position.X-$dlg.Left; $script:acDY=[System.Windows.Forms.Cursor]::Position.Y-$dlg.Top })
    $picTitle.Add_MouseMove({ if($script:acDrag){ $dlg.Left=[System.Windows.Forms.Cursor]::Position.X-$script:acDX; $dlg.Top=[System.Windows.Forms.Cursor]::Position.Y-$script:acDY } })
    $picTitle.Add_MouseUp({ $script:acDrag=$false })
    $titleBar.Controls.Add($picTitle)

    # Close (X) button
    $btnClose = New-Object System.Windows.Forms.Button
    $btnClose.Location  = New-Object System.Drawing.Point(($W - 6 - 36), 8)
    $btnClose.Size      = New-Object System.Drawing.Size(28, 28)
    $btnClose.Text      = "X"
    $btnClose.FlatStyle = "Flat"
    $btnClose.BackColor = [System.Drawing.Color]::FromArgb(20,20,20)
    $btnClose.ForeColor = [System.Drawing.Color]::Yellow
    $btnClose.Font      = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $btnClose.FlatAppearance.BorderSize = 1
    $btnClose.FlatAppearance.BorderColor = [System.Drawing.Color]::Yellow
    $btnClose.Cursor    = [System.Windows.Forms.Cursors]::Hand
    $btnClose.Add_Click({ $dlg.Close() })
    $titleBar.Controls.Add($btnClose)

    # Divider
    $div = New-Object System.Windows.Forms.Panel
    $div.Location  = New-Object System.Drawing.Point(0, 70)
    $div.Size      = New-Object System.Drawing.Size(($W - 6), 2)
    $div.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 40)
    $inner.Controls.Add($div)

    # ── ALPHA info panel (three rows) ────────────────────────────────────
    $badgePanel = New-Object System.Windows.Forms.Panel
    $badgePanel.Location  = New-Object System.Drawing.Point(20, 80)
    $badgePanel.Size      = New-Object System.Drawing.Size(($W - 46), 96)
    $badgePanel.BackColor = [System.Drawing.Color]::FromArgb(22, 22, 0)
    $inner.Controls.Add($badgePanel)

    # Row 1: alpha warning
    $lblStatus = New-Object System.Windows.Forms.Label
    $lblStatus.Location  = New-Object System.Drawing.Point(8, 4)
    $lblStatus.Size      = New-Object System.Drawing.Size(($W - 62), 24)
    $lblStatus.Text      = "[INFO]  Edit stick calibration values directly. Use with care!"
    $lblStatus.Font      = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $lblStatus.ForeColor = [System.Drawing.Color]::Yellow
    $lblStatus.BackColor = [System.Drawing.Color]::Transparent
    $lblStatus.TextAlign = "MiddleLeft"
    $badgePanel.Controls.Add($lblStatus)

    # Row 2: backup reminder
    $lblBackupNote = New-Object System.Windows.Forms.Label
    $lblBackupNote.Location  = New-Object System.Drawing.Point(8, 30)
    $lblBackupNote.Size      = New-Object System.Drawing.Size(($W - 62), 20)
    $lblBackupNote.Text      = "Load reads your file directly. Save writes your edits back to that same file."
    $lblBackupNote.Font      = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Italic)
    $lblBackupNote.ForeColor = [System.Drawing.Color]::FromArgb(175, 175, 90)
    $lblBackupNote.BackColor = [System.Drawing.Color]::Transparent
    $lblBackupNote.TextAlign = "MiddleLeft"
    $badgePanel.Controls.Add($lblBackupNote)

    # Row 3: red manual backup warning - tells user exactly how to do it
    $lblBackupWarn = New-Object System.Windows.Forms.Label
    $lblBackupWarn.Location  = New-Object System.Drawing.Point(8, 52)
    $lblBackupWarn.Size      = New-Object System.Drawing.Size(($W - 62), 20)
    $lblBackupWarn.Text      = "MAKE SURE TO BACK UP YOUR ORIGINAL FILE - this works best on a fresh, known-good calibration!"
    $lblBackupWarn.Font      = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
    $lblBackupWarn.ForeColor = [System.Drawing.Color]::FromArgb(220, 50, 50)
    $lblBackupWarn.BackColor = [System.Drawing.Color]::Transparent
    $lblBackupWarn.TextAlign = "MiddleLeft"
    $badgePanel.Controls.Add($lblBackupWarn)

    # Row 4: extra red line - tell them to keep a copy OUTSIDE the tool too
    $lblBackupWarn2 = New-Object System.Windows.Forms.Label
    $lblBackupWarn2.Location  = New-Object System.Drawing.Point(8, 72)
    $lblBackupWarn2.Size      = New-Object System.Drawing.Size(($W - 62), 20)
    $lblBackupWarn2.Text      = "KEEP YOUR ORIGINAL FILE SAFE - copy it to another folder or USB drive as your own backup!"
    $lblBackupWarn2.Font      = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
    $lblBackupWarn2.ForeColor = [System.Drawing.Color]::FromArgb(220, 50, 50)
    $lblBackupWarn2.BackColor = [System.Drawing.Color]::Transparent
    $lblBackupWarn2.TextAlign = "MiddleLeft"
    $badgePanel.Controls.Add($lblBackupWarn2)

    # ── Load / Save / Exit buttons ───────────────────────────────────────
    $btnLoad = New-Object System.Windows.Forms.Button
    $btnLoad.Location  = New-Object System.Drawing.Point(20, 188)
    $btnLoad.Size      = New-Object System.Drawing.Size(155, 36)
    $btnLoad.Text      = "LOAD CONFIG"
    $btnLoad.FlatStyle = "Flat"
    $btnLoad.BackColor = [System.Drawing.Color]::FromArgb(20,20,20)
    $btnLoad.ForeColor = [System.Drawing.Color]::Yellow
    $btnLoad.Font      = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $btnLoad.FlatAppearance.BorderSize = 1
    $btnLoad.FlatAppearance.BorderColor = [System.Drawing.Color]::Yellow
    $btnLoad.Cursor    = [System.Windows.Forms.Cursors]::Hand
    $inner.Controls.Add($btnLoad)

    $btnSave = New-Object System.Windows.Forms.Button
    $btnSave.Location  = New-Object System.Drawing.Point(185, 188)
    $btnSave.Size      = New-Object System.Drawing.Size(155, 36)
    $btnSave.Text      = "SAVE CONFIG"
    $btnSave.FlatStyle = "Flat"
    $btnSave.BackColor = [System.Drawing.Color]::FromArgb(20,20,20)
    $btnSave.ForeColor = [System.Drawing.Color]::FromArgb(120,120,120)
    $btnSave.Font      = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $btnSave.FlatAppearance.BorderSize = 1
    $btnSave.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(80,80,80)
    $btnSave.Cursor    = [System.Windows.Forms.Cursors]::Hand
    $btnSave.Enabled   = $false
    $inner.Controls.Add($btnSave)

    # EXIT button - always enabled, closes the calibration dialog
    $btnExit = New-Object System.Windows.Forms.Button
    $btnExit.Location  = New-Object System.Drawing.Point(350, 188)
    $btnExit.Size      = New-Object System.Drawing.Size(100, 36)
    $btnExit.Text      = "EXIT"
    $btnExit.FlatStyle = "Flat"
    $btnExit.BackColor = [System.Drawing.Color]::FromArgb(28, 8, 8)
    $btnExit.ForeColor = [System.Drawing.Color]::FromArgb(220, 60, 60)
    $btnExit.Font      = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $btnExit.FlatAppearance.BorderSize = 1
    $btnExit.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(180, 40, 40)
    $btnExit.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(50, 10, 10)
    $btnExit.FlatAppearance.MouseDownBackColor = [System.Drawing.Color]::FromArgb(70, 10, 10)
    $btnExit.Cursor    = [System.Windows.Forms.Cursors]::Hand
    $btnExit.Add_Click({ $dlg.Close() })
    $inner.Controls.Add($btnExit)

    $lblPath = New-Object System.Windows.Forms.Label
    $lblPath.Location  = New-Object System.Drawing.Point(460, 154)
    $lblPath.Size      = New-Object System.Drawing.Size(($W - 6 - 460 - 20), 24)
    $lblPath.Text      = "No file loaded"
    $lblPath.Font      = New-Object System.Drawing.Font("Segoe UI", 8)
    $lblPath.ForeColor = [System.Drawing.Color]::FromArgb(150,150,150)
    $lblPath.TextAlign = "MiddleLeft"
    $lblPath.AutoEllipsis = $true
    $inner.Controls.Add($lblPath)

    # ── Stick group panels (LEFT STICK / RIGHT STICK) ───────────────────
    function New-AcGroup {
        param([string]$Title, [int]$X, [int]$Y, [int]$GW, [int]$GH)
        $grp = New-Object System.Windows.Forms.Panel
        $grp.Location  = New-Object System.Drawing.Point($X, $Y)
        $grp.Size      = New-Object System.Drawing.Size($GW, $GH)
        $grp.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 20)

        $hdr = New-Object System.Windows.Forms.Label
        $hdr.Location  = New-Object System.Drawing.Point(10, 8)
        $hdr.Size      = New-Object System.Drawing.Size(($GW - 20), 24)
        $hdr.Text      = $Title
        $hdr.Font      = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
        $hdr.ForeColor = [System.Drawing.Color]::Yellow
        $grp.Controls.Add($hdr)

        return $grp
    }

    # 4 rows per stick: UP (yMin), LEFT (xMin), RIGHT (xMax), DOWN (yMax)
    function Add-AcRow {
        param($Parent, [string]$LabelText, [int]$RowY)
        $lbl = New-Object System.Windows.Forms.Label
        $lbl.Location  = New-Object System.Drawing.Point(10, $RowY)
        $lbl.Size      = New-Object System.Drawing.Size(130, 28)
        $lbl.Text      = $LabelText
        $lbl.Font      = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
        $lbl.ForeColor = [System.Drawing.Color]::FromArgb(200, 200, 200)
        $lbl.BackColor = [System.Drawing.Color]::Transparent
        $lbl.TextAlign = "MiddleLeft"
        $Parent.Controls.Add($lbl)

        $num = New-Object System.Windows.Forms.NumericUpDown
        $num.Location  = New-Object System.Drawing.Point(150, $RowY)
        $num.Size      = New-Object System.Drawing.Size(110, 28)
        $num.Minimum   = -100000
        $num.Maximum   = 100000
        $num.Increment = 10
        $num.Font      = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        # Keep Enabled=true so WinForms respects our colors; ReadOnly prevents editing until loaded
        $num.ReadOnly  = $true
        $num.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
        $num.ForeColor = [System.Drawing.Color]::FromArgb(90, 90, 90)
        $num.BorderStyle = "FixedSingle"
        $num.TextAlign = "Center"
        $num.Enabled   = $true
        $Parent.Controls.Add($num)

        $lblKey = New-Object System.Windows.Forms.Label
        $lblKey.Location  = New-Object System.Drawing.Point(270, $RowY)
        $lblKey.Size      = New-Object System.Drawing.Size(70, 28)
        $lblKey.Text      = ""
        $lblKey.Font      = New-Object System.Drawing.Font("Segoe UI", 8)
        $lblKey.ForeColor = [System.Drawing.Color]::FromArgb(110, 110, 110)
        $lblKey.BackColor = [System.Drawing.Color]::Transparent
        $lblKey.TextAlign = "MiddleLeft"
        $Parent.Controls.Add($lblKey)

        return $num, $lblKey
    }

    $groupW = ($W - 6 - 60) / 2
    $groupH = 220

    $grpLeft  = New-AcGroup -Title "LEFT STICK"  -X 20 -Y 240 -GW $groupW -GH $groupH
    $grpRight = New-AcGroup -Title "RIGHT STICK" -X (20 + $groupW + 20) -Y 240 -GW $groupW -GH $groupH
    $inner.Controls.Add($grpLeft)
    $inner.Controls.Add($grpRight)

    $L_up,    $L_upKey    = Add-AcRow -Parent $grpLeft  -LabelText "UP (yMin)"    -RowY 50
    $L_left,  $L_leftKey  = Add-AcRow -Parent $grpLeft  -LabelText "LEFT (xMin)"  -RowY 90
    $L_right, $L_rightKey = Add-AcRow -Parent $grpLeft  -LabelText "RIGHT (xMax)" -RowY 130
    $L_down,  $L_downKey  = Add-AcRow -Parent $grpLeft  -LabelText "DOWN (yMax)"  -RowY 170

    $R_up,    $R_upKey    = Add-AcRow -Parent $grpRight -LabelText "UP (yMin)"    -RowY 50
    $R_left,  $R_leftKey  = Add-AcRow -Parent $grpRight -LabelText "LEFT (xMin)"  -RowY 90
    $R_right, $R_rightKey = Add-AcRow -Parent $grpRight -LabelText "RIGHT (xMax)" -RowY 130
    $R_down,  $R_downKey  = Add-AcRow -Parent $grpRight -LabelText "DOWN (yMax)"  -RowY 170

    # ── Per-stick adjust buttons — directly under each group ─────────────
    # Groups bottom: Y=200 + groupH=220 = 420; leave 8px gap
    $stickLblH   = 20
    $stickBtnY   = 240 + $groupH + 8 + $stickLblH + 4
    $stickBtnH   = 36
    $stickBtnGap = 6
    # Each group is $groupW wide starting at X=20 (left) and X=20+groupW+20 (right)
    $stickBtnW   = [int](($groupW - 30) / 4)   # 4 buttons per side with gaps
    $rightGrpX   = 20 + $groupW + 20

    # Red "LEFT STICK" label above left buttons
    $lblLeftStick = New-Object System.Windows.Forms.Label
    $lblLeftStick.Location  = New-Object System.Drawing.Point(20, (240 + $groupH + 8))
    $lblLeftStick.Size      = New-Object System.Drawing.Size($groupW, $stickLblH)
    $lblLeftStick.Text      = "LEFT STICK"
    $lblLeftStick.Font      = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $lblLeftStick.ForeColor = [System.Drawing.Color]::FromArgb(210, 50, 50)
    $lblLeftStick.BackColor = [System.Drawing.Color]::Transparent
    $lblLeftStick.TextAlign = "MiddleLeft"
    $inner.Controls.Add($lblLeftStick)

    # Red "RIGHT STICK" label above right buttons
    $lblRightStick = New-Object System.Windows.Forms.Label
    $lblRightStick.Location  = New-Object System.Drawing.Point($rightGrpX, (240 + $groupH + 8))
    $lblRightStick.Size      = New-Object System.Drawing.Size($groupW, $stickLblH)
    $lblRightStick.Text      = "RIGHT STICK"
    $lblRightStick.Font      = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $lblRightStick.ForeColor = [System.Drawing.Color]::FromArgb(210, 50, 50)
    $lblRightStick.BackColor = [System.Drawing.Color]::Transparent
    $lblRightStick.TextAlign = "MiddleLeft"
    $inner.Controls.Add($lblRightStick)

    function New-StickBtn {
        param([string]$Text, [int]$X, [int]$Y, [int]$W2, [int]$H2)
        $b = New-Object System.Windows.Forms.Button
        $b.Location  = New-Object System.Drawing.Point($X, $Y)
        $b.Size      = New-Object System.Drawing.Size($W2, $H2)
        $b.Text      = $Text
        $b.FlatStyle = "Flat"
        $b.BackColor = [System.Drawing.Color]::FromArgb(20,20,20)
        $b.ForeColor = [System.Drawing.Color]::Yellow
        $b.Font      = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
        $b.FlatAppearance.BorderSize  = 1
        $b.FlatAppearance.BorderColor = [System.Drawing.Color]::Yellow
        $b.Cursor    = [System.Windows.Forms.Cursors]::Hand
        $b.Enabled   = $false
        return $b
    }

    # LEFT stick buttons (row 1: +2 | +5 | +10 | +20 / row 2: -2 | -5 | -10 | -20)
    $btnL2   = New-StickBtn "+2"   (20)                                              ($stickBtnY)                  $stickBtnW $stickBtnH
    $btnL5   = New-StickBtn "+5"   (20 + $stickBtnW + $stickBtnGap)                 ($stickBtnY)                  $stickBtnW $stickBtnH
    $btnL10  = New-StickBtn "+10"  (20 + ($stickBtnW + $stickBtnGap)*2)             ($stickBtnY)                  $stickBtnW $stickBtnH
    $btnL20  = New-StickBtn "+20"  (20 + ($stickBtnW + $stickBtnGap)*3)             ($stickBtnY)                  $stickBtnW $stickBtnH
    $btnLm2  = New-StickBtn "-2"   (20)                                              ($stickBtnY + $stickBtnH + 4) $stickBtnW $stickBtnH
    $btnLm5  = New-StickBtn "-5"   (20 + $stickBtnW + $stickBtnGap)                 ($stickBtnY + $stickBtnH + 4) $stickBtnW $stickBtnH
    $btnLm10 = New-StickBtn "-10"  (20 + ($stickBtnW + $stickBtnGap)*2)             ($stickBtnY + $stickBtnH + 4) $stickBtnW $stickBtnH
    $btnLm20 = New-StickBtn "-20"  (20 + ($stickBtnW + $stickBtnGap)*3)             ($stickBtnY + $stickBtnH + 4) $stickBtnW $stickBtnH

    # RIGHT stick buttons — same layout shifted to right group X
    $btnR2   = New-StickBtn "+2"   ($rightGrpX)                                              ($stickBtnY)                  $stickBtnW $stickBtnH
    $btnR5   = New-StickBtn "+5"   ($rightGrpX + $stickBtnW + $stickBtnGap)                 ($stickBtnY)                  $stickBtnW $stickBtnH
    $btnR10  = New-StickBtn "+10"  ($rightGrpX + ($stickBtnW + $stickBtnGap)*2)             ($stickBtnY)                  $stickBtnW $stickBtnH
    $btnR20  = New-StickBtn "+20"  ($rightGrpX + ($stickBtnW + $stickBtnGap)*3)             ($stickBtnY)                  $stickBtnW $stickBtnH
    $btnRm2  = New-StickBtn "-2"   ($rightGrpX)                                              ($stickBtnY + $stickBtnH + 4) $stickBtnW $stickBtnH
    $btnRm5  = New-StickBtn "-5"   ($rightGrpX + $stickBtnW + $stickBtnGap)                 ($stickBtnY + $stickBtnH + 4) $stickBtnW $stickBtnH
    $btnRm10 = New-StickBtn "-10"  ($rightGrpX + ($stickBtnW + $stickBtnGap)*2)             ($stickBtnY + $stickBtnH + 4) $stickBtnW $stickBtnH
    $btnRm20 = New-StickBtn "-20"  ($rightGrpX + ($stickBtnW + $stickBtnGap)*3)             ($stickBtnY + $stickBtnH + 4) $stickBtnW $stickBtnH

    foreach ($b in @($btnL2,$btnL5,$btnL10,$btnL20,$btnLm2,$btnLm5,$btnLm10,$btnLm20,$btnR2,$btnR5,$btnR10,$btnR20,$btnRm2,$btnRm5,$btnRm10,$btnRm20)) {
        $inner.Controls.Add($b)
    }

    # ── AUTO ADJUST ALL buttons — below per-stick rows ───────────────────
    $adjY = $stickBtnY + $stickBtnH*2 + 4 + 18   # below both per-stick rows + gap

    $lblAdj = New-Object System.Windows.Forms.Label
    $lblAdj.Location  = New-Object System.Drawing.Point(20, $adjY)
    $lblAdj.Size      = New-Object System.Drawing.Size(($W - 46), 24)
    $lblAdj.Text      = "AUTO ADJUST  (both sticks: yMin/xMin +delta, xMax/yMax -delta)"
    $lblAdj.Font      = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $lblAdj.ForeColor = [System.Drawing.Color]::FromArgb(210, 50, 50)
    $inner.Controls.Add($lblAdj)

    $btnY = $adjY + 28
    $btnAdjW = [int](($W - 6 - 40 - 40) / 5)

    $btn2all = New-Object System.Windows.Forms.Button
    $btn2all.Location  = New-Object System.Drawing.Point(20, $btnY)
    $btn2all.Size      = New-Object System.Drawing.Size($btnAdjW, 40)
    $btn2all.Text      = "+/-2 ALL"
    $btn2all.FlatStyle = "Flat"
    $btn2all.BackColor = [System.Drawing.Color]::FromArgb(20,20,20)
    $btn2all.ForeColor = [System.Drawing.Color]::Yellow
    $btn2all.Font      = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $btn2all.FlatAppearance.BorderSize = 1
    $btn2all.FlatAppearance.BorderColor = [System.Drawing.Color]::Yellow
    $btn2all.Cursor    = [System.Windows.Forms.Cursors]::Hand
    $btn2all.Enabled   = $false
    $inner.Controls.Add($btn2all)

    $btn5all = New-Object System.Windows.Forms.Button
    $btn5all.Location  = New-Object System.Drawing.Point((20 + $btnAdjW + 10), $btnY)
    $btn5all.Size      = New-Object System.Drawing.Size($btnAdjW, 40)
    $btn5all.Text      = "+/-5 ALL"
    $btn5all.FlatStyle = "Flat"
    $btn5all.BackColor = [System.Drawing.Color]::FromArgb(20,20,20)
    $btn5all.ForeColor = [System.Drawing.Color]::Yellow
    $btn5all.Font      = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $btn5all.FlatAppearance.BorderSize = 1
    $btn5all.FlatAppearance.BorderColor = [System.Drawing.Color]::Yellow
    $btn5all.Cursor    = [System.Windows.Forms.Cursors]::Hand
    $btn5all.Enabled   = $false
    $inner.Controls.Add($btn5all)

    $btn10all = New-Object System.Windows.Forms.Button
    $btn10all.Location  = New-Object System.Drawing.Point((20 + 2*($btnAdjW + 10)), $btnY)
    $btn10all.Size      = New-Object System.Drawing.Size($btnAdjW, 40)
    $btn10all.Text      = "+/-10 ALL"
    $btn10all.FlatStyle = "Flat"
    $btn10all.BackColor = [System.Drawing.Color]::FromArgb(20,20,20)
    $btn10all.ForeColor = [System.Drawing.Color]::Yellow
    $btn10all.Font      = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $btn10all.FlatAppearance.BorderSize = 1
    $btn10all.FlatAppearance.BorderColor = [System.Drawing.Color]::Yellow
    $btn10all.Cursor    = [System.Windows.Forms.Cursors]::Hand
    $btn10all.Enabled   = $false
    $inner.Controls.Add($btn10all)

    $btn20all = New-Object System.Windows.Forms.Button
    $btn20all.Location  = New-Object System.Drawing.Point((20 + 3*($btnAdjW + 10)), $btnY)
    $btn20all.Size      = New-Object System.Drawing.Size($btnAdjW, 40)
    $btn20all.Text      = "+/-20 ALL"
    $btn20all.FlatStyle = "Flat"
    $btn20all.BackColor = [System.Drawing.Color]::FromArgb(20,20,20)
    $btn20all.ForeColor = [System.Drawing.Color]::Yellow
    $btn20all.Font      = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $btn20all.FlatAppearance.BorderSize = 1
    $btn20all.FlatAppearance.BorderColor = [System.Drawing.Color]::Yellow
    $btn20all.Cursor    = [System.Windows.Forms.Cursors]::Hand
    $btn20all.Enabled   = $false
    $inner.Controls.Add($btn20all)

    $btnReset = New-Object System.Windows.Forms.Button
    $btnReset.Location  = New-Object System.Drawing.Point((20 + 4*($btnAdjW + 10)), $btnY)
    $btnReset.Size      = New-Object System.Drawing.Size($btnAdjW, 40)
    $btnReset.Text      = "RESET TO LOADED"
    $btnReset.FlatStyle = "Flat"
    $btnReset.BackColor = [System.Drawing.Color]::FromArgb(20,20,20)
    $btnReset.ForeColor = [System.Drawing.Color]::Yellow
    $btnReset.Font      = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $btnReset.FlatAppearance.BorderSize = 1
    $btnReset.FlatAppearance.BorderColor = [System.Drawing.Color]::Yellow
    $btnReset.Cursor    = [System.Windows.Forms.Cursors]::Hand
    $btnReset.Enabled   = $false
    $inner.Controls.Add($btnReset)

    foreach ($b in @($btnLoad,$btnSave,$btn2all,$btn5all,$btn10all,$btn20all,$btnReset,
                     $btnL2,$btnL5,$btnL10,$btnL20,$btnLm2,$btnLm5,$btnLm10,$btnLm20,$btnR2,$btnR5,$btnR10,$btnR20,$btnRm2,$btnRm5,$btnRm10,$btnRm20)) {
        $b.Add_MouseEnter({ if($this.Enabled){ $this.BackColor=[System.Drawing.Color]::FromArgb(40,40,12) } })
        $b.Add_MouseLeave({ if($this.Enabled){ $this.BackColor=[System.Drawing.Color]::FromArgb(20,20,20) } })
    }
    # EXIT uses its own FlatAppearance colours; just reset background on leave
    $btnExit.Add_MouseLeave({ $btnExit.BackColor=[System.Drawing.Color]::FromArgb(28,8,8) })

    # ── Log box (shows what was found / changed) ────────────────────────
    $logY = $btnY + 48
    $logBox = New-Object System.Windows.Forms.RichTextBox
    $logBox.Location   = New-Object System.Drawing.Point(20, $logY)
    $logBox.Size       = New-Object System.Drawing.Size(($W - 46), ($H - $logY - 30))
    $logBox.BackColor  = [System.Drawing.Color]::FromArgb(18, 18, 18)
    $logBox.ForeColor  = [System.Drawing.Color]::FromArgb(190, 190, 190)
    $logBox.Font       = New-Object System.Drawing.Font("Consolas", 9)
    $logBox.ReadOnly   = $true
    $logBox.BorderStyle = "None"
    $logBox.ScrollBars = "Vertical"
    $inner.Controls.Add($logBox)

    function Write-AcLog {
        param([string]$Text, [string]$ColorName = "Gray")
        $logBox.SelectionStart = $logBox.TextLength
        $logBox.SelectionLength = 0
        $logBox.SelectionColor = [System.Drawing.Color]::$ColorName
        $logBox.AppendText("$Text`n")
        $logBox.ScrollToCaret()
    }

    Write-AcLog "Auto Calibration Tool" "Yellow"
    Write-AcLog "Load a JSON file containing xMin/yMin/xMax/yMax values." "Gray"
    Write-AcLog "First complete set found = LEFT STICK. Last complete set found = RIGHT STICK." "Gray"
    Write-AcLog "Load reads directly from the file you pick. Save writes back to that same file." "Cyan"
    Write-AcLog "Pick any JSON file - Load and Save both operate on it directly." "Gray"

    # ── Core: find xMin/yMin/xMax/yMax occurrences in raw text ──────────
    function Find-AcMatches {
        param([string]$Text)

        $pattern = '("(?<key>xMin|yMin|xMax|yMax)"\s*:\s*)(?<val>-?\d+)'
        $regexMatches = [regex]::Matches($Text, $pattern)

        $found = New-Object System.Collections.Generic.List[object]
        foreach ($m in $regexMatches) {
            $valGroup = $m.Groups['val']
            $found.Add([PSCustomObject]@{
                Key    = $m.Groups['key'].Value
                Value  = [int]$valGroup.Value
                Start  = $valGroup.Index
                Length = $valGroup.Length
            })
        }
        return $found
    }

    function Group-AcSticks {
        param($Found)

        # Walk through matches, grouping into consecutive sets of the 4 keys.
        $sets = New-Object System.Collections.Generic.List[object]
        $current = @{}
        foreach ($m in $Found) {
            if ($current.ContainsKey($m.Key)) {
                # Starting a new set (key repeats) -- flush current if it has anything
                if ($current.Count -gt 0) {
                    $sets.Add($current)
                    $current = @{}
                }
            }
            $current[$m.Key] = $m
            if ($current.Count -eq 4) {
                $sets.Add($current)
                $current = @{}
            }
        }
        if ($current.Count -gt 0) { $sets.Add($current) }
        return $sets
    }

    # ── Helper to populate a row — defined at function scope so it works on every load ──
    # FIX: was defined inside $btnLoad.Add_Click which caused scoping issues on 2nd+ load
    function Set-AcRow {
        param($Num, $KeyLbl, $Set, [string]$Key)
        if ($Set.ContainsKey($Key)) {
            $Num.Value     = [decimal]$Set[$Key].Value
            $Num.ReadOnly  = $false
            $Num.BackColor = [System.Drawing.Color]::FromArgb(22, 22, 22)
            $Num.ForeColor = [System.Drawing.Color]::Yellow
            $KeyLbl.Text   = $Key
            $KeyLbl.ForeColor = [System.Drawing.Color]::FromArgb(130, 130, 130)
        } else {
            $Num.Value     = 0
            $Num.ReadOnly  = $true
            $Num.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 20)
            $Num.ForeColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
            $KeyLbl.Text   = "(missing)"
            $KeyLbl.ForeColor = [System.Drawing.Color]::FromArgb(80, 80, 80)
        }
        $Num.Refresh()  # force repaint so new value shows immediately
    }

    # ── LOAD JSON ─────────────────────────────────────────────────────────
    $btnLoad.Add_Click({
        $ofd = New-Object System.Windows.Forms.OpenFileDialog
        $ofd.Filter = "JSON files (*.json)|*.json|All files (*.*)|*.*"
        $ofd.Title  = "Select calibration JSON file"
        if ($ofd.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { return }

        try {
            $text = [System.IO.File]::ReadAllText($ofd.FileName)
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Could not read file:`n$_","Error",
                [System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error)
            return
        }

        $found = Find-AcMatches -Text $text
        if ($found.Count -eq 0) {
            Write-AcLog "No xMin/yMin/xMax/yMax values found in this file." "Red"
            [System.Windows.Forms.MessageBox]::Show("No xMin/yMin/xMax/yMax keys were found in this JSON file.","Nothing Found",
                [System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Warning)
            return
        }

        $sets = Group-AcSticks -Found $found
        if ($sets.Count -eq 0) {
            Write-AcLog "Could not group values into complete sets." "Red"
            return
        }

        # Load reads source into memory. Save writes to LoadThisFileIntoMarius.json.
        $fileDir           = [System.IO.Path]::GetDirectoryName($ofd.FileName)
        $script:acRawText  = $text
        $script:acFilePath = [System.IO.Path]::Combine($fileDir, "LoadThisFileIntoMarius.json")

        $lblPath.Text      = "LoadThisFileIntoMarius.json  (source: $($ofd.SafeFileName))"
        $lblStatus.Text    = "  LOADED  |  $($sets.Count) set(s) found - edit values then SAVE CONFIG"

        $leftSet  = $sets[0]
        $rightSet = $sets[$sets.Count - 1]

        # FIX: reset all spinners to 0 before populating — prevents stale values
        # from a previously loaded file sticking around if a key is missing in the new one
        foreach ($ctrl in @($L_up,$L_left,$L_right,$L_down,$R_up,$R_left,$R_right,$R_down)) {
            $ctrl.Value = 0
        }

        Set-AcRow $L_up    $L_upKey    $leftSet  "yMin"
        Set-AcRow $L_left  $L_leftKey  $leftSet  "xMin"
        Set-AcRow $L_right $L_rightKey $leftSet  "xMax"
        Set-AcRow $L_down  $L_downKey  $leftSet  "yMax"

        Set-AcRow $R_up    $R_upKey    $rightSet "yMin"
        Set-AcRow $R_left  $R_leftKey  $rightSet "xMin"
        Set-AcRow $R_right $R_rightKey $rightSet "xMax"
        Set-AcRow $R_down  $R_downKey  $rightSet "yMax"

        # Store matches for save (use object refs so live edits via NumericUpDown are picked up later)
        $script:acLeftSet  = $leftSet
        $script:acRightSet = $rightSet
        $script:acAllFound = $found

        # FIX: snapshot AFTER Set-AcRow calls so RESET restores the actual new file's values
        $script:acLoadedValues = @{
            L_up    = $L_up.Value;    L_left  = $L_left.Value;  L_right = $L_right.Value;  L_down  = $L_down.Value
            R_up    = $R_up.Value;    R_left  = $R_left.Value;  R_right = $R_right.Value;  R_down  = $R_down.Value
        }

        $btnSave.Enabled = $true
        $btnSave.ForeColor = [System.Drawing.Color]::Yellow
        $btnSave.FlatAppearance.BorderColor = [System.Drawing.Color]::Yellow
        $btn2all.Enabled = $true
        $btn2all.ForeColor = [System.Drawing.Color]::Yellow
        $btn5all.Enabled = $true
        $btn5all.ForeColor = [System.Drawing.Color]::Yellow
        $btn10all.Enabled = $true
        $btn10all.ForeColor = [System.Drawing.Color]::Yellow
        $btn20all.Enabled = $true
        $btn20all.ForeColor = [System.Drawing.Color]::Yellow
        $btnReset.Enabled = $true
        $btnReset.ForeColor = [System.Drawing.Color]::Yellow
        foreach ($b in @($btnL2,$btnL5,$btnL10,$btnL20,$btnLm2,$btnLm5,$btnLm10,$btnLm20,$btnR2,$btnR5,$btnR10,$btnR20,$btnRm2,$btnRm5,$btnRm10,$btnRm20)) {
            $b.Enabled   = $true
            $b.ForeColor = [System.Drawing.Color]::Yellow
        }

        Write-AcLog "Loaded: $($ofd.FileName)" "Yellow"
        Write-AcLog "Found $($found.Count) value(s) across $($sets.Count) set(s)." "Gray"
        if ($leftSet.Count -lt 4) { Write-AcLog "WARNING: LEFT STICK set is incomplete (missing keys)." "Orange" }
        if ($rightSet.Count -lt 4 -and $sets.Count -gt 1) { Write-AcLog "WARNING: RIGHT STICK set is incomplete (missing keys)." "Orange" }
        if ($sets.Count -eq 1) { Write-AcLog "Only one set found - LEFT and RIGHT show the same values. Saving will update that single set." "Orange" }
        Write-AcLog "  LEFT  -> yMin=$($leftSet['yMin'].Value)  xMin=$($leftSet['xMin'].Value)  xMax=$($leftSet['xMax'].Value)  yMax=$($leftSet['yMax'].Value)" "Gray"
        Write-AcLog "  RIGHT -> yMin=$($rightSet['yMin'].Value)  xMin=$($rightSet['xMin'].Value)  xMax=$($rightSet['xMax'].Value)  yMax=$($rightSet['yMax'].Value)" "Gray"
    })

    # ── Auto-adjust: apply delta to mins (+delta) and maxes (-delta) ────────
    function Apply-AcDelta {
        param([int]$Delta)
        if (-not $script:acFilePath) { return }

        # Snapshot "before" values for the log
        $before = @{
            L_up=$L_up.Value; L_left=$L_left.Value; L_right=$L_right.Value; L_down=$L_down.Value
            R_up=$R_up.Value; R_left=$R_left.Value; R_right=$R_right.Value; R_down=$R_down.Value
        }

        # yMin/xMin increase by Delta; xMax/yMax decrease by Delta
        $L_up.Value    = [decimal][Math]::Min([Math]::Max(($L_up.Value    + $Delta), $L_up.Minimum),    $L_up.Maximum)
        $L_left.Value  = [decimal][Math]::Min([Math]::Max(($L_left.Value  + $Delta), $L_left.Minimum),  $L_left.Maximum)
        $L_right.Value = [decimal][Math]::Min([Math]::Max(($L_right.Value - $Delta), $L_right.Minimum), $L_right.Maximum)
        $L_down.Value  = [decimal][Math]::Min([Math]::Max(($L_down.Value  - $Delta), $L_down.Minimum),  $L_down.Maximum)

        $R_up.Value    = [decimal][Math]::Min([Math]::Max(($R_up.Value    + $Delta), $R_up.Minimum),    $R_up.Maximum)
        $R_left.Value  = [decimal][Math]::Min([Math]::Max(($R_left.Value  + $Delta), $R_left.Minimum),  $R_left.Maximum)
        $R_right.Value = [decimal][Math]::Min([Math]::Max(($R_right.Value - $Delta), $R_right.Minimum), $R_right.Maximum)
        $R_down.Value  = [decimal][Math]::Min([Math]::Max(($R_down.Value  - $Delta), $R_down.Minimum),  $R_down.Maximum)

        Write-AcLog "Applied delta $Delta (yMin/xMin +, xMax/yMax -) to both sticks:" "Yellow"
        Write-AcLog "  LEFT  UP $($before.L_up)->$($L_up.Value)  LEFT $($before.L_left)->$($L_left.Value)  RIGHT $($before.L_right)->$($L_right.Value)  DOWN $($before.L_down)->$($L_down.Value)" "Gray"
        Write-AcLog "  RIGHT UP $($before.R_up)->$($R_up.Value)  LEFT $($before.R_left)->$($R_left.Value)  RIGHT $($before.R_right)->$($R_right.Value)  DOWN $($before.R_down)->$($R_down.Value)" "Gray"
    }

    $btn2all.Add_Click({  Apply-AcDelta -Delta 2  })
    $btn5all.Add_Click({  Apply-AcDelta -Delta 5  })
    $btn10all.Add_Click({ Apply-AcDelta -Delta 10 })
    $btn20all.Add_Click({ Apply-AcDelta -Delta 20 })

    # ── Per-stick delta (only touches one stick) ─────────────────────────
    function Apply-AcDeltaStick {
        param([int]$Delta, [string]$Stick)
        if (-not $script:acFilePath) { return }

        if ($Stick -eq 'LEFT') {
            $before = @{ up=$L_up.Value; left=$L_left.Value; right=$L_right.Value; down=$L_down.Value }
            $L_up.Value    = [decimal][Math]::Min([Math]::Max(($L_up.Value    + $Delta), $L_up.Minimum),    $L_up.Maximum)
            $L_left.Value  = [decimal][Math]::Min([Math]::Max(($L_left.Value  + $Delta), $L_left.Minimum),  $L_left.Maximum)
            $L_right.Value = [decimal][Math]::Min([Math]::Max(($L_right.Value - $Delta), $L_right.Minimum), $L_right.Maximum)
            $L_down.Value  = [decimal][Math]::Min([Math]::Max(($L_down.Value  - $Delta), $L_down.Minimum),  $L_down.Maximum)
            Write-AcLog "Applied delta $Delta to LEFT stick only (yMin/xMin +, xMax/yMax -):" "Yellow"
            Write-AcLog "  UP $($before.up)->$($L_up.Value)  LEFT $($before.left)->$($L_left.Value)  RIGHT $($before.right)->$($L_right.Value)  DOWN $($before.down)->$($L_down.Value)" "Gray"
        } elseif ($Stick -eq 'RIGHT') {
            $before = @{ up=$R_up.Value; left=$R_left.Value; right=$R_right.Value; down=$R_down.Value }
            $R_up.Value    = [decimal][Math]::Min([Math]::Max(($R_up.Value    + $Delta), $R_up.Minimum),    $R_up.Maximum)
            $R_left.Value  = [decimal][Math]::Min([Math]::Max(($R_left.Value  + $Delta), $R_left.Minimum),  $R_left.Maximum)
            $R_right.Value = [decimal][Math]::Min([Math]::Max(($R_right.Value - $Delta), $R_right.Minimum), $R_right.Maximum)
            $R_down.Value  = [decimal][Math]::Min([Math]::Max(($R_down.Value  - $Delta), $R_down.Minimum),  $R_down.Maximum)
            Write-AcLog "Applied delta $Delta to RIGHT stick only (yMin/xMin +, xMax/yMax -):" "Yellow"
            Write-AcLog "  UP $($before.up)->$($R_up.Value)  LEFT $($before.left)->$($R_left.Value)  RIGHT $($before.right)->$($R_right.Value)  DOWN $($before.down)->$($R_down.Value)" "Gray"
        }
    }

    $btnL2.Add_Click({   Apply-AcDeltaStick -Delta   2 -Stick 'LEFT'  })
    $btnL5.Add_Click({   Apply-AcDeltaStick -Delta   5 -Stick 'LEFT'  })
    $btnL10.Add_Click({  Apply-AcDeltaStick -Delta  10 -Stick 'LEFT'  })
    $btnL20.Add_Click({  Apply-AcDeltaStick -Delta  20 -Stick 'LEFT'  })
    $btnLm2.Add_Click({  Apply-AcDeltaStick -Delta  -2 -Stick 'LEFT'  })
    $btnLm5.Add_Click({  Apply-AcDeltaStick -Delta  -5 -Stick 'LEFT'  })
    $btnLm10.Add_Click({ Apply-AcDeltaStick -Delta -10 -Stick 'LEFT'  })
    $btnLm20.Add_Click({ Apply-AcDeltaStick -Delta -20 -Stick 'LEFT'  })
    $btnR2.Add_Click({   Apply-AcDeltaStick -Delta   2 -Stick 'RIGHT' })
    $btnR5.Add_Click({   Apply-AcDeltaStick -Delta   5 -Stick 'RIGHT' })
    $btnR10.Add_Click({  Apply-AcDeltaStick -Delta  10 -Stick 'RIGHT' })
    $btnR20.Add_Click({  Apply-AcDeltaStick -Delta  20 -Stick 'RIGHT' })
    $btnRm2.Add_Click({  Apply-AcDeltaStick -Delta  -2 -Stick 'RIGHT' })
    $btnRm5.Add_Click({  Apply-AcDeltaStick -Delta  -5 -Stick 'RIGHT' })
    $btnRm10.Add_Click({ Apply-AcDeltaStick -Delta -10 -Stick 'RIGHT' })
    $btnRm20.Add_Click({ Apply-AcDeltaStick -Delta -20 -Stick 'RIGHT' })

    # ── RESET TO LOADED: restore the values as they were when the file was loaded ──
    $btnReset.Add_Click({
        if (-not $script:acLoadedValues) { return }
        $v = $script:acLoadedValues
        $L_up.Value    = $v.L_up;    $L_left.Value  = $v.L_left;  $L_right.Value = $v.L_right;  $L_down.Value  = $v.L_down
        $R_up.Value    = $v.R_up;    $R_left.Value  = $v.R_left;  $R_right.Value = $v.R_right;  $R_down.Value  = $v.R_down
        Write-AcLog "Reset all 8 values back to as-loaded." "Yellow"
    })

    # ── SAVE JSON ─────────────────────────────────────────────────────────
    $btnSave.Add_Click({
        if (-not $script:acFilePath -or -not $script:acRawText) { return }

        # Read spinner values directly
        $leftVals  = @{ yMin=[int]$L_up.Value; xMin=[int]$L_left.Value; xMax=[int]$L_right.Value; yMax=[int]$L_down.Value }
        $rightVals = @{ yMin=[int]$R_up.Value; xMin=[int]$R_left.Value; xMax=[int]$R_right.Value; yMax=[int]$R_down.Value }

        # FIX: always re-scan fresh offsets from the current working text instead of
        # using $script:acAllFound which holds stale positions from load time.
        # Offsets drift whenever a number changes digit length (e.g. 480->1000),
        # causing subsequent saves to corrupt the file or write to the wrong position.
        $freshFound = Find-AcMatches -Text $script:acRawText
        $sets = Group-AcSticks -Found $freshFound
        if ($sets.Count -eq 0) {
            Write-AcLog "ERROR: Could not find calibration keys in working text." "Red"
            return
        }
        $leftSet  = $sets[0]
        $rightSet = $sets[$sets.Count - 1]

        # Apply replacements back-to-front by offset so earlier positions stay valid
        $ops = New-Object System.Collections.Generic.List[object]
        foreach ($key in @("yMin","xMin","xMax","yMax")) {
            if ($leftSet.ContainsKey($key)) {
                $m = $leftSet[$key]
                $ops.Add([PSCustomObject]@{ Start=$m.Start; Length=$m.Length; NewText=[string]$leftVals[$key] })
            }
            if ($sets.Count -gt 1 -and $rightSet.ContainsKey($key)) {
                $m = $rightSet[$key]
                $ops.Add([PSCustomObject]@{ Start=$m.Start; Length=$m.Length; NewText=[string]$rightVals[$key] })
            }
        }

        $sortedOps = $ops | Sort-Object -Property Start -Descending
        $newText = $script:acRawText
        foreach ($op in $sortedOps) {
            $newText = $newText.Substring(0, $op.Start) + $op.NewText + $newText.Substring($op.Start + $op.Length)
        }

        try {
            [System.IO.File]::WriteAllText($script:acFilePath, $newText, [System.Text.Encoding]::UTF8)  # exact bytes, no BOM/newline drift
            $script:acRawText  = $newText
            $script:acAllFound = Find-AcMatches -Text $newText
            # Verify: re-read the file we just wrote and confirm values match spinners
            $verify = [System.IO.File]::ReadAllText($script:acFilePath)
            $vFound = Find-AcMatches -Text $verify
            $vSets  = Group-AcSticks -Found $vFound
            $vL = $vSets[0]; $vR = $vSets[$vSets.Count - 1]
            Write-AcLog "Saved to: $($script:acFilePath)" "Yellow"
            Write-AcLog "  WRITTEN LEFT  -> yMin=$($vL['yMin'].Value)  xMin=$($vL['xMin'].Value)  xMax=$($vL['xMax'].Value)  yMax=$($vL['yMax'].Value)" "Gray"
            Write-AcLog "  WRITTEN RIGHT -> yMin=$($vR['yMin'].Value)  xMin=$($vR['xMin'].Value)  xMax=$($vR['xMax'].Value)  yMax=$($vR['yMax'].Value)" "Gray"
            Write-AcLog "  SPINNER LEFT  -> yMin=$([int]$L_up.Value)  xMin=$([int]$L_left.Value)  xMax=$([int]$L_right.Value)  yMax=$([int]$L_down.Value)" "Cyan"
            Write-AcLog "  SPINNER RIGHT -> yMin=$([int]$R_up.Value)  xMin=$([int]$R_left.Value)  xMax=$([int]$R_right.Value)  yMax=$([int]$R_down.Value)" "Cyan"
            Write-AcLog "  Your original source file is still untouched." "Cyan"
            $lblStatus.Text = "  SAVED  |  $($ops.Count) value(s) written"
        } catch {
            Write-AcLog "ERROR saving file: $_" "Red"
            [System.Windows.Forms.MessageBox]::Show("Could not save file:`n$_","Error",
                [System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error)
        }
    })

    $dlg.Add_KeyDown({ param($s,$e); if($e.KeyCode -eq "Escape"){ $dlg.Close() } })
    [void]$dlg.ShowDialog()
}

function Show-UsbAnalyzer {
    $analyzerForm = New-Object System.Windows.Forms.Form
    $analyzerForm.Text = "USB LATENCY ANALYZER V3"
    $analyzerForm.Width = 854
    $analyzerForm.Height = 654
    $analyzerForm.StartPosition = "CenterScreen"
    $analyzerForm.FormBorderStyle = "None"
    $analyzerForm.BackColor = [System.Drawing.Color]::Yellow
    $analyzerForm.Padding = New-Object System.Windows.Forms.Padding(2)

    $mainPanel = New-Object System.Windows.Forms.Panel
    $mainPanel.Location = New-Object System.Drawing.Point(2, 2)
    $mainPanel.Size = New-Object System.Drawing.Size(850, 650)
    $mainPanel.BackColor = [System.Drawing.Color]::FromArgb(26, 6, 6)

    $headerPanel = New-Object System.Windows.Forms.Panel
    $headerPanel.Location = New-Object System.Drawing.Point(0, 0)
    $headerPanel.Size = New-Object System.Drawing.Size(850, 85)
    $headerPanel.BackColor = [System.Drawing.Color]::Black

    $headerPanel.Add_MouseDown({
        $script:dragging = $true
        $script:dragCursorX = [System.Windows.Forms.Cursor]::Position.X - $analyzerForm.Left
        $script:dragCursorY = [System.Windows.Forms.Cursor]::Position.Y - $analyzerForm.Top
    })

    $headerPanel.Add_MouseMove({
        if ($script:dragging) {
            $analyzerForm.Left = [System.Windows.Forms.Cursor]::Position.X - $script:dragCursorX
            $analyzerForm.Top = [System.Windows.Forms.Cursor]::Position.Y - $script:dragCursorY
        }
    })

    $headerPanel.Add_MouseUp({
        $script:dragging = $false
    })

    $analyzerTitlePicBox = New-Object System.Windows.Forms.PictureBox
    $analyzerTitlePicBox.Location = New-Object System.Drawing.Point(0, 0)
    $analyzerTitlePicBox.Size = New-Object System.Drawing.Size(850, 85)
    $analyzerTitlePicBox.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom
    $analyzerTitlePicBox.BackColor = [System.Drawing.Color]::Black

    try {
        $logoPath2 = if ($script:LogoPath) { $script:LogoPath } else { $script:LogoInstallPath }
        if (Test-Path $logoPath2) {
            $imgBytes2 = [System.IO.File]::ReadAllBytes($logoPath2)
            $ms2 = New-Object System.IO.MemoryStream($imgBytes2, 0, $imgBytes2.Length)
            $analyzerTitlePicBox.Image = [System.Drawing.Image]::FromStream($ms2)
        } else {
            throw "Logo not found at $logoPath2"
        }
    } catch {
        $analyzerTitlePicBox.Add_Paint({
            param($sender, $e)
            $font = New-Object System.Drawing.Font("Segoe UI", 20, [System.Drawing.FontStyle]::Bold)
            $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Yellow)
            $sf = New-Object System.Drawing.StringFormat
            $sf.Alignment = [System.Drawing.StringAlignment]::Center
            $sf.LineAlignment = [System.Drawing.StringAlignment]::Center
            $rect = New-Object System.Drawing.RectangleF(0, 0, $sender.Width, $sender.Height)
            $e.Graphics.DrawString("USB LATENCY ANALYZER V3", $font, $brush, $rect, $sf)
            $font.Dispose()
            $brush.Dispose()
        })
    }

    $analyzerTitlePicBox.Add_MouseDown({
        $script:dragging = $true
        $script:dragCursorX = [System.Windows.Forms.Cursor]::Position.X - $analyzerForm.Left
        $script:dragCursorY = [System.Windows.Forms.Cursor]::Position.Y - $analyzerForm.Top
    })

    $analyzerTitlePicBox.Add_MouseMove({
        if ($script:dragging) {
            $analyzerForm.Left = [System.Windows.Forms.Cursor]::Position.X - $script:dragCursorX
            $analyzerForm.Top = [System.Windows.Forms.Cursor]::Position.Y - $script:dragCursorY
        }
    })

    $analyzerTitlePicBox.Add_MouseUp({
        $script:dragging = $false
    })

    $headerPanel.Controls.Add($analyzerTitlePicBox)
    $mainPanel.Controls.Add($headerPanel)

    $subtitle = New-Object System.Windows.Forms.Label
    $subtitle.Location = New-Object System.Drawing.Point(30, 105)
    $subtitle.Size = New-Object System.Drawing.Size(790, 25)
    $subtitle.Text = "Count chips between your device and CPU - More chips = more latency"
    $subtitle.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $subtitle.ForeColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
    $subtitle.TextAlign = "MiddleCenter"
    $subtitle.BackColor = [System.Drawing.Color]::Transparent
    $mainPanel.Controls.Add($subtitle)

    $legend = New-Object System.Windows.Forms.RichTextBox
    $legend.Location = New-Object System.Drawing.Point(30, 135)
    $legend.Size = New-Object System.Drawing.Size(790, 60)
    $legend.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $legend.BackColor = [System.Drawing.Color]::Black
    $legend.BorderStyle = "None"
    $legend.ReadOnly = $true
    $legend.Cursor = [System.Windows.Forms.Cursors]::Arrow

    $legend.SelectionColor = [System.Drawing.Color]::FromArgb(0, 255, 135)
    $legend.AppendText([char]0x25cf + " 0 CHIPS - Direct to CPU (BEST - Lowest Latency)`n")
    $legend.SelectionColor = [System.Drawing.Color]::FromArgb(255, 179, 71)
    $legend.AppendText([char]0x25cf + " 1 CHIP - Through Chipset (GOOD - Normal Latency)`n")
    $legend.SelectionColor = [System.Drawing.Color]::FromArgb(255, 107, 107)
    $legend.AppendText([char]0x25cf + " 2+ CHIPS - Through USB Hub (AVOID - Highest Latency)")

    $mainPanel.Controls.Add($legend)

    $resultsPanel = New-Object System.Windows.Forms.Panel
    $resultsPanel.Location = New-Object System.Drawing.Point(30, 200)
    $resultsPanel.Size = New-Object System.Drawing.Size(790, 350)
    $resultsPanel.BackColor = [System.Drawing.Color]::FromArgb(15, 15, 15)
    $resultsPanel.BorderStyle = "None"

    $results = New-Object System.Windows.Forms.RichTextBox
    $results.Location = New-Object System.Drawing.Point(1, 1)
    $results.Size = New-Object System.Drawing.Size(788, 348)
    $results.BackColor = [System.Drawing.Color]::FromArgb(15, 15, 15)
    $results.ForeColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
    $results.Font = New-Object System.Drawing.Font("Consolas", 10)
    $results.ReadOnly = $true
    $results.BorderStyle = "None"
    $results.ScrollBars = "Vertical"
    $resultsPanel.Controls.Add($results)
    $mainPanel.Controls.Add($resultsPanel)

    $scanBtn = New-Object System.Windows.Forms.Button
    $scanBtn.Location = New-Object System.Drawing.Point(30, 565)
    $scanBtn.Size = New-Object System.Drawing.Size(380, 50)
    $scanBtn.FlatStyle = "Flat"
    $scanBtn.BackColor = [System.Drawing.Color]::FromArgb(26, 6, 6)
    $scanBtn.ForeColor = [System.Drawing.Color]::White
    $scanBtn.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
    $scanBtn.Text = ""
    $scanBtn.Cursor = [System.Windows.Forms.Cursors]::Hand
    $scanBtn.FlatAppearance.BorderSize = 1
    $scanBtn.FlatAppearance.BorderColor = $script:AccentColor
    $scanBtn.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(48, 12, 12)
    $scanBtn.FlatAppearance.MouseDownBackColor = [System.Drawing.Color]::FromArgb(64, 16, 16)

    # Add hover glow effect
    $scanBtn.Add_MouseEnter({
        $this.BackColor = [System.Drawing.Color]::FromArgb(48, 12, 12)
        $this.FlatAppearance.BorderColor = $script:AccentGlow
        $this.FlatAppearance.BorderSize = 2
    })
    
    $scanBtn.Add_MouseLeave({
        $this.BackColor = [System.Drawing.Color]::FromArgb(26, 6, 6)
        $this.FlatAppearance.BorderColor = $script:AccentColor
        $this.FlatAppearance.BorderSize = 1
    })

    $scanBtn.Add_Paint({
        param($sender, $e)
        $g = $e.Graphics
        $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
        
        $titleFont = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
        $descFont = New-Object System.Drawing.Font("Segoe UI", 8)
        $whiteBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
        $grayBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(160, 160, 160))
        
        $g.DrawString("SCAN USB DEVICES", $titleFont, $whiteBrush, 20, 12)
        $g.DrawString("Analyze all connected USB input devices", $descFont, $grayBrush, 20, 32)
        
        $whiteBrush.Dispose()
        $grayBrush.Dispose()
        $titleFont.Dispose()
        $descFont.Dispose()
    })

    $exitBtn = New-Object System.Windows.Forms.Button
    $exitBtn.Location = New-Object System.Drawing.Point(440, 565)
    $exitBtn.Size = New-Object System.Drawing.Size(380, 50)
    $exitBtn.FlatStyle = "Flat"
    $exitBtn.BackColor = [System.Drawing.Color]::FromArgb(26, 6, 6)
    $exitBtn.ForeColor = [System.Drawing.Color]::White
    $exitBtn.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
    $exitBtn.Text = ""
    $exitBtn.Cursor = [System.Windows.Forms.Cursors]::Hand
    $exitBtn.FlatAppearance.BorderSize = 1
    $exitBtn.FlatAppearance.BorderColor = $script:AccentColor
    $exitBtn.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(48, 12, 12)
    $exitBtn.FlatAppearance.MouseDownBackColor = [System.Drawing.Color]::FromArgb(64, 16, 16)

    # Add hover glow effect
    $exitBtn.Add_MouseEnter({
        $this.BackColor = [System.Drawing.Color]::FromArgb(48, 12, 12)
        $this.FlatAppearance.BorderColor = $script:AccentGlow
        $this.FlatAppearance.BorderSize = 2
    })
    
    $exitBtn.Add_MouseLeave({
        $this.BackColor = [System.Drawing.Color]::FromArgb(26, 6, 6)
        $this.FlatAppearance.BorderColor = $script:AccentColor
        $this.FlatAppearance.BorderSize = 1
    })

    $exitBtn.Add_Paint({
        param($sender, $e)
        $g = $e.Graphics
        $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
        
        $titleFont = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
        $descFont = New-Object System.Drawing.Font("Segoe UI", 8)
        $whiteBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
        $grayBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(160, 160, 160))
        
        $g.DrawString("EXIT", $titleFont, $whiteBrush, 20, 12)
        $g.DrawString("Close this application", $descFont, $grayBrush, 20, 32)
        
        $whiteBrush.Dispose()
        $grayBrush.Dispose()
        $titleFont.Dispose()
        $descFont.Dispose()
    })

    $exitBtn.Add_Click({
        $analyzerForm.Close()
    })

    $scanBtn.Add_Click({
        $results.Clear()
        $results.SelectionColor = [System.Drawing.Color]::Yellow
        $results.AppendText("Scanning USB devices...`n`n")
        $analyzerForm.Refresh()
        
        $allDevs = @(Get-PnpDevice -Status OK)
        $usbDevs = $allDevs | Where-Object { $_.InstanceId -match "^USB\\" }
        
        $inputDevs = @()
        foreach ($d in $usbDevs) {
            try {
                $cid = (Get-PnpDeviceProperty -InstanceId $d.InstanceId -KeyName "DEVPKEY_Device_CompatibleIds" -ErrorAction SilentlyContinue).Data
                if ($cid -match "Class_03") {
                    $inputDevs += $d
                }
            } catch {}
        }
        
        $xboxDevs = $allDevs | Where-Object { $_.Class -in @("XboxComposite", "XnaComposite", "XUSBClass") }
        if ($xboxDevs) {
            $inputDevs += $xboxDevs
        }
        
        $deviceData = @()
        $seen = @{}
        
        foreach ($d in $inputDevs) {
            $instId = $d.InstanceId
            $usbParent = $instId
            
            if ($instId -match "^HID\\") {
                try {
                    $parent = Get-PnpDeviceProperty -InstanceId $instId -KeyName "DEVPKEY_Device_Parent" -ErrorAction Stop
                    $usbParent = $parent.Data
                } catch { continue }
            }
            
            $vid = "????"
            $productId = "????"
            if ($usbParent -match "VID_([0-9A-F]{4})") { $vid = $matches[1] }
            if ($usbParent -match "PID_([0-9A-F]{4})") { $productId = $matches[1] }
            
            $key = "${vid}_${productId}"
            if ($seen.ContainsKey($key)) { continue }
            $seen[$key] = $true
            
            $chain = Get-DeviceChain -InstanceId $usbParent
            if (-not $chain.ControllerInfo) { continue }
            
            $devName = $d.FriendlyName
            try {
                $busDesc = (Get-PnpDeviceProperty -InstanceId $usbParent -KeyName "DEVPKEY_Device_BusReportedDeviceDesc" -ErrorAction SilentlyContinue).Data
                if ($busDesc -and $busDesc.Trim()) { $devName = $busDesc.Trim() }
            } catch {}
            
            $deviceData += @{
                Name = $devName
                ChipCount = $chain.ChipCount
                ControllerName = $chain.ControllerInfo.Name
                Platform = $chain.ControllerInfo.Platform
                HubCount = $chain.HubCount
            }
        }
        
        $chip0 = @($deviceData | Where-Object { $_.ChipCount -eq 0 })
        $chip1 = @($deviceData | Where-Object { $_.ChipCount -eq 1 })
        $chip2 = @($deviceData | Where-Object { $_.ChipCount -ge 2 })
        
        $results.SelectionColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
        $results.SelectionFont = New-Object System.Drawing.Font("Consolas", 11, [System.Drawing.FontStyle]::Bold)
        $results.AppendText("FOUND $($deviceData.Count) INPUT DEVICES`n")
        $results.SelectionFont = New-Object System.Drawing.Font("Consolas", 10)
        $results.AppendText(([string][char]0x2550) * 67 + "`n`n")
        
        if ($chip0.Count -gt 0) {
            $results.SelectionColor = [System.Drawing.Color]::FromArgb(0, 255, 135)
            $results.SelectionFont = New-Object System.Drawing.Font("Consolas", 11, [System.Drawing.FontStyle]::Bold)
            $results.AppendText([char]0x25cf + " 0 CHIPS - DIRECT TO CPU ($($chip0.Count) devices)`n")
            $results.SelectionFont = New-Object System.Drawing.Font("Consolas", 10)
            
            foreach ($dev in $chip0) {
                $results.SelectionColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
                $results.AppendText("   " + [char]0x2514 + [char]0x2500 + " ")
                $results.SelectionColor = [System.Drawing.Color]::FromArgb(0, 255, 135)
                $results.AppendText("$($dev.Name)`n")
                $results.SelectionColor = [System.Drawing.Color]::FromArgb(180, 180, 180)
                $results.AppendText("      $($dev.ControllerName) | $($dev.Platform)`n")
            }
            $results.AppendText("`n")
        }
        
        if ($chip1.Count -gt 0) {
            $results.SelectionColor = [System.Drawing.Color]::FromArgb(255, 179, 71)
            $results.SelectionFont = New-Object System.Drawing.Font("Consolas", 11, [System.Drawing.FontStyle]::Bold)
            $results.AppendText([char]0x25cf + " 1 CHIP - THROUGH CHIPSET ($($chip1.Count) devices)`n")
            $results.SelectionFont = New-Object System.Drawing.Font("Consolas", 10)
            
            foreach ($dev in $chip1) {
                $results.SelectionColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
                $results.AppendText("   " + [char]0x2514 + [char]0x2500 + " ")
                $results.SelectionColor = [System.Drawing.Color]::FromArgb(255, 179, 71)
                $results.AppendText("$($dev.Name)`n")
                $results.SelectionColor = [System.Drawing.Color]::FromArgb(180, 180, 180)
                $results.AppendText("      $($dev.ControllerName) | $($dev.Platform)`n")
            }
            $results.AppendText("`n")
        }
        
        if ($chip2.Count -gt 0) {
            $results.SelectionColor = [System.Drawing.Color]::FromArgb(255, 107, 107)
            $results.SelectionFont = New-Object System.Drawing.Font("Consolas", 11, [System.Drawing.FontStyle]::Bold)
            $results.AppendText([char]0x25cf + " 2+ CHIPS - THROUGH HUB ($($chip2.Count) devices)`n")
            $results.SelectionFont = New-Object System.Drawing.Font("Consolas", 10)
            
            foreach ($dev in $chip2) {
                $results.SelectionColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
                $results.AppendText("   " + [char]0x2514 + [char]0x2500 + " ")
                $results.SelectionColor = [System.Drawing.Color]::FromArgb(255, 107, 107)
                $results.AppendText("$($dev.Name)`n")
                $results.SelectionColor = [System.Drawing.Color]::FromArgb(180, 180, 180)
                $results.AppendText("      $($dev.ChipCount) chips | $($dev.HubCount) hub(s)`n")
            }
            $results.AppendText("`n")
        }
        
        $results.SelectionColor = [System.Drawing.Color]::FromArgb(200, 200, 200)
        $results.AppendText(([string][char]0x2550) * 67 + "`n")
        $results.SelectionColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
        $results.AppendText("TIP: Try different USB ports to find the best latency path!")
    })

    $mainPanel.Controls.Add($scanBtn)
    $mainPanel.Controls.Add($exitBtn)
    
    # Add Credits Label (Red text at bottom) for USB Analyzer
    $analyzerCredits = New-Object System.Windows.Forms.Label
    $analyzerCredits.Location = New-Object System.Drawing.Point(0, 625)
    $analyzerCredits.Size = New-Object System.Drawing.Size(850, 25)
    $analyzerCredits.Text = "Created by: @mariusheier"
    $analyzerCredits.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $analyzerCredits.ForeColor = $script:AccentColor
    $analyzerCredits.TextAlign = "MiddleCenter"
    $analyzerCredits.BackColor = [System.Drawing.Color]::Black
    $mainPanel.Controls.Add($analyzerCredits)
    
    $analyzerForm.Controls.Add($mainPanel)

    # ============================================================================
    # RGB BORDER ANIMATION TIMER (USB Analyzer - synced to main window)
    # ============================================================================
    $script:analyzerRgbTimer = New-Object System.Windows.Forms.Timer
    $script:analyzerRgbTimer.Interval = 40

    $script:analyzerRgbTimer.Add_Tick({
        # Read the shared hue from the main window timer - no increment here
        $h = $script:rgbHue / 360.0
        $i = [Math]::Floor($h * 6)
        $f = $h * 6 - $i
        $q = 1 - $f
        $t = $f
        switch ($i % 6) {
            0 { $r = 255; $g = [int]($t * 255); $b = 0 }
            1 { $r = [int]($q * 255); $g = 255; $b = 0 }
            2 { $r = 0; $g = 255; $b = [int]($t * 255) }
            3 { $r = 0; $g = [int]($q * 255); $b = 255 }
            4 { $r = [int]($t * 255); $g = 0; $b = 255 }
            5 { $r = 255; $g = 0; $b = [int]($q * 255) }
        }
        $rgbColorA = [System.Drawing.Color]::FromArgb($r, $g, $b)
        $analyzerForm.BackColor = $rgbColorA
        foreach ($ctrl in $mainPanel.Controls) {
            if ($ctrl -is [System.Windows.Forms.Button]) {
                $ctrl.FlatAppearance.BorderColor = $rgbColorA
            }
        }
    })

    $script:analyzerRgbTimer.Start()

    $analyzerForm.Add_FormClosed({
        $script:analyzerRgbTimer.Stop()
        $script:analyzerRgbTimer.Dispose()
    })

    $analyzerForm.Add_KeyDown({
        param($sender, $e)
        if ($e.KeyCode -eq "Escape") {
            $analyzerForm.Close()
        }
    })

    $analyzerForm.Add_Shown({$analyzerForm.Activate()})
    [void]$analyzerForm.ShowDialog()
}

# ============================================================================
# GAMEBAR NOTIFICATION FIX FUNCTION
# ============================================================================

function Show-GameBarDialog {
    param(
        [string]$Title,
        [string]$Subtitle,
        [string[]]$Lines,
        [string]$ApplyLabel   = "",
        [string]$RestoreLabel = "",
        [string]$CancelLabel  = "CANCEL",
        [bool]$IsApplied      = $false,
        [bool]$ResultOnly     = $false,
        [string]$Credits      = "",
        [bool]$ShowStatusBadge = $true
    )

    # Dimensions
    $W = 620
    $H = if ($ResultOnly) { 390 } else { 480 }

    $dlg = New-Object System.Windows.Forms.Form
    $dlg.Text            = ""
    $dlg.Width           = $W
    $dlg.Height          = $H
    $dlg.StartPosition   = "CenterScreen"
    $dlg.FormBorderStyle = "None"
    $dlg.BackColor       = [System.Drawing.Color]::Yellow   # RGB border will replace this
    $dlg.TopMost         = $false

    # Drag state
    $script:gbDrag = $false; $script:gbDX = 0; $script:gbDY = 0

    # Inner dark panel (3px inset for RGB border to show)
    $inner = New-Object System.Windows.Forms.Panel
    $inner.Location  = New-Object System.Drawing.Point(3, 3)
    $inner.Size      = New-Object System.Drawing.Size(($W - 6), ($H - 6))
    $inner.BackColor = [System.Drawing.Color]::FromArgb(10, 10, 10)
    $dlg.Controls.Add($inner)

    # ── RGB border timer (synced to main window hue) ──────────────────────────
    $script:gbHue = if ($script:rgbHue) { $script:rgbHue } else { 0 }
    $gbRgbTimer = New-Object System.Windows.Forms.Timer
    $gbRgbTimer.Interval = 40
    $gbRgbTimer.Add_Tick({
        $script:gbHue = ($script:gbHue + 2) % 360
        $h = $script:gbHue / 360.0
        $i = [Math]::Floor($h * 6)
        $f = $h * 6 - $i
        $q = 1 - $f; $t = $f
        switch ($i % 6) {
            0 { $r = 255; $g = [int]($t*255); $b = 0 }
            1 { $r = [int]($q*255); $g = 255; $b = 0 }
            2 { $r = 0; $g = 255; $b = [int]($t*255) }
            3 { $r = 0; $g = [int]($q*255); $b = 255 }
            4 { $r = [int]($t*255); $g = 0; $b = 255 }
            5 { $r = 255; $g = 0; $b = [int]($q*255) }
        }
        $dlg.BackColor = [System.Drawing.Color]::FromArgb($r, $g, $b)
    })
    $gbRgbTimer.Start()
    $dlg.Add_FormClosed({ $gbRgbTimer.Stop(); $gbRgbTimer.Dispose() })

    # ── Title bar (GDI+ painted header - matches MARIUS style) ──────────────
    $titleBar = New-Object System.Windows.Forms.Panel
    $titleBar.Location  = New-Object System.Drawing.Point(0, 0)
    $titleBar.Size      = New-Object System.Drawing.Size(($W - 6), 70)
    $titleBar.BackColor = [System.Drawing.Color]::FromArgb(10, 10, 10)
    $inner.Controls.Add($titleBar)

    $titleBar.Add_MouseDown({ $script:gbDrag=$true; $script:gbDX=[System.Windows.Forms.Cursor]::Position.X-$dlg.Left; $script:gbDY=[System.Windows.Forms.Cursor]::Position.Y-$dlg.Top })
    $titleBar.Add_MouseMove({ if($script:gbDrag){ $dlg.Left=[System.Windows.Forms.Cursor]::Position.X-$script:gbDX; $dlg.Top=[System.Windows.Forms.Cursor]::Position.Y-$script:gbDY } })
    $titleBar.Add_MouseUp({ $script:gbDrag=$false })

    # PictureBox paints the title as Impact italic yellow - same as MARIUS header
    $picTitle = New-Object System.Windows.Forms.PictureBox
    $picTitle.Location  = New-Object System.Drawing.Point(0, 0)
    $picTitle.Size      = New-Object System.Drawing.Size(($W - 50), 70)
    $picTitle.BackColor = [System.Drawing.Color]::FromArgb(10, 10, 10)
    $dlgTitle = $Title
    $picTitle.Add_Paint({
        param($sender, $e)
        $g = $e.Graphics
        $g.SmoothingMode     = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
        $shadowFont  = New-Object System.Drawing.Font("Impact", 22, [System.Drawing.FontStyle]::Italic)
        $shadowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(80, 0, 0, 0))
        $titleFont   = New-Object System.Drawing.Font("Impact", 22, [System.Drawing.FontStyle]::Italic)
        $titleBrush  = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Yellow)
        $g.DrawString($dlgTitle, $shadowFont, $shadowBrush, 22, 17)
        $g.DrawString($dlgTitle, $titleFont,  $titleBrush,  20, 15)
        $shadowFont.Dispose(); $shadowBrush.Dispose()
        $titleFont.Dispose();  $titleBrush.Dispose()
    }.GetNewClosure())
    $picTitle.Add_MouseDown({ $script:gbDrag=$true; $script:gbDX=[System.Windows.Forms.Cursor]::Position.X-$dlg.Left; $script:gbDY=[System.Windows.Forms.Cursor]::Position.Y-$dlg.Top })
    $picTitle.Add_MouseMove({ if($script:gbDrag){ $dlg.Left=[System.Windows.Forms.Cursor]::Position.X-$script:gbDX; $dlg.Top=[System.Windows.Forms.Cursor]::Position.Y-$script:gbDY } })
    $picTitle.Add_MouseUp({ $script:gbDrag=$false })
    $titleBar.Controls.Add($picTitle)

    # X button - plain ASCII X, no unicode issues
    $btnX = New-Object System.Windows.Forms.Button
    $btnX.Location  = New-Object System.Drawing.Point(($W - 52), 18)
    $btnX.Size      = New-Object System.Drawing.Size(32, 32)
    $btnX.Text      = "X"
    $btnX.FlatStyle = "Flat"
    $btnX.BackColor = [System.Drawing.Color]::FromArgb(10, 10, 10)
    $btnX.ForeColor = [System.Drawing.Color]::FromArgb(140, 140, 140)
    $btnX.Font      = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $btnX.FlatAppearance.BorderSize = 0
    $btnX.Cursor    = [System.Windows.Forms.Cursors]::Hand
    $btnX.Add_Click({ $dlg.Tag = "cancel"; $dlg.Close() })
    $btnX.Add_MouseEnter({ $btnX.ForeColor = [System.Drawing.Color]::White })
    $btnX.Add_MouseLeave({ $btnX.ForeColor = [System.Drawing.Color]::FromArgb(140,140,140) })
    $titleBar.Controls.Add($btnX)

    # Divider line
    $div = New-Object System.Windows.Forms.Panel
    $div.Location  = New-Object System.Drawing.Point(0, 70)
    $div.Size      = New-Object System.Drawing.Size(($W - 6), 2)
    $div.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 40)
    $inner.Controls.Add($div)

    # Subtitle
    $lblSub = New-Object System.Windows.Forms.Label
    $lblSub.Location  = New-Object System.Drawing.Point(20, 82)
    $lblSub.Size      = New-Object System.Drawing.Size(($W - 46), 26)
    $lblSub.Text      = $Subtitle
    $lblSub.Font      = New-Object System.Drawing.Font("Segoe UI", 9)
    $lblSub.ForeColor = [System.Drawing.Color]::FromArgb(160, 160, 160)
    $lblSub.BackColor = [System.Drawing.Color]::Transparent
    $inner.Controls.Add($lblSub)

    # Detail lines
    $yPos = 116
    foreach ($line in $Lines) {
        if ($line -eq "") { $yPos += 10; continue }
        $isHeader = $line.StartsWith("##")
        $text = $line.TrimStart("#").Trim()
        $lbl = New-Object System.Windows.Forms.Label
        $lbl.Location  = New-Object System.Drawing.Point(20, $yPos)
        $lbl.Size      = New-Object System.Drawing.Size(($W - 46), 24)
        $lbl.Text      = $text
        $lbl.BackColor = [System.Drawing.Color]::Transparent
        if ($isHeader) {
            $lbl.Font      = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
            $lbl.ForeColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
        } else {
            $lbl.Font      = New-Object System.Drawing.Font("Segoe UI", 9)
            $lbl.ForeColor = [System.Drawing.Color]::FromArgb(150, 150, 150)
        }
        $inner.Controls.Add($lbl)
        $yPos += 24
    }

    if (-not $ResultOnly) {
        if ($ShowStatusBadge) {
            # Status badge
            $statusBg = New-Object System.Windows.Forms.Panel
            $statusBg.Location  = New-Object System.Drawing.Point(20, ($H - 122))
            $statusBg.Size      = New-Object System.Drawing.Size(($W - 46), 28)
            $statusBg.BackColor = [System.Drawing.Color]::FromArgb(22, 22, 22)
            $inner.Controls.Add($statusBg)

            $badge = New-Object System.Windows.Forms.Label
            $badge.Location  = New-Object System.Drawing.Point(0, 0)
            $badge.Size      = New-Object System.Drawing.Size(($W - 46), 28)
            $badge.Text      = if ($IsApplied) { "  >> STATUS: CURRENTLY APPLIED" } else { "  >> STATUS: NOT APPLIED" }
            $badge.Font      = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
            $badge.ForeColor = if ($IsApplied) { [System.Drawing.Color]::FromArgb(80,210,80) } else { [System.Drawing.Color]::FromArgb(210,70,70) }
            $badge.BackColor = [System.Drawing.Color]::Transparent
            $badge.TextAlign = "MiddleLeft"
            $statusBg.Controls.Add($badge)
        }

        # Two buttons centred, with RGB border panels behind them
        $btnW   = 220
        $btnH   = 50
        $btnGap = 24
        $btnY   = $H - 88
        $totalW = ($btnW * 2) + $btnGap
        $startX = [int](($W - 6 - $totalW) / 2)

        # RGB wrapper panels (2px border, button sits 2px inset)
        $rgbApplyPanel = New-Object System.Windows.Forms.Panel
        $rgbApplyPanel.Location  = New-Object System.Drawing.Point($startX, $btnY)
        $rgbApplyPanel.Size      = New-Object System.Drawing.Size(($btnW + 4), ($btnH + 4))
        $rgbApplyPanel.BackColor = [System.Drawing.Color]::Yellow
        $inner.Controls.Add($rgbApplyPanel)

        $rgbRestorePanel = New-Object System.Windows.Forms.Panel
        $rgbRestorePanel.Location  = New-Object System.Drawing.Point(($startX + $btnW + 4 + $btnGap), $btnY)
        $rgbRestorePanel.Size      = New-Object System.Drawing.Size(($btnW + 4), ($btnH + 4))
        $rgbRestorePanel.BackColor = [System.Drawing.Color]::Yellow
        $inner.Controls.Add($rgbRestorePanel)

        # Hook the existing RGB timer to also update the button border panels
        $gbRgbTimer.Add_Tick({
            $c = $dlg.BackColor
            $rgbApplyPanel.BackColor   = $c
            $rgbRestorePanel.BackColor = $c
        })

        $btnApply = New-Object System.Windows.Forms.Button
        $btnApply.Location  = New-Object System.Drawing.Point(2, 2)
        $btnApply.Size      = New-Object System.Drawing.Size($btnW, $btnH)
        $btnApply.Text      = $ApplyLabel
        $btnApply.FlatStyle = "Flat"
        $btnApply.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 20)
        $btnApply.ForeColor = [System.Drawing.Color]::Yellow
        $btnApply.Font      = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
        $btnApply.FlatAppearance.BorderSize  = 0
        $btnApply.Cursor    = [System.Windows.Forms.Cursors]::Hand
        $btnApply.Add_Click({ $dlg.Tag = "apply"; $dlg.Close() })
        $btnApply.Add_MouseEnter({ $btnApply.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 12) })
        $btnApply.Add_MouseLeave({ $btnApply.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 20) })
        $rgbApplyPanel.Controls.Add($btnApply)

        $btnRestore = New-Object System.Windows.Forms.Button
        $btnRestore.Location  = New-Object System.Drawing.Point(2, 2)
        $btnRestore.Size      = New-Object System.Drawing.Size($btnW, $btnH)
        $btnRestore.Text      = $RestoreLabel
        $btnRestore.FlatStyle = "Flat"
        $btnRestore.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 20)
        $btnRestore.ForeColor = [System.Drawing.Color]::FromArgb(220, 50, 50)
        $btnRestore.Font      = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
        $btnRestore.FlatAppearance.BorderSize  = 0
        $btnRestore.Cursor    = [System.Windows.Forms.Cursors]::Hand
        $btnRestore.Add_Click({ $dlg.Tag = "restore"; $dlg.Close() })
        $btnRestore.Add_MouseEnter({ $btnRestore.BackColor = [System.Drawing.Color]::FromArgb(40, 15, 15) })
        $btnRestore.Add_MouseLeave({ $btnRestore.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 20) })
        $rgbRestorePanel.Controls.Add($btnRestore)

        # Credits
        $lblCredits = New-Object System.Windows.Forms.Label
        $lblCredits.Location  = New-Object System.Drawing.Point(0, ($H - 30))
        $lblCredits.Size      = New-Object System.Drawing.Size(($W - 6), 20)
        $lblCredits.Text      = $Credits
        $lblCredits.Font      = New-Object System.Drawing.Font("Segoe UI", 8)
        $lblCredits.ForeColor = [System.Drawing.Color]::FromArgb(100, 100, 100)
        $lblCredits.BackColor = [System.Drawing.Color]::Transparent
        $lblCredits.TextAlign = "MiddleCenter"
        $inner.Controls.Add($lblCredits)

    } else {
        # Single OK button centred with RGB border
        $okBtnW = 220; $okBtnH = 50
        $okX = [int](($W - 6 - $okBtnW - 4) / 2)
        $okY = $H - 84

        $rgbOkPanel = New-Object System.Windows.Forms.Panel
        $rgbOkPanel.Location  = New-Object System.Drawing.Point($okX, $okY)
        $rgbOkPanel.Size      = New-Object System.Drawing.Size(($okBtnW + 4), ($okBtnH + 4))
        $rgbOkPanel.BackColor = [System.Drawing.Color]::Yellow
        $inner.Controls.Add($rgbOkPanel)

        $gbRgbTimer.Add_Tick({ $rgbOkPanel.BackColor = $dlg.BackColor })

        $btnOk = New-Object System.Windows.Forms.Button
        $btnOk.Location  = New-Object System.Drawing.Point(2, 2)
        $btnOk.Size      = New-Object System.Drawing.Size($okBtnW, $okBtnH)
        $btnOk.Text      = "OK"
        $btnOk.FlatStyle = "Flat"
        $btnOk.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 20)
        $btnOk.ForeColor = [System.Drawing.Color]::Yellow
        $btnOk.Font      = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
        $btnOk.FlatAppearance.BorderSize = 0
        $btnOk.Cursor    = [System.Windows.Forms.Cursors]::Hand
        $btnOk.Add_Click({ $dlg.Tag = "ok"; $dlg.Close() })
        $btnOk.Add_MouseEnter({ $btnOk.BackColor = [System.Drawing.Color]::FromArgb(40,40,12) })
        $btnOk.Add_MouseLeave({ $btnOk.BackColor = [System.Drawing.Color]::FromArgb(20,20,20) })
        $rgbOkPanel.Controls.Add($btnOk)
    }

    $dlg.Add_KeyDown({ param($s,$e); if($e.KeyCode -eq "Escape"){ $dlg.Tag="cancel"; $dlg.Close() } })
    [void]$dlg.ShowDialog()
    return $dlg.Tag
}

function Invoke-GameBarNotificationFix {
    # Check current state
    $isApplied = (Get-ItemProperty "Registry::HKCR\ms-gamebar" -Name "NoOpenWith" -ErrorAction SilentlyContinue) -ne $null

    # ── Styled confirm dialog ─────────────────────────────────────────────────
    $choice = Show-GameBarDialog `
        -Title        "GAMEBAR NOTIFICATION FIX" `
        -Subtitle     "Select an action below:" `
        -Lines        @(
            "## What this fix does:",
            "  [+]  Disables GameDVR and AppCapture",
            "  [+]  Blocks controller GameBar hotkeys",
            "  [+]  Hijacks ms-gamebar URI handlers",
            "  [+]  Deactivates PresenceWriter service",
            "  [+]  Kills running GameBar process",
            "",
            "  Recommended for 8K polling rate controllers."
        ) `
        -ApplyLabel   "APPLY" `
        -RestoreLabel "RESTORE" `
        -CancelLabel  "CANCEL" `
        -IsApplied    $isApplied `
        -Credits      "GameBar fix by: @FR33THY"

    if ($choice -eq "cancel" -or $choice -eq $null) { return }
    $cl     = if ($choice -eq "apply") { 'apply' } else { 'restore' }
    $toggle = if ($cl -eq 'apply') { 0 } else { 1 }

    # ── HKCU tweaks (no admin needed) ────────────────────────────────────────
    sp "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" "AppCaptureEnabled"       $toggle -type dword -force -ea 0
    sp "HKCU:\System\GameConfigStore"                            "GameDVR_Enabled"          $toggle -type dword -force -ea 0
    sp "HKCU:\SOFTWARE\Microsoft\GameBar" "UseNexusForGameBarEnabled" $toggle -type dword -force -ea 0
    sp "HKCU:\SOFTWARE\Microsoft\GameBar" "GamepadNexusChordEnabled"  $toggle -type dword -force -ea 0

    # ── Admin block (HKCR + HKLM changes) ────────────────────────────────────
    $psBlock = [scriptblock]::Create(@"
        `$toggle = $toggle
        `$cl     = '$cl'

        "ms-gamebar","ms-gamebarservices","ms-gamingoverlay" | ForEach-Object {
            if (!(Test-Path "Registry::HKCR\`$_\shell"))              { New-Item "Registry::HKCR\`$_\shell"              -Force | Out-Null }
            if (!(Test-Path "Registry::HKCR\`$_\shell\open"))         { New-Item "Registry::HKCR\`$_\shell\open"         -Force | Out-Null }
            if (!(Test-Path "Registry::HKCR\`$_\shell\open\command")) { New-Item "Registry::HKCR\`$_\shell\open\command" -Force | Out-Null }
            Set-ItemProperty "Registry::HKCR\`$_" "(Default)"    "URL:`$_" -Force
            Set-ItemProperty "Registry::HKCR\`$_" "URL Protocol" ""        -Force
            if (`$toggle -eq 0) {
                Set-ItemProperty "Registry::HKCR\`$_"                    "NoOpenWith" ""                                              -Force
                Set-ItemProperty "Registry::HKCR\`$_\shell\open\command" "(Default)"  "`"`$env:SystemRoot\System32\systray.exe`"" -Force
            } else {
                Remove-ItemProperty "Registry::HKCR\`$_" "NoOpenWith" -Force -ErrorAction SilentlyContinue
                Remove-Item         "Registry::HKCR\`$_\shell" -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        `$presencePath = "HKLM:\SOFTWARE\Microsoft\WindowsRuntime\ActivatableClassId\Windows.Gaming.GameBar.PresenceServer.Internal.PresenceWriter"
        if (Test-Path `$presencePath) {
            Set-ItemProperty `$presencePath "ActivationType" (if (`$toggle -eq 0) { 0 } else { 1 }) -Force -ErrorAction SilentlyContinue
        }

        if (`$toggle -eq 0) {
            Stop-Process -Force -Name GameBar -ErrorAction SilentlyContinue
            cmd /c "sc stop GameInputSvc >nul 2>&1"
            "gamingservices","gamingservicesnet","GameInputRedistService" | ForEach-Object {
                Stop-Process -Name `$_ -Force -ErrorAction SilentlyContinue
            }
        }
"@)

    $isAdmin = [Security.Principal.WindowsIdentity]::GetCurrent().Groups.Value -contains 'S-1-5-32-544'
    if ($isAdmin) { . $psBlock }
    else {
        $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($psBlock.ToString()))
        Start-Process powershell -ArgumentList "-nop -enc $encoded" -Verb RunAs -Wait -ErrorAction SilentlyContinue
    }

    # ── Styled result dialog ──────────────────────────────────────────────────
    if ($cl -eq 'apply') {
        Show-GameBarDialog `
            -Title      "GAMEBAR REMOVED" `
            -Subtitle   "All changes applied successfully." `
            -Lines      @(
                "## Changes applied:",
                "  [+]  GameDVR / AppCapture disabled",
                "  [+]  Controller GameBar hotkeys disabled",
                "  [+]  ms-gamebar URI handlers blocked",
                "  [+]  PresenceWriter service deactivated",
                "  [+]  GameBar process stopped"
            ) `
            -ResultOnly $true | Out-Null
    } else {
        Show-GameBarDialog `
            -Title      "GAMEBAR RESTORED" `
            -Subtitle   "All changes reverted to Windows defaults." `
            -Lines      @(
                "## Changes restored:",
                "  [-]  GameDVR / AppCapture re-enabled",
                "  [-]  Controller GameBar hotkeys re-enabled",
                "  [-]  ms-gamebar URI handlers restored",
                "  [-]  PresenceWriter service re-activated"
            ) `
            -ResultOnly $true | Out-Null
    }
}

function Invoke-UninstallHIDUSBF {
    # ── Styled confirm dialog ─────────────────────────────────────────────────
    $choice = Show-GameBarDialog `
        -Title        "UNINSTALL HIDUSBF" `
        -Subtitle     "This will completely remove HIDUSBF from your system." `
        -Lines        @(
            "## Steps that will be performed:",
            "  [+]  Remove hidusbf.sys from System32\drivers",
            "  [+]  Remove hidusbf.dll files if present",
            "  [+]  Remove common HIDUSBF folders",
            "  [+]  Verify removal",
            "",
            "  A restart may be needed to finish removal.",
            "  Downloaded ZIP files will NOT be removed."
        ) `
        -ApplyLabel     "UNINSTALL" `
        -RestoreLabel   "CANCEL" `
        -ShowStatusBadge $false

    if ($choice -ne "apply") { return }

    # ── Admin block (mirrors Uninstall_HIDUSBF_Complete.bat) ─────────────────
    $psBlock = [scriptblock]::Create(@'
        $result = @{ SysRemoved = $false; SysStillPresent = $false; FoldersRemoved = 0 }

        # Step 1: driver + dll files
        $sysPath = "C:\Windows\System32\drivers\hidusbf.sys"
        if (Test-Path $sysPath) {
            Remove-Item -Path $sysPath -Force -ErrorAction SilentlyContinue
        }
        "C:\Windows\System32\hidusbf.dll","C:\Windows\SysWOW64\hidusbf.dll" | ForEach-Object {
            if (Test-Path $_) { Remove-Item -Path $_ -Force -ErrorAction SilentlyContinue }
        }

        # Step 2: verify driver removal
        $result.SysStillPresent = Test-Path $sysPath
        $result.SysRemoved = -not $result.SysStillPresent

        # Step 3: common folders (downloaded ZIPs are left alone)
        $folders = @(
            "C:\Tools\HIDUSBF",
            "C:\Program Files\HIDUSBF",
            "C:\Program Files (x86)\HIDUSBF",
            "$env:USERPROFILE\Downloads\HIDUSBF",
            "$env:USERPROFILE\Desktop\HIDUSBF"
        )
        foreach ($f in $folders) {
            if (Test-Path $f) {
                Remove-Item -Path $f -Recurse -Force -ErrorAction SilentlyContinue
                $result.FoldersRemoved++
            }
        }

        $resultPath = "$env:TEMP\marius_hidusbf_uninstall_result.json"
        ($result | ConvertTo-Json -Compress) | Out-File -FilePath $resultPath -Encoding utf8 -Force
'@)

    $resultPath = "$env:TEMP\marius_hidusbf_uninstall_result.json"
    Remove-Item -Path $resultPath -Force -ErrorAction SilentlyContinue

    $isAdmin = [Security.Principal.WindowsIdentity]::GetCurrent().Groups.Value -contains 'S-1-5-32-544'
    if ($isAdmin) {
        . $psBlock
    } else {
        $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($psBlock.ToString()))
        Start-Process powershell -ArgumentList "-nop -enc $encoded" -Verb RunAs -Wait -ErrorAction SilentlyContinue
    }

    $uninstallResult = if (Test-Path $resultPath) {
        Get-Content $resultPath -Raw | ConvertFrom-Json
    } else { $null }
    Remove-Item -Path $resultPath -Force -ErrorAction SilentlyContinue

    # ── Styled result dialog ──────────────────────────────────────────────────
    $sysRemoved = if ($uninstallResult) { $uninstallResult.SysRemoved } else { -not (Test-Path "C:\Windows\System32\drivers\hidusbf.sys") }
    $foldersRemoved = if ($uninstallResult) { $uninstallResult.FoldersRemoved } else { 0 }

    $resultLines = @(
        "## Uninstall summary:",
        "  [+]  Driver files removed",
        "  [+]  hidusbf.dll removed (System32 / SysWOW64)",
        "  [+]  $foldersRemoved HIDUSBF folder(s) removed",
        ""
    )
    if ($sysRemoved) {
        $resultLines += "  hidusbf.sys: REMOVED"
    } else {
        $resultLines += "  hidusbf.sys: STILL PRESENT (restart required)"
    }
    $resultLines += @("", "  Restart your computer whenever you're ready", "  to finish removing HIDUSBF.")

    Show-GameBarDialog `
        -Title      "HIDUSBF UNINSTALLED" `
        -Subtitle   "Restart when convenient to finish removal." `
        -Lines      $resultLines `
        -ResultOnly $true | Out-Null
}

# ============================================================================
# ACCENT COLOR / THEME CUSTOMIZATION
# ============================================================================
# The whole app's "gold" look is driven off a single base color. Changing
# $script:AccentColor and calling Update-AccentPalette recomputes every
# derived shade (hover glow, gradient borders) used by the tiles, form
# border, and labels throughout the UI.

function Blend-Color {
    param(
        [System.Drawing.Color]$Base,
        [System.Drawing.Color]$Target,
        [double]$Ratio
    )
    $r = [int]($Base.R + (($Target.R - $Base.R) * $Ratio))
    $g = [int]($Base.G + (($Target.G - $Base.G) * $Ratio))
    $b = [int]($Base.B + (($Target.B - $Base.B) * $Ratio))
    $r = [Math]::Max(0, [Math]::Min(255, $r))
    $g = [Math]::Max(0, [Math]::Min(255, $g))
    $b = [Math]::Max(0, [Math]::Min(255, $b))
    return [System.Drawing.Color]::FromArgb($r, $g, $b)
}

# Color is a value type, so passing $null for one into a brush/pen constructor
# makes PowerShell's overload resolution fail with "Cannot find an overload"
# instead of a normal null-reference error. Every place that reads a
# $script:-scoped color into a Paint handler runs it through this first so a
# timing hiccup degrades to a fallback color instead of crashing the paint.
function Get-SafeColor {
    param($Value, [System.Drawing.Color]$Fallback)
    if ($null -eq $Value) { return $Fallback }
    return $Value
}

function Update-AccentPalette {
    param([System.Drawing.Color]$Color)

    $white = [System.Drawing.Color]::White
    $black = [System.Drawing.Color]::Black

    $script:AccentColor       = $Color
    $script:AccentGlow        = Blend-Color -Base $Color -Target $white -Ratio 0.35
    $script:AccentBorderTopN  = Blend-Color -Base $Color -Target $white -Ratio 0.15
    $script:AccentBorderBotN  = Blend-Color -Base $Color -Target $black -Ratio 0.35
    $script:AccentBorderTopH  = Blend-Color -Base $Color -Target $white -Ratio 0.45
    $script:AccentBorderBotH  = Blend-Color -Base $Color -Target $white -Ratio 0.12
}

function Update-BackgroundPalette {
    param([System.Drawing.Color]$Color)

    $white = [System.Drawing.Color]::White
    $black = [System.Drawing.Color]::Black

    # $Color is the base app background (panels, tile faces). Everything else
    # here is a derived shade so tiles/icons keep the same layered look no
    # matter what background color is chosen.
    $script:BgColor     = $Color
    $script:BgTileTopN  = Blend-Color -Base $Color -Target $white -Ratio 0.35
    $script:BgTileBotN  = Blend-Color -Base $Color -Target $black -Ratio 0.25
    $script:BgTileTopH  = Blend-Color -Base $Color -Target $white -Ratio 0.55
    $script:BgTileBotH  = Blend-Color -Base $Color -Target $black -Ratio 0.05
    $script:BgIconTop   = Blend-Color -Base $Color -Target $white -Ratio 0.60
    $script:BgIconBot   = Blend-Color -Base $Color -Target $black -Ratio 0.20
}

# Sensible defaults so anything painted before Read-Settings runs still has
# valid colors to draw with.
Update-AccentPalette -Color ([System.Drawing.Color]::FromArgb(212, 175, 55))
Update-BackgroundPalette -Color ([System.Drawing.Color]::FromArgb(26, 6, 6))

function Get-CurrentTilePalette {
    # The toolbox tiles are built inside a function and their Paint handler
    # is wrapped in .GetNewClosure() (needed so each tile keeps its own
    # Name/Desc instead of all showing the last item's). That closure freezes
    # any $script: color variable read directly inside it to whatever value
    # it had the moment the closure was created - so toolbox tiles never
    # picked up later Color Customizer changes even though main-menu tiles
    # (built at top level, no closure) did. Routing the lookup through a
    # plain function call sidesteps that: a function body always resolves
    # $script: against the real script scope, live, on every call.
    return [PSCustomObject]@{
        BgTopN     = $script:BgTileTopN
        BgBotN     = $script:BgTileBotN
        BgTopH     = $script:BgTileTopH
        BgBotH     = $script:BgTileBotH
        BorderTopN = $script:AccentBorderTopN
        BorderBotN = $script:AccentBorderBotN
        BorderTopH = $script:AccentBorderTopH
        BorderBotH = $script:AccentBorderBotH
        Accent     = $script:AccentColor
        Glow       = $script:AccentGlow
        IconTop    = $script:BgIconTop
        IconBot    = $script:BgIconBot
    }
}

function Refresh-AccentUI {
    # Repaints every persistent control that carries the accent color so a
    # theme change shows up immediately without restarting the app. Called
    # once ShowDialog() has fully returned (see the COLOR_CUSTOMIZER click
    # handler) rather than from inside the color dialog's own button
    # handlers - calling it there, right as the modal dialog is still in
    # the middle of closing, could throw and get silently swallowed,
    # leaving tiles never actually repainted.
    try {
        if ($script:form) { $script:form.BackColor = $script:AccentColor }
        if ($script:mainPanel -and $script:BgColor) { $script:mainPanel.BackColor = $script:BgColor }
        if ($script:mainTiles)    { foreach ($c in $script:mainTiles)    { if ($script:BgColor) { $c.BackColor = $script:BgColor }; $c.Invalidate($true) } }
        if ($script:toolboxTiles) { foreach ($c in $script:toolboxTiles) { if ($script:BgColor) { $c.BackColor = $script:BgColor }; $c.Invalidate($true) } }
        if ($versionLabel) { $versionLabel.ForeColor = $script:AccentColor }
        if ($creditsLabel) { $creditsLabel.ForeColor = $script:AccentColor }
        if ($muteBtn) { $muteBtn.Invalidate() }
        if ($script:volSliderPanel) { $script:volSliderPanel.Invalidate() }
        # Invalidate the whole panel tree, then force a synchronous WM_PAINT
        # right now instead of waiting for the message queue - right after a
        # modal ShowDialog() closes, a plain .Refresh() on each tile can get
        # coalesced/dropped so the change doesn't visibly land until some
        # later repaint (e.g. next hover). Update() + DoEvents() forces it.
        if ($script:mainPanel) {
            $script:mainPanel.Invalidate($true)
            $script:mainPanel.Update()
        }
        if ($script:form) { $script:form.Update() }
        [System.Windows.Forms.Application]::DoEvents()
    } catch {}
}

# ============================================================================
# SETTINGS HELPERS (Settings.ini in %APPDATA%\MARIUS)
# ============================================================================

function Read-Settings {
    $script:MusicEnabled = $false   # Muted by default
    $script:MusicVolume  = 38       # 38% volume by default
    $accentColor = [System.Drawing.Color]::FromArgb(212, 175, 55)   # Default gold
    $bgColor     = [System.Drawing.Color]::FromArgb(26, 6, 6)       # Default background
    try {
        if (Test-Path $script:SettingsPath) {
            Get-Content $script:SettingsPath | ForEach-Object {
                if ($_ -match '^\s*MusicEnabled\s*=\s*(.+)') {
                    $script:MusicEnabled = ($matches[1].Trim() -eq "True")
                }
                if ($_ -match '^\s*MusicVolume\s*=\s*(\d+)') {
                    $v = [int]$matches[1]
                    $script:MusicVolume = [Math]::Max(0, [Math]::Min(100, $v))
                }
                if ($_ -match '^\s*AccentColor\s*=\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)') {
                    $ar = [Math]::Max(0, [Math]::Min(255, [int]$matches[1]))
                    $ag = [Math]::Max(0, [Math]::Min(255, [int]$matches[2]))
                    $ab = [Math]::Max(0, [Math]::Min(255, [int]$matches[3]))
                    $accentColor = [System.Drawing.Color]::FromArgb($ar, $ag, $ab)
                }
                if ($_ -match '^\s*BackgroundColor\s*=\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)') {
                    $br = [Math]::Max(0, [Math]::Min(255, [int]$matches[1]))
                    $bg = [Math]::Max(0, [Math]::Min(255, [int]$matches[2]))
                    $bb = [Math]::Max(0, [Math]::Min(255, [int]$matches[3]))
                    $bgColor = [System.Drawing.Color]::FromArgb($br, $bg, $bb)
                }
            }
        }
    } catch {}
    Update-AccentPalette -Color $accentColor
    Update-BackgroundPalette -Color $bgColor
}

function Save-Settings {
    try {
        if (-not (Test-Path $script:InstallDir)) {
            New-Item -ItemType Directory -Path $script:InstallDir -Force | Out-Null
        }
        $val = if ($script:MusicEnabled) { "True" } else { "False" }
        $vol = if ($null -ne $script:MusicVolume) { $script:MusicVolume } else { 38 }
        $ac  = if ($script:AccentColor) { $script:AccentColor } else { [System.Drawing.Color]::FromArgb(212, 175, 55) }
        $accentStr = "$($ac.R),$($ac.G),$($ac.B)"
        $bc  = if ($script:BgColor) { $script:BgColor } else { [System.Drawing.Color]::FromArgb(26, 6, 6) }
        $bgStr = "$($bc.R),$($bc.G),$($bc.B)"

        if (-not (Test-Path $script:SettingsPath)) {
            # File doesn't exist yet - create it fresh with defaults + comments
            $lines = @(
                "MusicEnabled=$val",
                "MusicVolume=$vol",
                "AccentColor=$accentStr",
                "BackgroundColor=$bgStr",
                "",
                "# MusicEnabled:     True or False",
                "# MusicVolume:      0 to 100",
                "# AccentColor:      R,G,B (0-255 each)",
                "# BackgroundColor:  R,G,B (0-255 each)"
            )
            Set-Content -Path $script:SettingsPath -Value $lines -Encoding UTF8
        } else {
            # File exists - surgically update only the known keys.
            # All other content (comments, custom keys, whitespace) is preserved.
            $raw = Get-Content $script:SettingsPath
            $updatedEnabled = $false
            $updatedVolume  = $false
            $updatedAccent  = $false
            $updatedBg      = $false
            $out = $raw | ForEach-Object {
                if ($_ -match '^\s*MusicEnabled\s*=') { $updatedEnabled = $true; "MusicEnabled=$val" }
                elseif ($_ -match '^\s*MusicVolume\s*=') { $updatedVolume = $true; "MusicVolume=$vol" }
                elseif ($_ -match '^\s*AccentColor\s*=') { $updatedAccent = $true; "AccentColor=$accentStr" }
                elseif ($_ -match '^\s*BackgroundColor\s*=') { $updatedBg = $true; "BackgroundColor=$bgStr" }
                else { $_ }
            }
            # Append any keys that were missing entirely
            if (-not $updatedEnabled) { $out += "MusicEnabled=$val" }
            if (-not $updatedVolume)  { $out += "MusicVolume=$vol"  }
            if (-not $updatedAccent)  { $out += "AccentColor=$accentStr" }
            if (-not $updatedBg)      { $out += "BackgroundColor=$bgStr" }
            Set-Content -Path $script:SettingsPath -Value $out -Encoding UTF8
        }
    } catch {}
}

function Open-Settings {
    try {
        if (-not (Test-Path $script:SettingsPath)) { Save-Settings }
        Start-Process "notepad.exe" -ArgumentList "`"$script:SettingsPath`""
    } catch {}
}

function Get-IniToolVer {
    # Returns @{ Tag = "v1.2.0"; Size = 512000 } for a given key prefix (e.g. "DeepPoll")
    param([string]$Prefix)
    $tag = ""; $size = -1L
    try {
        if (Test-Path $script:SettingsPath) {
            Get-Content $script:SettingsPath | ForEach-Object {
                if ($_ -match "^\s*${Prefix}Ver\s*=\s*(.+)")   { $tag  = $Matches[1].Trim() }
                if ($_ -match "^\s*${Prefix}Size\s*=\s*(\d+)") { $size = [long]$Matches[1] }
            }
        }
    } catch {}
    return @{ Tag = $tag; Size = $size }
}

function Save-IniToolVer {
    # Surgically writes <Prefix>Ver and <Prefix>Size into Settings.ini
    param([string]$Prefix, [string]$Tag, [long]$Size)
    try {
        if (-not (Test-Path $script:SettingsPath)) { Save-Settings }
        $raw       = Get-Content $script:SettingsPath
        $wroteTag  = $false
        $wroteSize = $false
        $out = $raw | ForEach-Object {
            if ($_ -match "^\s*${Prefix}Ver\s*=")  { $wroteTag  = $true; "${Prefix}Ver=$Tag"   }
            elseif ($_ -match "^\s*${Prefix}Size\s*=") { $wroteSize = $true; "${Prefix}Size=$Size" }
            else { $_ }
        }
        if (-not $wroteTag)  { $out += "${Prefix}Ver=$Tag"   }
        if (-not $wroteSize) { $out += "${Prefix}Size=$Size" }
        Set-Content -Path $script:SettingsPath -Value $out -Encoding UTF8
    } catch {}
}

# ============================================================================
# MUSIC via mciSendString (winmm.dll) - reliable MP3 looping
# ============================================================================

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class MciAudio {
    [DllImport("winmm.dll", CharSet = CharSet.Auto)]
    public static extern int mciSendString(string command, string returnString, int returnLength, IntPtr hwndCallback);
    [DllImport("winmm.dll")]
    public static extern int waveOutSetVolume(IntPtr hwo, uint dwVolume);
    public static void SendCommand(string cmd) {
        mciSendString(cmd, null, 0, IntPtr.Zero);
    }
    public static void SetVolume(int percent) {
        // percent 0-100, maps to 0-0xFFFF on each channel
        uint vol = (uint)(percent * 0xFFFF / 100);
        uint stereo = (vol & 0xFFFF) | ((vol & 0xFFFF) << 16);
        waveOutSetVolume(IntPtr.Zero, stereo);
    }
}
"@ -ErrorAction SilentlyContinue

function Get-MusicFile {
    try {
        if (-not (Test-Path $script:MusicPath)) {
            $wc = New-Object System.Net.WebClient
            $wc.DownloadFile($script:MusicUrl, $script:MusicPath)
        }
    } catch {}
}

function Start-Music {
    if (-not $script:MusicEnabled) { return }
    try {
        if (-not (Test-Path $script:MusicPath)) { return }
        [MciAudio]::SendCommand("close MariusMusic")
        [MciAudio]::SendCommand("open `"$($script:MusicPath)`" type mpegvideo alias MariusMusic")
        $vol = if ($null -ne $script:MusicVolume) { $script:MusicVolume } else { 38 }
        [MciAudio]::SetVolume($vol)
        [MciAudio]::SendCommand("play MariusMusic repeat")
    } catch {}
}

function Stop-Music {
    try {
        [MciAudio]::SendCommand("stop MariusMusic")
        [MciAudio]::SendCommand("close MariusMusic")
    } catch {}
}

function Toggle-Music {
    $script:MusicEnabled = -not $script:MusicEnabled
    Save-Settings
    if ($script:MusicEnabled) {
        Start-Music
    } else {
        Stop-Music
    }
}

# ============================================================================
# STARTUP: INSTALL, ICON, SHORTCUT, UPDATE CHECK
# ============================================================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# 1. Install script to %APPDATA%\MARIUS if needed
Invoke-SelfInstall

# 2. Read saved settings
Read-Settings

# 3. Download music file if not cached
Get-MusicFile

# 2. Extract MBC icon/logo and create Desktop shortcut (first run only)
$script:IconPath = Install-SuiovoiIcon
$script:LogoPath = Install-SuiovoiLogo
Install-DesktopShortcut -IconPath $script:IconPath
Install-StartMenuShortcut -IconPath $script:IconPath

# ============================================================================
# MAIN BROWSER WINDOW
# ============================================================================

$script:form = New-Object System.Windows.Forms.Form
$form = $script:form
$form.Text = "SUIOVOI CONFIGURATOR"
$form.Width = 854
$form.Height = 834
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "None"
$form.BackColor = $script:AccentColor
$form.Padding = New-Object System.Windows.Forms.Padding(2)

# Apply MBC icon to taskbar/window
try {
    if ($script:IconPath -and (Test-Path $script:IconPath)) {
        $form.Icon = New-Object System.Drawing.Icon($script:IconPath)
    }
} catch {}

$form.Add_Shown({
    $DWM_BB_ENABLE = 1
    $DWM_BB_BLURREGION = 2
    $dwmApi = Add-Type -MemberDefinition @"
        [DllImport("dwmapi.dll")]
        public static extern int DwmExtendFrameIntoClientArea(IntPtr hWnd, ref MARGINS pMarInset);
        [StructLayout(LayoutKind.Sequential)]
        public struct MARGINS { public int Left, Right, Top, Bottom; }
"@ -Name "DwmApi" -Namespace "Win32" -PassThru -ErrorAction SilentlyContinue
})

$mainPanel = New-Object System.Windows.Forms.Panel
$script:mainPanel = $mainPanel
$mainPanel.Location = New-Object System.Drawing.Point(2, 2)
$mainPanel.Size = New-Object System.Drawing.Size(850, 830)
$mainPanel.BackColor = $script:BgColor

$headerPanel = New-Object System.Windows.Forms.Panel
$headerPanel.Location = New-Object System.Drawing.Point(0, 0)
$headerPanel.Size = New-Object System.Drawing.Size(850, 85)
$headerPanel.BackColor = [System.Drawing.Color]::Black

$headerPanel.Add_MouseDown({
    $script:dragging = $true
    $script:dragCursorX = [System.Windows.Forms.Cursor]::Position.X - $form.Left
    $script:dragCursorY = [System.Windows.Forms.Cursor]::Position.Y - $form.Top
})

$headerPanel.Add_MouseMove({
    if ($script:dragging) {
        $form.Left = [System.Windows.Forms.Cursor]::Position.X - $script:dragCursorX
        $form.Top = [System.Windows.Forms.Cursor]::Position.Y - $script:dragCursorY
    }
})

$headerPanel.Add_MouseUp({
    $script:dragging = $false
})

# --- TITLE IMAGE (replaces text label) ---
$titlePicBox = New-Object System.Windows.Forms.PictureBox
$titlePicBox.Location = New-Object System.Drawing.Point(0, 0)
$titlePicBox.Size = New-Object System.Drawing.Size(850, 85)
$titlePicBox.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom
$titlePicBox.BackColor = [System.Drawing.Color]::Black

try {
    $logoPath = if ($script:LogoPath) { $script:LogoPath } else { $script:LogoInstallPath }
    if (Test-Path $logoPath) {
        $imgBytes = [System.IO.File]::ReadAllBytes($logoPath)
        $ms = New-Object System.IO.MemoryStream($imgBytes, 0, $imgBytes.Length)
        $titlePicBox.Image = [System.Drawing.Image]::FromStream($ms)
    } else {
        throw "Logo not found at $logoPath"
    }
} catch {
    # Fallback: draw text if image fails to load
    $titlePicBox.Add_Paint({
        param($sender, $e)
        $font = New-Object System.Drawing.Font("Segoe UI", 20, [System.Drawing.FontStyle]::Bold)
        $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Yellow)
        $sf = New-Object System.Drawing.StringFormat
        $sf.Alignment = [System.Drawing.StringAlignment]::Center
        $sf.LineAlignment = [System.Drawing.StringAlignment]::Center
        $rect = New-Object System.Drawing.RectangleF(0, 0, $sender.Width, $sender.Height)
        $e.Graphics.DrawString("SUIOVOI CONFIGURATOR", $font, $brush, $rect, $sf)
        $font.Dispose()
        $brush.Dispose()
    })
}

$titlePicBox.Add_MouseDown({
    $script:dragging = $true
    $script:dragCursorX = [System.Windows.Forms.Cursor]::Position.X - $form.Left
    $script:dragCursorY = [System.Windows.Forms.Cursor]::Position.Y - $form.Top
})

$titlePicBox.Add_MouseMove({
    if ($script:dragging) {
        $form.Left = [System.Windows.Forms.Cursor]::Position.X - $script:dragCursorX
        $form.Top = [System.Windows.Forms.Cursor]::Position.Y - $script:dragCursorY
    }
})

$titlePicBox.Add_MouseUp({
    $script:dragging = $false
})

$headerPanel.Controls.Add($titlePicBox)
$mainPanel.Controls.Add($headerPanel)

# ============================================================================
# PAGE NAVIGATION HELPERS - swap tiles in-place on the MAIN window
# ============================================================================

# Collect main-menu tile buttons after they are built (populated below)
$script:mainTiles    = [System.Collections.Generic.List[System.Windows.Forms.Control]]::new()
$script:toolboxTiles = [System.Collections.Generic.List[System.Windows.Forms.Control]]::new()

# Base64-encoded seller logos (embedded so no external files are needed)
$script:L1mitLogoB64      = "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"
$script:HeadglytchLogoB64 = "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"

function Show-SellerPicker {
    $W = 560; $H = 420

    $dlg = New-Object System.Windows.Forms.Form
    $dlg.Text            = ""
    $dlg.Width           = $W
    $dlg.Height          = $H
    $dlg.StartPosition   = "CenterScreen"
    $dlg.FormBorderStyle = "None"
    $dlg.BackColor       = $script:AccentColor
    $dlg.TopMost         = $false

    $script:spDrag = $false; $script:spDX = 0; $script:spDY = 0

    $inner = New-Object System.Windows.Forms.Panel
    $inner.Location  = New-Object System.Drawing.Point(2, 2)
    $inner.Size      = New-Object System.Drawing.Size(($W - 4), ($H - 4))
    $inner.BackColor = [System.Drawing.Color]::FromArgb(26, 6, 6)
    $dlg.Controls.Add($inner)

    # ── Title bar ────────────────────────────────────────────────────────────
    $titleBar = New-Object System.Windows.Forms.Panel
    $titleBar.Location  = New-Object System.Drawing.Point(0, 0)
    $titleBar.Size      = New-Object System.Drawing.Size(($W - 4), 50)
    $titleBar.BackColor = [System.Drawing.Color]::FromArgb(26, 6, 6)
    $inner.Controls.Add($titleBar)
    $titleBar.Add_MouseDown({ $script:spDrag=$true; $script:spDX=[System.Windows.Forms.Cursor]::Position.X-$dlg.Left; $script:spDY=[System.Windows.Forms.Cursor]::Position.Y-$dlg.Top })
    $titleBar.Add_MouseMove({ if($script:spDrag){ $dlg.Left=[System.Windows.Forms.Cursor]::Position.X-$script:spDX; $dlg.Top=[System.Windows.Forms.Cursor]::Position.Y-$script:spDY } })
    $titleBar.Add_MouseUp({ $script:spDrag=$false })

    $lblTitle = New-Object System.Windows.Forms.Label
    $lblTitle.Location  = New-Object System.Drawing.Point(20, 10)
    $lblTitle.Size      = New-Object System.Drawing.Size(($W - 90), 30)
    $lblTitle.Text      = "CHOOSE A SELLER"
    $lblTitle.Font      = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
    $lblTitle.ForeColor = $script:AccentGlow
    $lblTitle.BackColor = [System.Drawing.Color]::Transparent
    $titleBar.Controls.Add($lblTitle)

    $btnX = New-Object System.Windows.Forms.Label
    $btnX.Location  = New-Object System.Drawing.Point(($W - 46), 8)
    $btnX.Size      = New-Object System.Drawing.Size(30, 30)
    $btnX.Text      = "x"
    $btnX.Font      = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
    $btnX.ForeColor = [System.Drawing.Color]::FromArgb(140,140,140)
    $btnX.BackColor = [System.Drawing.Color]::Transparent
    $btnX.TextAlign = "MiddleCenter"
    $btnX.Cursor    = [System.Windows.Forms.Cursors]::Hand
    $btnX.Add_MouseEnter({ $btnX.ForeColor = [System.Drawing.Color]::White })
    $btnX.Add_MouseLeave({ $btnX.ForeColor = [System.Drawing.Color]::FromArgb(140,140,140) })
    $btnX.Add_Click({ $dlg.Close() })
    $titleBar.Controls.Add($btnX)

    # ── Seller buttons ──────────────────────────────────────────────────────
    $sellers = @(
        @{ Name = "@l1mitRoller";  Url = "https://x.com/l1mitRollers"; DisplayUrl = "x.com/l1mitRollers"; DiscordUrl = "https://discord.gg/QGKK3AAGJx"; DiscordDisplay = "discord.gg/QGKK3AAGJx"; LogoB64 = $script:L1mitLogoB64 },
        @{ Name = "@headglytch";   Url = "https://x.com/headglytch";   DisplayUrl = "x.com/headglytch";   DiscordUrl = "https://discord.gg/SmSjfAbwCq"; DiscordDisplay = "discord.gg/SmSjfAbwCq"; LogoB64 = $script:HeadglytchLogoB64 }
    )

    $blockH = 148
    $btnY = 86
    foreach ($seller in $sellers) {
        $btn = New-Object System.Windows.Forms.Button
        $btn.Location  = New-Object System.Drawing.Point(20, $btnY)
        $btn.Size      = New-Object System.Drawing.Size(($W - 44), $blockH)
        $btn.FlatStyle = "Flat"
        $btn.BackColor = [System.Drawing.Color]::FromArgb(26, 6, 6)
        $btn.ForeColor = [System.Drawing.Color]::White
        $btn.Font      = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
        $btn.Text      = ""
        $btn.Cursor    = [System.Windows.Forms.Cursors]::Hand
        $btn.FlatAppearance.BorderSize  = 1
        $btn.FlatAppearance.BorderColor = $script:AccentColor
        $btn.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(48, 12, 12)
        $btn.FlatAppearance.MouseDownBackColor = [System.Drawing.Color]::FromArgb(64, 16, 16)
        $btn.Add_MouseEnter({ $this.FlatAppearance.BorderColor = $script:AccentGlow; $this.FlatAppearance.BorderSize = 2 })
        $btn.Add_MouseLeave({ $this.FlatAppearance.BorderColor = $script:AccentColor; $this.FlatAppearance.BorderSize = 1 })
        $sellerUrl = $seller.Url
        $btn.Add_Click({ Start-Process $sellerUrl; $dlg.Close() }.GetNewClosure())
        $inner.Controls.Add($btn)

        # Logo, layered on top of the button so clicking it still opens the X link
        try {
            $logoBytes = [Convert]::FromBase64String($seller.LogoB64)
            $logoMs    = New-Object System.IO.MemoryStream($logoBytes, 0, $logoBytes.Length)
            $logoPic = New-Object System.Windows.Forms.PictureBox
            $logoPic.Location  = New-Object System.Drawing.Point(96, ($btnY + 34))
            $logoPic.Size      = New-Object System.Drawing.Size(80, 80)
            $logoPic.SizeMode  = [System.Windows.Forms.PictureBoxSizeMode]::Zoom
            $logoPic.Image     = [System.Drawing.Image]::FromStream($logoMs)
            $logoPic.Cursor    = [System.Windows.Forms.Cursors]::Hand
            $logoPic.Add_Click({ Start-Process $sellerUrl; $dlg.Close() }.GetNewClosure())
            $inner.Controls.Add($logoPic)
            $logoPic.BringToFront()
        } catch {}

        # Name label
        $nameLbl = New-Object System.Windows.Forms.Label
        $nameLbl.Location  = New-Object System.Drawing.Point(200, ($btnY + 14))
        $nameLbl.Size      = New-Object System.Drawing.Size(300, 30)
        $nameLbl.Text      = $seller.Name
        $nameLbl.Font      = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
        $nameLbl.ForeColor = [System.Drawing.Color]::White
        $nameLbl.BackColor = [System.Drawing.Color]::Transparent
        $nameLbl.Cursor    = [System.Windows.Forms.Cursors]::Hand
        $nameLbl.Add_Click({ Start-Process $sellerUrl; $dlg.Close() }.GetNewClosure())
        $inner.Controls.Add($nameLbl)
        $nameLbl.BringToFront()

        # X (Twitter) link row
        $xLbl = New-Object System.Windows.Forms.Label
        $xLbl.Location  = New-Object System.Drawing.Point(200, ($btnY + 52))
        $xLbl.Size      = New-Object System.Drawing.Size(300, 24)
        $xLbl.Text      = "X:  $($seller.DisplayUrl)"
        $xLbl.Font      = New-Object System.Drawing.Font("Segoe UI", 10)
        $xLbl.ForeColor = $script:AccentColor
        $xLbl.BackColor = [System.Drawing.Color]::Transparent
        $xLbl.Cursor    = [System.Windows.Forms.Cursors]::Hand
        $xLbl.Add_MouseEnter({ $this.ForeColor = $script:AccentGlow })
        $xLbl.Add_MouseLeave({ $this.ForeColor = $script:AccentColor })
        $xLbl.Add_Click({ Start-Process $sellerUrl; $dlg.Close() }.GetNewClosure())
        $inner.Controls.Add($xLbl)
        $xLbl.BringToFront()

        # Discord link row
        $discordUrl = $seller.DiscordUrl
        $discordLbl = New-Object System.Windows.Forms.Label
        $discordLbl.Location  = New-Object System.Drawing.Point(200, ($btnY + 80))
        $discordLbl.Size      = New-Object System.Drawing.Size(300, 24)
        $discordLbl.Text      = "Discord:  $($seller.DiscordDisplay)"
        $discordLbl.Font      = New-Object System.Drawing.Font("Segoe UI", 10)
        $discordLbl.ForeColor = $script:AccentColor
        $discordLbl.BackColor = [System.Drawing.Color]::Transparent
        $discordLbl.Cursor    = [System.Windows.Forms.Cursors]::Hand
        $discordLbl.Add_MouseEnter({ $this.ForeColor = $script:AccentGlow })
        $discordLbl.Add_MouseLeave({ $this.ForeColor = $script:AccentColor })
        $discordLbl.Add_Click({ Start-Process $discordUrl; $dlg.Close() }.GetNewClosure())
        $inner.Controls.Add($discordLbl)
        $discordLbl.BringToFront()

        $btnY += ($blockH + 14)
    }

    $dlg.ShowDialog()
}

function Show-ColorCustomizer {
    $W = 460; $H = 640

    $dlg = New-Object System.Windows.Forms.Form
    $dlg.Text            = ""
    $dlg.Width           = $W
    $dlg.Height          = $H
    $dlg.StartPosition   = "CenterScreen"
    $dlg.FormBorderStyle = "None"
    $dlg.BackColor       = $script:AccentColor
    $dlg.TopMost         = $false

    $script:ccDrag = $false; $script:ccDX = 0; $script:ccDY = 0

    $inner = New-Object System.Windows.Forms.Panel
    $inner.Location  = New-Object System.Drawing.Point(2, 2)
    $inner.Size      = New-Object System.Drawing.Size(($W - 4), ($H - 4))
    $inner.BackColor = $script:BgColor
    $dlg.Controls.Add($inner)

    # ── Title bar ────────────────────────────────────────────────────────────
    $titleBar = New-Object System.Windows.Forms.Panel
    $titleBar.Location  = New-Object System.Drawing.Point(0, 0)
    $titleBar.Size      = New-Object System.Drawing.Size(($W - 4), 50)
    $titleBar.BackColor = $script:BgColor
    $inner.Controls.Add($titleBar)
    $titleBar.Add_MouseDown({ $script:ccDrag=$true; $script:ccDX=[System.Windows.Forms.Cursor]::Position.X-$dlg.Left; $script:ccDY=[System.Windows.Forms.Cursor]::Position.Y-$dlg.Top })
    $titleBar.Add_MouseMove({ if($script:ccDrag){ $dlg.Left=[System.Windows.Forms.Cursor]::Position.X-$script:ccDX; $dlg.Top=[System.Windows.Forms.Cursor]::Position.Y-$script:ccDY } })
    $titleBar.Add_MouseUp({ $script:ccDrag=$false })

    $lblTitle = New-Object System.Windows.Forms.Label
    $lblTitle.Location  = New-Object System.Drawing.Point(20, 10)
    $lblTitle.Size      = New-Object System.Drawing.Size(($W - 90), 30)
    $lblTitle.Text      = "COLOR CUSTOMIZER"
    $lblTitle.Font      = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
    $lblTitle.ForeColor = $script:AccentGlow
    $lblTitle.BackColor = [System.Drawing.Color]::Transparent
    $titleBar.Controls.Add($lblTitle)

    $btnX = New-Object System.Windows.Forms.Label
    $btnX.Location  = New-Object System.Drawing.Point(($W - 46), 8)
    $btnX.Size      = New-Object System.Drawing.Size(30, 30)
    $btnX.Text      = "x"
    $btnX.Font      = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
    $btnX.ForeColor = [System.Drawing.Color]::FromArgb(140,140,140)
    $btnX.BackColor = [System.Drawing.Color]::Transparent
    $btnX.TextAlign = "MiddleCenter"
    $btnX.Cursor    = [System.Windows.Forms.Cursors]::Hand
    $btnX.Add_MouseEnter({ $btnX.ForeColor = [System.Drawing.Color]::White })
    $btnX.Add_MouseLeave({ $btnX.ForeColor = [System.Drawing.Color]::FromArgb(140,140,140) })
    $btnX.Add_Click({ $dlg.Close() })
    $titleBar.Controls.Add($btnX)

    $lblSectionAccent = New-Object System.Windows.Forms.Label
    $lblSectionAccent.Location  = New-Object System.Drawing.Point(20, 58)
    $lblSectionAccent.Size      = New-Object System.Drawing.Size(($W - 60), 20)
    $lblSectionAccent.Text      = "ACCENT COLOR"
    $lblSectionAccent.Font      = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $lblSectionAccent.ForeColor = $script:AccentGlow
    $lblSectionAccent.BackColor = [System.Drawing.Color]::Transparent
    $inner.Controls.Add($lblSectionAccent)

    $lblSub = New-Object System.Windows.Forms.Label
    $lblSub.Location  = New-Object System.Drawing.Point(20, 78)
    $lblSub.Size      = New-Object System.Drawing.Size(($W - 60), 22)
    $lblSub.Text      = "Pick a preset, or choose a custom color:"
    $lblSub.Font      = New-Object System.Drawing.Font("Segoe UI", 9)
    $lblSub.ForeColor = [System.Drawing.Color]::FromArgb(190, 190, 190)
    $lblSub.BackColor = [System.Drawing.Color]::Transparent
    $inner.Controls.Add($lblSub)

    # ── Preset swatches ─────────────────────────────────────────────────────
    $presets = @(
        @{ Name = "Gold";   Color = [System.Drawing.Color]::FromArgb(212, 175, 55) },
        @{ Name = "Red";    Color = [System.Drawing.Color]::FromArgb(200, 60, 60)  },
        @{ Name = "Orange"; Color = [System.Drawing.Color]::FromArgb(220, 130, 40) },
        @{ Name = "Green";  Color = [System.Drawing.Color]::FromArgb(80, 190, 100) },
        @{ Name = "Cyan";   Color = [System.Drawing.Color]::FromArgb(60, 190, 200) },
        @{ Name = "Blue";   Color = [System.Drawing.Color]::FromArgb(70, 130, 220) },
        @{ Name = "Purple"; Color = [System.Drawing.Color]::FromArgb(150, 90, 210) },
        @{ Name = "Pink";   Color = [System.Drawing.Color]::FromArgb(220, 90, 160) },
        @{ Name = "White";  Color = [System.Drawing.Color]::FromArgb(220, 220, 220) }
    )

    $swW = 100; $swH = 60; $swGapX = 12; $swGapY = 12; $swCols = 3
    $swStartX = 20; $swStartY = 110
    $swIdx = 0
    foreach ($preset in $presets) {
        $swCol = $swIdx % $swCols
        $swRow = [int][Math]::Floor($swIdx / $swCols)
        $swX = $swStartX + ($swCol * ($swW + $swGapX))
        $swY = $swStartY + ($swRow * ($swH + $swGapY))

        $swBtn = New-Object System.Windows.Forms.Button
        $swBtn.Location  = New-Object System.Drawing.Point($swX, $swY)
        $swBtn.Size      = New-Object System.Drawing.Size($swW, $swH)
        $swBtn.FlatStyle = "Flat"
        $swBtn.BackColor = $preset.Color
        $swBtn.ForeColor = [System.Drawing.Color]::FromArgb(20, 20, 20)
        $swBtn.Font      = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
        $swBtn.Text      = $preset.Name
        $swBtn.Cursor    = [System.Windows.Forms.Cursors]::Hand
        $swBtn.FlatAppearance.BorderSize  = 1
        $swBtn.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(0, 0, 0)
        $swColor = $preset.Color
        $swBtn.Add_Click({
            try {
                Update-AccentPalette -Color $swColor
                Save-Settings
                $dlg.Close()
            } catch {
                [System.Windows.Forms.MessageBox]::Show(
                    "Could not apply that color:`n`n$($_.Exception.GetType().FullName)`n$($_.Exception.Message)",
                    "Color Customizer - Error",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Error
                ) | Out-Null
            }
        }.GetNewClosure())
        $inner.Controls.Add($swBtn)

        $swIdx++
    }

    # ── Custom color picker ─────────────────────────────────────────────────
    $customRow = [int][Math]::Ceiling($presets.Count / $swCols)
    $customY = $swStartY + ($customRow * ($swH + $swGapY)) + 6

    $btnCustom = New-Object System.Windows.Forms.Button
    $btnCustom.Location  = New-Object System.Drawing.Point($swStartX, $customY)
    $btnCustom.Size      = New-Object System.Drawing.Size(($W - 60), 40)
    $btnCustom.FlatStyle = "Flat"
    $btnCustom.BackColor = [System.Drawing.Color]::FromArgb(42, 12, 12)
    $btnCustom.ForeColor = [System.Drawing.Color]::White
    $btnCustom.Font      = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $btnCustom.Text      = "Custom Color..."
    $btnCustom.Cursor    = [System.Windows.Forms.Cursors]::Hand
    $btnCustom.FlatAppearance.BorderSize  = 1
    $btnCustom.FlatAppearance.BorderColor = $script:AccentColor
    $btnCustom.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(64, 16, 16)
    $btnCustom.Add_MouseEnter({ $this.FlatAppearance.BorderColor = $script:AccentGlow; $this.FlatAppearance.BorderSize = 2 })
    $btnCustom.Add_MouseLeave({ $this.FlatAppearance.BorderColor = $script:AccentColor; $this.FlatAppearance.BorderSize = 1 })
    $btnCustom.Add_Click({
        try {
            $picker = New-Object System.Windows.Forms.ColorDialog
            $picker.Color = $script:AccentColor
            $picker.FullOpen = $true
            if ($picker.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                Update-AccentPalette -Color $picker.Color
                Save-Settings
                $dlg.Close()
            }
        } catch {
            [System.Windows.Forms.MessageBox]::Show(
                "Could not apply that color:`n`n$($_.Exception.GetType().FullName)`n$($_.Exception.Message)",
                "Color Customizer - Error",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            ) | Out-Null
        }
    })
    $inner.Controls.Add($btnCustom)

    # ── Background Color section ────────────────────────────────────────────
    $lblSectionBg = New-Object System.Windows.Forms.Label
    $lblSectionBg.Location  = New-Object System.Drawing.Point(20, 392)
    $lblSectionBg.Size      = New-Object System.Drawing.Size(($W - 60), 20)
    $lblSectionBg.Text      = "BACKGROUND COLOR"
    $lblSectionBg.Font      = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $lblSectionBg.ForeColor = $script:AccentGlow
    $lblSectionBg.BackColor = [System.Drawing.Color]::Transparent
    $inner.Controls.Add($lblSectionBg)

    $bgPresets = @(
        @{ Name = "Maroon";   Color = [System.Drawing.Color]::FromArgb(26, 6, 6)   },
        @{ Name = "Black";    Color = [System.Drawing.Color]::FromArgb(8, 8, 8)    },
        @{ Name = "Charcoal"; Color = [System.Drawing.Color]::FromArgb(24, 24, 24) },
        @{ Name = "Navy";     Color = [System.Drawing.Color]::FromArgb(8, 12, 28)  },
        @{ Name = "Forest";   Color = [System.Drawing.Color]::FromArgb(8, 24, 12)  },
        @{ Name = "Plum";     Color = [System.Drawing.Color]::FromArgb(26, 8, 28)  }
    )

    $bgSwStartX = 20; $bgSwStartY = 420
    $bgSwIdx = 0
    foreach ($bgPreset in $bgPresets) {
        $bgSwCol = $bgSwIdx % $swCols
        $bgSwRow = [int][Math]::Floor($bgSwIdx / $swCols)
        $bgSwX = $bgSwStartX + ($bgSwCol * ($swW + $swGapX))
        $bgSwY = $bgSwStartY + ($bgSwRow * ($swH + $swGapY))

        $bgSwBtn = New-Object System.Windows.Forms.Button
        $bgSwBtn.Location  = New-Object System.Drawing.Point($bgSwX, $bgSwY)
        $bgSwBtn.Size      = New-Object System.Drawing.Size($swW, $swH)
        $bgSwBtn.FlatStyle = "Flat"
        $bgSwBtn.BackColor = $bgPreset.Color
        $bgSwBtn.ForeColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
        $bgSwBtn.Font      = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
        $bgSwBtn.Text      = $bgPreset.Name
        $bgSwBtn.Cursor    = [System.Windows.Forms.Cursors]::Hand
        $bgSwBtn.FlatAppearance.BorderSize  = 1
        $bgSwBtn.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(90, 90, 90)
        $bgSwColor = $bgPreset.Color
        $bgSwBtn.Add_Click({
            try {
                Update-BackgroundPalette -Color $bgSwColor
                Save-Settings
                $dlg.Close()
            } catch {
                [System.Windows.Forms.MessageBox]::Show(
                    "Could not apply that background:`n`n$($_.Exception.GetType().FullName)`n$($_.Exception.Message)",
                    "Color Customizer - Error",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Error
                ) | Out-Null
            }
        }.GetNewClosure())
        $inner.Controls.Add($bgSwBtn)

        $bgSwIdx++
    }

    $bgCustomRow = [int][Math]::Ceiling($bgPresets.Count / $swCols)
    $bgCustomY = $bgSwStartY + ($bgCustomRow * ($swH + $swGapY)) + 6

    $btnBgCustom = New-Object System.Windows.Forms.Button
    $btnBgCustom.Location  = New-Object System.Drawing.Point($bgSwStartX, $bgCustomY)
    $btnBgCustom.Size      = New-Object System.Drawing.Size(($W - 60), 40)
    $btnBgCustom.FlatStyle = "Flat"
    $btnBgCustom.BackColor = [System.Drawing.Color]::FromArgb(42, 12, 12)
    $btnBgCustom.ForeColor = [System.Drawing.Color]::White
    $btnBgCustom.Font      = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $btnBgCustom.Text      = "Custom Background..."
    $btnBgCustom.Cursor    = [System.Windows.Forms.Cursors]::Hand
    $btnBgCustom.FlatAppearance.BorderSize  = 1
    $btnBgCustom.FlatAppearance.BorderColor = $script:AccentColor
    $btnBgCustom.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(64, 16, 16)
    $btnBgCustom.Add_MouseEnter({ $this.FlatAppearance.BorderColor = $script:AccentGlow; $this.FlatAppearance.BorderSize = 2 })
    $btnBgCustom.Add_MouseLeave({ $this.FlatAppearance.BorderColor = $script:AccentColor; $this.FlatAppearance.BorderSize = 1 })
    $btnBgCustom.Add_Click({
        try {
            $picker = New-Object System.Windows.Forms.ColorDialog
            $picker.Color = $script:BgColor
            $picker.FullOpen = $true
            if ($picker.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                Update-BackgroundPalette -Color $picker.Color
                Save-Settings
                $dlg.Close()
            }
        } catch {
            [System.Windows.Forms.MessageBox]::Show(
                "Could not apply that background:`n`n$($_.Exception.GetType().FullName)`n$($_.Exception.Message)",
                "Color Customizer - Error",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            ) | Out-Null
        }
    })
    $inner.Controls.Add($btnBgCustom)

    $dlg.ShowDialog()
}

function Show-TroubleshootingDialog {
    $W = 660; $H = 780
    $dlg = New-Object System.Windows.Forms.Form
    $dlg.Text            = ""
    $dlg.Width           = $W
    $dlg.Height          = $H
    $dlg.StartPosition   = "CenterScreen"
    $dlg.FormBorderStyle = "None"
    $dlg.BackColor       = [System.Drawing.Color]::Yellow
    $dlg.TopMost         = $false

    $script:tsDrag = $false; $script:tsDX = 0; $script:tsDY = 0

    $inner = New-Object System.Windows.Forms.Panel
    $inner.Location  = New-Object System.Drawing.Point(3, 3)
    $inner.Size      = New-Object System.Drawing.Size(($W - 6), ($H - 6))
    $inner.BackColor = [System.Drawing.Color]::FromArgb(10, 10, 10)
    $dlg.Controls.Add($inner)

    # ── RGB border timer (matches Gamebar pattern with script-scoped hue) ──────
    $script:tsHue = if ($script:rgbHue) { $script:rgbHue } else { 0 }
    $tsRgbTimer = New-Object System.Windows.Forms.Timer
    $tsRgbTimer.Interval = 40
    $tsRgbTimer.Add_Tick({
        $script:tsHue = ($script:tsHue + 2) % 360
        $h = $script:tsHue / 360.0
        $i = [Math]::Floor($h * 6)
        $f = $h * 6 - $i
        $q = 1 - $f; $t = $f
        switch ($i % 6) {
            0 { $r = 255; $g = [int]($t*255); $b = 0 }
            1 { $r = [int]($q*255); $g = 255; $b = 0 }
            2 { $r = 0; $g = 255; $b = [int]($t*255) }
            3 { $r = 0; $g = [int]($q*255); $b = 255 }
            4 { $r = [int]($t*255); $g = 0; $b = 255 }
            5 { $r = 255; $g = 0; $b = [int]($q*255) }
        }
        $dlg.BackColor = [System.Drawing.Color]::FromArgb($r, $g, $b)
    })
    $tsRgbTimer.Start()
    $dlg.Add_FormClosed({ $tsRgbTimer.Stop(); $tsRgbTimer.Dispose() })

    # Title bar
    $titleBar = New-Object System.Windows.Forms.Panel
    $titleBar.Location  = New-Object System.Drawing.Point(0, 0)
    $titleBar.Size      = New-Object System.Drawing.Size(($W - 6), 70)
    $titleBar.BackColor = [System.Drawing.Color]::FromArgb(10, 10, 10)
    $inner.Controls.Add($titleBar)
    $titleBar.Add_MouseDown({ $script:tsDrag=$true; $script:tsDX=[System.Windows.Forms.Cursor]::Position.X-$dlg.Left; $script:tsDY=[System.Windows.Forms.Cursor]::Position.Y-$dlg.Top })
    $titleBar.Add_MouseMove({ if($script:tsDrag){ $dlg.Left=[System.Windows.Forms.Cursor]::Position.X-$script:tsDX; $dlg.Top=[System.Windows.Forms.Cursor]::Position.Y-$script:tsDY } })
    $titleBar.Add_MouseUp({ $script:tsDrag=$false })

    $picTitle = New-Object System.Windows.Forms.PictureBox
    $picTitle.Location  = New-Object System.Drawing.Point(0, 0)
    $picTitle.Size      = New-Object System.Drawing.Size(($W - 6), 70)
    $picTitle.BackColor = [System.Drawing.Color]::FromArgb(10, 10, 10)
    $picTitle.Add_Paint({
        param($sender, $e); $g=$e.Graphics
        $g.SmoothingMode=[System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $g.TextRenderingHint=[System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
        $sf=New-Object System.Drawing.Font("Impact",22,[System.Drawing.FontStyle]::Italic)
        $sb=New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(80,0,0,0))
        $tf=New-Object System.Drawing.Font("Impact",22,[System.Drawing.FontStyle]::Italic)
        $tb=New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Yellow)
        $g.DrawString("TROUBLESHOOTING",$sf,$sb,22,17)
        $g.DrawString("TROUBLESHOOTING",$tf,$tb,20,15)
        $sf.Dispose();$sb.Dispose();$tf.Dispose();$tb.Dispose()
    })
    $picTitle.Add_MouseDown({ $script:tsDrag=$true; $script:tsDX=[System.Windows.Forms.Cursor]::Position.X-$dlg.Left; $script:tsDY=[System.Windows.Forms.Cursor]::Position.Y-$dlg.Top })
    $picTitle.Add_MouseMove({ if($script:tsDrag){ $dlg.Left=[System.Windows.Forms.Cursor]::Position.X-$script:tsDX; $dlg.Top=[System.Windows.Forms.Cursor]::Position.Y-$script:tsDY } })
    $picTitle.Add_MouseUp({ $script:tsDrag=$false })
    $titleBar.Controls.Add($picTitle)

    # Divider
    $div = New-Object System.Windows.Forms.Panel
    $div.Location  = New-Object System.Drawing.Point(0, 70)
    $div.Size      = New-Object System.Drawing.Size(($W - 6), 2)
    $div.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 40)
    $inner.Controls.Add($div)

    # Badge
    $badgePanel = New-Object System.Windows.Forms.Panel
    $badgePanel.Location  = New-Object System.Drawing.Point(20, 82)
    $badgePanel.Size      = New-Object System.Drawing.Size(($W - 46), 36)
    $badgePanel.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 0)
    $inner.Controls.Add($badgePanel)

    $badgeLabel = New-Object System.Windows.Forms.Label
    $badgeLabel.Location  = New-Object System.Drawing.Point(0, 0)
    $badgeLabel.Size      = New-Object System.Drawing.Size(($W - 46), 36)
    $badgeLabel.Text      = "  TROUBLESHOOTING GUIDE  |  Common Issues & Solutions"
    $badgeLabel.Font      = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $badgeLabel.ForeColor = [System.Drawing.Color]::Yellow
    $badgeLabel.BackColor = [System.Drawing.Color]::Transparent
    $badgeLabel.TextAlign = "MiddleLeft"
    $badgePanel.Controls.Add($badgeLabel)

    # Scrollable content box
    $contentBox = New-Object System.Windows.Forms.RichTextBox
    $contentBox.Location   = New-Object System.Drawing.Point(20, 130)
    $contentBox.Size       = New-Object System.Drawing.Size(($W - 46), ($H - 220))
    $contentBox.BackColor  = [System.Drawing.Color]::FromArgb(18, 18, 18)
    $contentBox.ForeColor  = [System.Drawing.Color]::FromArgb(190, 190, 190)
    $contentBox.Font       = New-Object System.Drawing.Font("Segoe UI", 9)
    $contentBox.ReadOnly   = $true
    $contentBox.BorderStyle = "None"
    $contentBox.ScrollBars = "Vertical"

    # Section helper: heading yellow, body gray
    function Add-TsSection {
        param($rtb, [string]$Heading, [string[]]$Lines)
        $rtb.SelectionFont  = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $rtb.SelectionColor = [System.Drawing.Color]::Yellow
        $rtb.AppendText("$Heading`n")
        foreach ($ln in $Lines) {
            $rtb.SelectionFont  = New-Object System.Drawing.Font("Segoe UI", 9)
            $rtb.SelectionColor = [System.Drawing.Color]::FromArgb(190, 190, 190)
            $rtb.AppendText("$ln`n")
        }
        $rtb.AppendText("`n")
    }

    Add-TsSection $contentBox "PREVIOUSLY OVERCLOCKED ANOTHER CONTROLLER?" @(
        "Have you installed an overclock (HIDUSBF) for another controller on the",
        "same USB port? (e.g. PS5 at 8000Hz, Xbox with HIDUSBF, any non-Marius",
        "controller using HIDUSBF).",
        "",
        "If YES, the Marius board may have trouble connecting to Marius Tools",
        "because HIDUSBF is forcing the USB polling rate for the previous controller.",
        "",
        "HOW TO REMOVE THE OVERCLOCK:",
        "  1. Open HIDUSBF.",
        "  2. Select your non-Marius controller.",
        "  3. Untick Filter On Device.",
        "  4. Right-click Install Service (or Uninstall Service if available).",
        "  5. Click Uninstall Service.",
        "  6. Restart your PC.",
        "",
        "Download HIDUSBF from the FR33THY GitHub if needed."
    )

    Add-TsSection $contentBox "MY MARIUS CONTROLLER KEEPS DISCONNECTING" @(
        "USB-C cables have a limited lifespan. Frequent plugging and unplugging can",
        "weaken the connection over time, especially during firmware updates or testing.",
        "",
        "THINGS TO CHECK:",
        "  - Try a different USB-C cable.",
        "  - Try a different USB port.",
        "  - Avoid USB hubs where possible.",
        "  - Keep a spare USB-C cable available for troubleshooting.",
        "",
        "Even if the cable is new, testing another cable is recommended."
    )

    Add-TsSection $contentBox "MY CONTROLLER IS NOT CONNECTING" @(
        "This issue has largely been resolved through firmware updates.",
        "Older firmware versions, particularly on some AMD systems, could cause",
        "connection issues.",
        "",
        "RECOMMENDED SOLUTION:",
        "  - Update to Firmware 1.22B or newer.",
        "  - Install and use Marius XInput.",
        "",
        "These updates resolve the vast majority of connection-related problems."
    )

    Add-TsSection $contentBox "MY BUTTONS ARE NOT WORKING CORRECTLY" @(
        "Button issues are typically caused by:",
        "  - A bug in the controller manufacturer's firmware.",
        "  - A bug in the Marius firmware.",
        "  - Corrupted controller settings or configuration.",
        "",
        "TROUBLESHOOTING STEPS:",
        "  1. Update to the latest Marius firmware.",
        "  2. Restart the controller and reconnect it.",
        "  3. Test the controller in a gamepad tester.",
        "  4. Report the issue with details about:",
        "       - Controller model",
        "       - Firmware version",
        "       - Which buttons are affected",
        "       - Whether the issue occurs in all or specific games",
        "",
        "Providing this information helps identify and fix bugs much faster."
    )

    $inner.Controls.Add($contentBox)

    # OK button with RGB border
    $okBtnW = 220; $okBtnH = 46
    $okX = [int](($W - 6 - $okBtnW - 4) / 2)
    $okY = $H - 76

    $rgbOkPanel = New-Object System.Windows.Forms.Panel
    $rgbOkPanel.Location  = New-Object System.Drawing.Point($okX, $okY)
    $rgbOkPanel.Size      = New-Object System.Drawing.Size(($okBtnW + 4), ($okBtnH + 4))
    $rgbOkPanel.BackColor = [System.Drawing.Color]::Yellow
    $inner.Controls.Add($rgbOkPanel)
    $tsRgbTimer.Add_Tick({ $rgbOkPanel.BackColor = $dlg.BackColor })

    $btnOk = New-Object System.Windows.Forms.Button
    $btnOk.Location  = New-Object System.Drawing.Point(2, 2)
    $btnOk.Size      = New-Object System.Drawing.Size($okBtnW, $okBtnH)
    $btnOk.Text      = "OK"
    $btnOk.FlatStyle = "Flat"
    $btnOk.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 20)
    $btnOk.ForeColor = [System.Drawing.Color]::Yellow
    $btnOk.Font      = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $btnOk.FlatAppearance.BorderSize = 0
    $btnOk.Cursor    = [System.Windows.Forms.Cursors]::Hand
    $btnOk.Add_Click({ $dlg.Close() })
    $btnOk.Add_MouseEnter({ $btnOk.BackColor = [System.Drawing.Color]::FromArgb(40,40,12) })
    $btnOk.Add_MouseLeave({ $btnOk.BackColor = [System.Drawing.Color]::FromArgb(20,20,20) })
    $rgbOkPanel.Controls.Add($btnOk)

    $dlg.Add_KeyDown({ param($s,$e); if($e.KeyCode -eq "Escape"){ $dlg.Close() } })
    [void]$dlg.ShowDialog()
}

function Show-ToolboxPage {
    # Hide every main-menu tile
    foreach ($c in $script:mainTiles) { $c.Visible = $false }

    # Build toolbox tiles only once; reuse on subsequent visits
    if ($script:toolboxTiles.Count -eq 0) {
        $tbItems = @(
            @{Name="Auto Calibration";                    URL="AUTO_CALIBRATE";        Desc="Edit stick calibration JSON values (xMin/yMin/xMax/yMax)"},
            # Temporarily removed - uncomment to restore:
            # @{Name="Beta Portal";                         URL="BETA_PORTAL";           Desc="Enroll your board in the beta program and receive early firmware updates"},
            @{Name="DeepPoll";                            URL="DEEPPOLL";              Desc="Measures USB polling rate with microsecond precision using kernel-level ETW tracing"; Admin="Requires Admin Permissions"},
            @{Name="DeepLog";                             URL="DEEPLOG";               Desc="Logs USB input events with microsecond timestamps for latency analysis"; Admin="Requires Admin Permissions"},
            @{Name="Gamebar Notification Removal";        URL="GAMEBAR_FIX";           Desc="Removes GameBar Notification with 8K Polling Affected Controllers"; Admin="Requires Admin Permissions"},
            @{Name="Uninstall HIDUSBF";                   URL="UNINSTALL_HIDUSBF";     Desc="Completely removes the HIDUSBF driver and related files from your system"; Admin="Requires Admin Permissions"},
            # No Suiovoi Discord link provided yet - uncomment and add URL when ready:
            # @{Name="Join Suiovoi Discord";              URL="DISCORD";               Desc="Join the Suiovoi community on Discord"},
            # Temporarily removed - uncomment to restore:
            # @{Name="Troubleshooting";                     URL="TROUBLESHOOTING";       Desc="Common issues and solutions for Marius controllers"},
            @{Name="FR33THY Ultimate Optimization Guide"; URL="FR33THY_GUIDE";         Desc="Optimise and Debloat Windows"},
            @{Name="Color Customizer";                    URL="COLOR_CUSTOMIZER";      Desc="Change the app's accent color to your liking"},
            @{Name="Back";                                URL="BACK";                  Desc="Return to main menu"}
        )
        $tbCols = 2
        $tbColGap = 20
        $tbRowGap = 16
        $tbSX = 30
        $tbHeaderBottom  = 90
        $tbPanelHeight   = 795
        $tbRows = [Math]::Ceiling($tbItems.Count / $tbCols)
        $tbCardW = [int]((790 - (($tbCols - 1) * $tbColGap)) / $tbCols)
        $tbCardH = [int]((($tbPanelHeight - $tbHeaderBottom) - (($tbRows - 1) * $tbRowGap)) / $tbRows)
        $tbIdx = 0
        foreach ($tbItem in $tbItems) {
            $tbCol = $tbIdx % $tbCols
            $tbRow = [int][Math]::Floor($tbIdx / $tbCols)
            $tbX = $tbSX + ($tbCol * ($tbCardW + $tbColGap))
            $tbY = $tbHeaderBottom + ($tbRow * ($tbCardH + $tbRowGap))

            $tbTile = New-Object System.Windows.Forms.Button
            $tbTile.Location  = New-Object System.Drawing.Point($tbX, $tbY)
            $tbTile.Size      = New-Object System.Drawing.Size($tbCardW, $tbCardH)
            $tbTile.FlatStyle = "Flat"
            $tbTile.FlatAppearance.BorderSize = 0
            $tbTile.BackColor = $script:BgColor
            $tbTile.ForeColor = [System.Drawing.Color]::White
            $tbTile.Text      = ""
            $tbTile.Cursor    = [System.Windows.Forms.Cursors]::Hand
            $tbTile.Tag = $tbItem.URL

            $tbRoundPath = New-RoundedPath -Rect (New-Object System.Drawing.Rectangle(0, 0, $tbCardW, $tbCardH)) -Radius 16
            $tbTile.Region = New-Object System.Drawing.Region($tbRoundPath)
            $script:suiovoiHover[$tbTile] = $false

            $tbTile.Add_MouseEnter({ if (-not $script:suiovoiHover) { $script:suiovoiHover = @{} }; $script:suiovoiHover[$this] = $true; $this.Invalidate() })
            $tbTile.Add_MouseLeave({ if (-not $script:suiovoiHover) { $script:suiovoiHover = @{} }; $script:suiovoiHover[$this] = $false; $this.Invalidate() })

            $tbN=$tbItem.Name; $tbD=$tbItem.Desc; $tbU=$tbItem.URL; $tbA=if($tbItem.Admin){$tbItem.Admin}else{""}
            $tbIconLetter = $tbN.Substring(0,1).ToUpper()

            $tbTipText = if ($tbA -ne "") { "$tbN`n$tbD ($tbA)" } else { "$tbN`n$tbD" }
            $script:mainToolTip.SetToolTip($tbTile, $tbTipText)

            $tbTile.Add_Paint({
                param($s,$e); $g=$e.Graphics
                try {
                $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
                $g.TextRenderingHint=[System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit

                if (-not $script:suiovoiHover) { $script:suiovoiHover = @{} }
                $tbIsHover = $false
                if ($script:suiovoiHover.ContainsKey($s)) { $tbIsHover = $script:suiovoiHover[$s] }
                $tbPal    = Get-CurrentTilePalette
                $tbTop    = Get-SafeColor $(if ($tbIsHover) { $tbPal.BgTopH } else { $tbPal.BgTopN }) ([System.Drawing.Color]::FromArgb(42,12,12))
                $tbBot    = Get-SafeColor $(if ($tbIsHover) { $tbPal.BgBotH } else { $tbPal.BgBotN }) ([System.Drawing.Color]::FromArgb(16,3,3))
                $tbBTop   = Get-SafeColor $(if ($tbIsHover) { $tbPal.BorderTopH } else { $tbPal.BorderTopN }) ([System.Drawing.Color]::FromArgb(230,210,140))
                $tbBBot   = Get-SafeColor $(if ($tbIsHover) { $tbPal.BorderBotH } else { $tbPal.BorderBotN }) ([System.Drawing.Color]::FromArgb(150,120,40))
                $tbBorder = Get-SafeColor $(if ($tbIsHover) { $tbPal.Glow } else { $tbPal.Accent }) ([System.Drawing.Color]::FromArgb(212,175,55))
                $tbBW     = if ($tbIsHover) { 2 } else { 1 }
                $tbShadowOff = 6

                $tbShRect1 = New-Object System.Drawing.Rectangle(($tbShadowOff-2), ($tbShadowOff-2), ($s.Width-1), ($s.Height-1))
                $tbShPath1 = New-RoundedPath -Rect $tbShRect1 -Radius 16
                $tbShBrush1 = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(60,0,0,0))
                $g.FillPath($tbShBrush1, $tbShPath1)
                $tbShRect2 = New-Object System.Drawing.Rectangle($tbShadowOff, $tbShadowOff, ($s.Width-1-2), ($s.Height-1-2))
                $tbShPath2 = New-RoundedPath -Rect $tbShRect2 -Radius 16
                $tbShBrush2 = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(100,0,0,0))
                $g.FillPath($tbShBrush2, $tbShPath2)

                # NOTE: each Rectangle used below is built into its own variable
                # first, then passed into New-Object by reference. Nesting a
                # "New-Object ... Rectangle(...)" call directly inline as an
                # argument to another New-Object call is what caused the
                # "Cannot find an overload for LinearGradientBrush" crash here
                # previously - PowerShell's argument-mode parser doesn't reliably
                # resolve the inner constructor call in that position.
                $tbFaceW = $s.Width - 1 - $tbShadowOff
                $tbFaceH = $s.Height - 1 - $tbShadowOff
                $tbRect = New-Object System.Drawing.Rectangle(0, 0, $tbFaceW, $tbFaceH)
                $tbPath = New-RoundedPath -Rect $tbRect -Radius 16
                $tbBgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($tbRect, $tbTop, $tbBot, 90)
                $g.FillPath($tbBgBrush, $tbPath)
                $tbBorderRect = New-Object System.Drawing.Rectangle(0, 0, $tbFaceW, $tbFaceH)
                $tbBorderBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($tbBorderRect, $tbBTop, $tbBBot, 90)
                $tbBorderPen = New-Object System.Drawing.Pen($tbBorderBrush, $tbBW)
                $g.DrawPath($tbBorderPen, $tbPath)

                $tbHlPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(70,255,255,255), 1)
                $g.DrawLine($tbHlPen, 14, 3, ($tbFaceW - 14), 3)

                $tbIconRect = New-Object System.Drawing.Rectangle(16, [int](($tbFaceH - 48) / 2), 48, 48)
                $tbIconPath = New-RoundedPath -Rect $tbIconRect -Radius 10
                $tbIconBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($tbIconRect, (Get-SafeColor $tbPal.IconTop ([System.Drawing.Color]::FromArgb(90,26,26))), (Get-SafeColor $tbPal.IconBot ([System.Drawing.Color]::FromArgb(50,10,10))), 90)
                $g.FillPath($tbIconBrush, $tbIconPath)
                $tbIconPen = New-Object System.Drawing.Pen($tbBorder, 1)
                $g.DrawPath($tbIconPen, $tbIconPath)

                $tbIconFont = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
                $tbIconTextBrush = New-Object System.Drawing.SolidBrush($tbBorder)
                $tbIconSf = New-Object System.Drawing.StringFormat
                $tbIconSf.Alignment = [System.Drawing.StringAlignment]::Center
                $tbIconSf.LineAlignment = [System.Drawing.StringAlignment]::Center
                $tbIconRectF = New-Object System.Drawing.RectangleF($tbIconRect.X, $tbIconRect.Y, $tbIconRect.Width, $tbIconRect.Height)
                $g.DrawString($tbIconLetter, $tbIconFont, $tbIconTextBrush, $tbIconRectF, $tbIconSf)

                $tbTextX = 76
                $tbTextWidth = $tbFaceW - $tbTextX - 14
                $tf=New-Object System.Drawing.Font("Segoe UI",12,[System.Drawing.FontStyle]::Bold)
                $df=New-Object System.Drawing.Font("Segoe UI",8.5)
                $wb=New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
                $rb=New-Object System.Drawing.SolidBrush((Get-SafeColor $tbPal.Accent ([System.Drawing.Color]::FromArgb(212,175,55))))
                $yb=New-Object System.Drawing.SolidBrush((Get-SafeColor $tbPal.Glow ([System.Drawing.Color]::FromArgb(230,210,140))))

                $g.DrawString($tbN,$tf,$wb,[float]$tbTextX,[float](($tbFaceH/2) - 20))
                $tbDescRect = New-Object System.Drawing.RectangleF($tbTextX, (($tbFaceH/2) + 4), $tbTextWidth, ($tbFaceH/2 - 8))
                if ($tbA -ne "") {
                    $g.DrawString("$tbD  |  $tbA", $df, $yb, $tbDescRect)
                } else {
                    $g.DrawString($tbD, $df, $rb, $tbDescRect)
                }

                $tbBgBrush.Dispose(); $tbBorderPen.Dispose(); $tbIconBrush.Dispose(); $tbIconPen.Dispose()
                $tbIconTextBrush.Dispose(); $wb.Dispose();$rb.Dispose();$yb.Dispose();$tf.Dispose();$df.Dispose();$tbIconFont.Dispose()
                $tbPath.Dispose(); $tbIconPath.Dispose()
                $tbShBrush1.Dispose(); $tbShBrush2.Dispose(); $tbShPath1.Dispose(); $tbShPath2.Dispose()
                $tbBorderBrush.Dispose(); $tbHlPen.Dispose()
                } catch {
                    if (-not $script:paintDebugShown) {
                        $script:paintDebugShown = $true
                        [System.Windows.Forms.MessageBox]::Show(
                            "TOOLBOX TILE PAINT ERROR:`n`n$($_.Exception.GetType().FullName)`n$($_.Exception.Message)`n`n$($_.InvocationInfo.PositionMessage)",
                            "Debug - Paint Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning
                        ) | Out-Null
                    }
                }
            }.GetNewClosure())
            $tbTile.Add_Click({
                $tu=$this.Tag
                if ($tu -eq "BACK")                { Show-MainPage; return }
                if ($tu -eq "COLOR_CUSTOMIZER")     { Show-ColorCustomizer; Refresh-AccentUI; return }
                if ($tu -eq "USB_ANALYZER")        { Show-UsbAnalyzer; return }
                if ($tu -eq "GAMEBAR_FIX")         { Invoke-GameBarNotificationFix; return }
                if ($tu -eq "UNINSTALL_HIDUSBF")   { Invoke-UninstallHIDUSBF; return }
                if ($tu -eq "TROUBLESHOOTING")     { Show-TroubleshootingDialog; return }
                if ($tu -eq "DEEPPOLL") { Show-DeepPoll; return }
                if ($tu -eq "DEEPLOG")  { Show-DeepLog; return }
                if ($tu -eq "AUTO_CALIBRATE") { Show-AutoCalibrate; return }
                if ($tu -eq "BETA_PORTAL") {
                    $targetUrl = "https://beta.mariusheier.com/"
                    $defaultBrowser = Get-DefaultBrowser
                    $browserPath = Get-BrowserPath $defaultBrowser
                    if (-not $browserPath) {
                        foreach ($browser in @("Chrome","Edge","Brave","Opera","Vivaldi","Arc")) {
                            if ($browser -ne $defaultBrowser) {
                                $browserPath = Get-BrowserPath $browser
                                if ($browserPath) { break }
                            }
                        }
                    }
                    if ($browserPath) {
                        $screen = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
                        $wW=1200; $wH=800
                        $l=[Math]::Floor(($screen.Width-$wW)/2); $t=[Math]::Floor(($screen.Height-$wH)/2)
                        Start-Process -FilePath $browserPath -ArgumentList "--app=`"$targetUrl`" --window-size=$wW,$wH --window-position=$l,$t"
                    } else { Start-Process $targetUrl }
                    return
                }
                if ($tu -eq "DISCORD") {
                    Start-Process "https://discord.com/invite/vKMr8nHN44"
                    return
                }
                if ($tu -eq "FR33THY_GUIDE") {
                    $targetUrl = "https://github.com/FR33THYFR33THY/Ultimate"
                    $defaultBrowser = Get-DefaultBrowser
                    $browserPath = Get-BrowserPath $defaultBrowser
                    if (-not $browserPath) {
                        foreach ($browser in @("Chrome","Edge","Brave","Opera","Vivaldi","Arc")) {
                            if ($browser -ne $defaultBrowser) {
                                $browserPath = Get-BrowserPath $browser
                                if ($browserPath) { break }
                            }
                        }
                    }
                    if ($browserPath) {
                        $screen = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
                        $wW=1200; $wH=800
                        $l=[Math]::Floor(($screen.Width-$wW)/2); $t=[Math]::Floor(($screen.Height-$wH)/2)
                        Start-Process -FilePath $browserPath -ArgumentList "--app=`"$targetUrl`" --window-size=$wW,$wH --window-position=$l,$t"
                    } else { Start-Process $targetUrl }
                    return
                }
            }.GetNewClosure())
            $script:mainPanel.Controls.Add($tbTile)
            $script:toolboxTiles.Add($tbTile)
            $tbIdx++
        }
    }

    # Show toolbox tiles
    foreach ($c in $script:toolboxTiles) { $c.Visible = $true }
    $script:mainPanel.Refresh()
}

function Show-MainPage {
    foreach ($c in $script:toolboxTiles) { $c.Visible = $false }
    foreach ($c in $script:mainTiles)    { $c.Visible = $true  }
    $script:mainPanel.Refresh()
}

# ============================================================================
# MAIN MENU TILES
# (Setup Controller, Joystick Tester, Polling Rate Checker, Firmware Updater,
#  Setup Guide By Parasite, Beta Portal, Creator Twitter, Update Script,
#  Marius Toolbox, Exit)
# ============================================================================
# Shared tooltip object - created here (before any tiles exist) so every
# tile's SetToolTip call below has something to attach to. Previously this
# was created near the bottom of the script, AFTER the tile loops had
# already run, so any SetToolTip call made while building a tile earlier
# in the script would have failed silently (the object didn't exist yet).
# Only the exit tile, which is built after this point, ever got one.
$script:mainToolTip = New-Object System.Windows.Forms.ToolTip
$script:mainToolTip.AutoPopDelay = 5000
$script:mainToolTip.InitialDelay = 300
$script:mainToolTip.ReshowDelay  = 100

# ── Small info window shown when the info icon is clicked ────────────────
function Show-InfoPopup {
    $pal = Get-CurrentTilePalette
    $accent = Get-SafeColor $pal.Accent ([System.Drawing.Color]::FromArgb(212, 175, 55))

    $popup = New-Object System.Windows.Forms.Form
    $popup.Text            = "About"
    $popup.Size            = New-Object System.Drawing.Size(320, 170)
    $popup.StartPosition   = "CenterParent"
    $popup.FormBorderStyle = "FixedDialog"
    $popup.MaximizeBox     = $false
    $popup.MinimizeBox     = $false
    $popup.BackColor       = [System.Drawing.Color]::Black
    $popup.ShowIcon        = $false

    $titleLbl = New-Object System.Windows.Forms.Label
    $titleLbl.Text      = "SUIOVOI CONFIGURATOR"
    $titleLbl.Font      = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
    $titleLbl.ForeColor = $accent
    $titleLbl.TextAlign = "MiddleCenter"
    $titleLbl.Location  = New-Object System.Drawing.Point(10, 15)
    $titleLbl.Size      = New-Object System.Drawing.Size(284, 26)
    $popup.Controls.Add($titleLbl)

    $verLbl = New-Object System.Windows.Forms.Label
    $verLbl.Text      = "Version $script:CurrentVersion"
    $verLbl.Font      = New-Object System.Drawing.Font("Segoe UI", 9)
    $verLbl.ForeColor = [System.Drawing.Color]::White
    $verLbl.TextAlign = "MiddleCenter"
    $verLbl.Location  = New-Object System.Drawing.Point(10, 50)
    $verLbl.Size      = New-Object System.Drawing.Size(284, 20)
    $popup.Controls.Add($verLbl)

    $creditLbl = New-Object System.Windows.Forms.Label
    $creditLbl.Text      = "Made by @ImJrid"
    $creditLbl.Font      = New-Object System.Drawing.Font("Segoe UI", 9)
    $creditLbl.ForeColor = [System.Drawing.Color]::White
    $creditLbl.TextAlign = "MiddleCenter"
    $creditLbl.Location  = New-Object System.Drawing.Point(10, 75)
    $creditLbl.Size      = New-Object System.Drawing.Size(284, 20)
    $popup.Controls.Add($creditLbl)

    $okBtn = New-Object System.Windows.Forms.Button
    $okBtn.Text      = "OK"
    $okBtn.Size      = New-Object System.Drawing.Size(80, 26)
    $okBtn.Location  = New-Object System.Drawing.Point(120, 98)
    $okBtn.FlatStyle = "Flat"
    $okBtn.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
    $okBtn.ForeColor = $accent
    $okBtn.FlatAppearance.BorderColor = $accent
    $okBtn.Add_Click({ $popup.Close() })
    $popup.Controls.Add($okBtn)
    $popup.AcceptButton = $okBtn

    $popup.ShowDialog($form) | Out-Null
    $popup.Dispose()
}

# ── Small info icon, top-right of the header ─────────────────────────────
# Click opens a small popup window with app name, version, and credits
$infoIcon = New-Object System.Windows.Forms.Label
$infoIcon.Location  = New-Object System.Drawing.Point(818, 10)
$infoIcon.Size      = New-Object System.Drawing.Size(20, 20)
$infoIcon.BackColor = [System.Drawing.Color]::Transparent
$infoIcon.Cursor    = [System.Windows.Forms.Cursors]::Hand
$infoIcon.Text      = ""

$infoIcon.Add_Paint({
    param($sender, $e)
    $g = $e.Graphics
    try {
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $pal = Get-CurrentTilePalette
        $ringColor = Get-SafeColor $pal.Accent ([System.Drawing.Color]::FromArgb(212,175,55))
        $pen = New-Object System.Drawing.Pen($ringColor, 1.5)
        $g.DrawEllipse($pen, 1, 1, 17, 17)
        $font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
        $brush = New-Object System.Drawing.SolidBrush($ringColor)
        $sf = New-Object System.Drawing.StringFormat
        $sf.Alignment = [System.Drawing.StringAlignment]::Center
        $sf.LineAlignment = [System.Drawing.StringAlignment]::Center
        $rect = New-Object System.Drawing.RectangleF(0, 0, $sender.Width, $sender.Height)
        $g.DrawString("i", $font, $brush, $rect, $sf)
        $pen.Dispose(); $font.Dispose(); $brush.Dispose(); $sf.Dispose()
    } catch {}
})

$headerPanel.Controls.Add($infoIcon)
$infoIcon.BringToFront()
$infoIcon.Add_Click({ Show-InfoPopup })

$websites = @(
    @{Name="Setup Controller";         URL="https://sy2.suiovoi.cc/";                                Desc="Calibrate and configure your controller settings and polling rate settings"},
    @{Name="Sellers";                  URL="SELLERS_PAGES";          Desc="Buy from @l1mitRoller or @headglytch - X or Discord"},
    @{Name="Joystick Tester";          URL="https://hardwaretester.com/gamepad";                         Desc="Test your joystick inputs, buttons, and analog stick precision"},
    @{Name="Polling Rate Checker";     URL="https://tools.mariusheier.com/poll_checker.html";            Desc="Test and verify your controller's polling rate"},
    @{Name="USB Latency Analyzer"; URL="USB_ANALYZER";                                                Desc="Count chips between your device and CPU. More chips = more latency"},
    @{Name="USB Cache Cleaner";        URL="CACHE_CLEANER";                                              Desc="Clear stuck USB device cache so your controller re-enumerates cleanly"},
    @{Name="Creator Twitter";          URL="https://x.com/Rilol_8";                                  Desc="Follow for updates, tips, and support"},
    @{Name="Suiovoi Toolbox";           URL="TOOLBOX";                                                    Desc="Gamebar Notification Removal, FR33THY Ultimate Guide, and more"}
    # Removed - this pulled from the original creator's repo and would overwrite
    # our customizations. Uncomment to restore:
    # @{Name="Update Script";            URL="UPDATE";                                                     Desc="Download and install the latest version automatically"},
    # "Exit" is no longer part of the 2-column grid - it's built separately
    # below as a single wide tile centered along the bottom of the page.
)

function New-RoundedPath {
    param([System.Drawing.Rectangle]$Rect, [int]$Radius)
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = $Radius * 2
    $path.AddArc($Rect.X, $Rect.Y, $d, $d, 180, 90)
    $path.AddArc(($Rect.Right - $d), $Rect.Y, $d, $d, 270, 90)
    $path.AddArc(($Rect.Right - $d), ($Rect.Bottom - $d), $d, $d, 0, 90)
    $path.AddArc($Rect.X, ($Rect.Bottom - $d), $d, $d, 90, 90)
    $path.CloseFigure()
    return $path
}

$cols = 2
$colGap = 20
$rowGap = 16
$startX = 30
$rightMargin = 30
$mainHeaderBottom = 90
$mainPanelHeight  = 795
# +1 reserves a final full-width row at the bottom for the standalone Exit
# tile below, so the grid tiles above keep the exact same size as before.
$rows = [Math]::Ceiling(($websites.Count + 1) / $cols)
$cardWidth  = [int]((790 - (($cols - 1) * $colGap)) / $cols)
$cardHeight = [int]((($mainPanelHeight - $mainHeaderBottom) - (($rows - 1) * $rowGap)) / $rows)

$index = 0
foreach ($site in $websites) {
    $col = $index % $cols
    $row = [int][Math]::Floor($index / $cols)
    $xPos = $startX + ($col * ($cardWidth + $colGap))
    $yPos = $mainHeaderBottom + ($row * ($cardHeight + $rowGap))

    $tile = New-Object System.Windows.Forms.Button
    $tile.Location = New-Object System.Drawing.Point($xPos, $yPos)
    $tile.Size = New-Object System.Drawing.Size($cardWidth, $cardHeight)
    $tile.FlatStyle = "Flat"
    $tile.FlatAppearance.BorderSize = 0
    $tile.BackColor = $script:BgColor
    $tile.ForeColor = [System.Drawing.Color]::White
    $tile.Text = ""
    $tile.TextAlign = "MiddleCenter"
    $tile.Cursor = [System.Windows.Forms.Cursors]::Hand
    $tile.Tag = $site.URL

    $roundPath = New-RoundedPath -Rect (New-Object System.Drawing.Rectangle(0, 0, $cardWidth, $cardHeight)) -Radius 16
    $tile.Region = New-Object System.Drawing.Region($roundPath)

    $script:suiovoiHover[$tile] = $false

    $tile.Add_MouseEnter({
        if (-not $script:suiovoiHover) { $script:suiovoiHover = @{} }
        $script:suiovoiHover[$this] = $true
        $this.Invalidate()
    })

    $tile.Add_MouseLeave({
        if (-not $script:suiovoiHover) { $script:suiovoiHover = @{} }
        $script:suiovoiHover[$this] = $false
        $this.Invalidate()
    })

    $siteName = $site.Name
    $siteDesc = $site.Desc
    $iconLetter = $siteName.Substring(0, 1).ToUpper()

    $script:mainToolTip.SetToolTip($tile, "$siteName`n$siteDesc")

    $tile.Add_Paint({
        param($sender, $e)
        $g = $e.Graphics
        try {
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit

        if (-not $script:suiovoiHover) { $script:suiovoiHover = @{} }
        $isHover = $false
        if ($script:suiovoiHover.ContainsKey($sender)) { $isHover = $script:suiovoiHover[$sender] }
        $pal         = Get-CurrentTilePalette
        $topColor    = Get-SafeColor $(if ($isHover) { $pal.BgTopH } else { $pal.BgTopN }) ([System.Drawing.Color]::FromArgb(42,12,12))
        $botColor    = Get-SafeColor $(if ($isHover) { $pal.BgBotH } else { $pal.BgBotN }) ([System.Drawing.Color]::FromArgb(16,3,3))
        $borderTop   = Get-SafeColor $(if ($isHover) { $pal.BorderTopH } else { $pal.BorderTopN }) ([System.Drawing.Color]::FromArgb(230,210,140))
        $borderBot   = Get-SafeColor $(if ($isHover) { $pal.BorderBotH } else { $pal.BorderBotN }) ([System.Drawing.Color]::FromArgb(150,120,40))
        $borderColor = Get-SafeColor $(if ($isHover) { $pal.Glow } else { $pal.Accent }) ([System.Drawing.Color]::FromArgb(212,175,55))
        $borderWidth = if ($isHover) { 2 } else { 1 }
        $shadowOff   = 6

        # Soft layered drop shadow (kept within control bounds)
        $shRect1 = New-Object System.Drawing.Rectangle(($shadowOff-2), ($shadowOff-2), ($sender.Width-1), ($sender.Height-1))
        $shPath1 = New-RoundedPath -Rect $shRect1 -Radius 16
        $shBrush1 = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(60, 0, 0, 0))
        $g.FillPath($shBrush1, $shPath1)
        $shRect2 = New-Object System.Drawing.Rectangle($shadowOff, $shadowOff, ($sender.Width-1-2), ($sender.Height-1-2))
        $shPath2 = New-RoundedPath -Rect $shRect2 -Radius 16
        $shBrush2 = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(100, 0, 0, 0))
        $g.FillPath($shBrush2, $shPath2)

        # Card face (inset up-left so the shadow peeks out bottom-right)
        $faceW = $sender.Width - 1 - $shadowOff
        $faceH = $sender.Height - 1 - $shadowOff
        $rect = New-Object System.Drawing.Rectangle(0, 0, $faceW, $faceH)
        $path = New-RoundedPath -Rect $rect -Radius 16

        $bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, $topColor, $botColor, 90)
        $g.FillPath($bgBrush, $path)

        $borderRectF = New-Object System.Drawing.Rectangle(0, 0, $faceW, $faceH)
        $borderBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($borderRectF, $borderTop, $borderBot, 90)
        $borderPen = New-Object System.Drawing.Pen($borderBrush, $borderWidth)
        $g.DrawPath($borderPen, $path)

        # Subtle top highlight line for a beveled-glass feel
        $hlPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(70, 255, 255, 255), 1)
        $g.DrawLine($hlPen, 14, 3, ($faceW - 14), 3)

        # Icon badge
        $iconRect = New-Object System.Drawing.Rectangle(16, [int](($faceH - 48) / 2), 48, 48)
        $iconPath = New-RoundedPath -Rect $iconRect -Radius 10
        $iconBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($iconRect, (Get-SafeColor $pal.IconTop ([System.Drawing.Color]::FromArgb(90,26,26))), (Get-SafeColor $pal.IconBot ([System.Drawing.Color]::FromArgb(50,10,10))), 90)
        $g.FillPath($iconBrush, $iconPath)
        $iconPen = New-Object System.Drawing.Pen($borderColor, 1)
        $g.DrawPath($iconPen, $iconPath)

        $iconFont = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
        $iconBrushText = New-Object System.Drawing.SolidBrush($borderColor)
        $iconSf = New-Object System.Drawing.StringFormat
        $iconSf.Alignment = [System.Drawing.StringAlignment]::Center
        $iconSf.LineAlignment = [System.Drawing.StringAlignment]::Center
        $iconRectF = New-Object System.Drawing.RectangleF($iconRect.X, $iconRect.Y, $iconRect.Width, $iconRect.Height)
        $g.DrawString($iconLetter, $iconFont, $iconBrushText, $iconRectF, $iconSf)

        # Title + description
        $textX = 76
        $textWidth = $faceW - $textX - 14
        $titleFont = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
        $descFont = New-Object System.Drawing.Font("Segoe UI", 8.5)
        $whiteBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
        $goldBrush = New-Object System.Drawing.SolidBrush((Get-SafeColor $pal.Accent ([System.Drawing.Color]::FromArgb(212,175,55))))

        $g.DrawString($siteName, $titleFont, $whiteBrush, [float]$textX, [float](($faceH / 2) - 20))
        $descRect = New-Object System.Drawing.RectangleF($textX, (($faceH / 2) + 4), $textWidth, ($faceH / 2 - 8))
        $g.DrawString($siteDesc, $descFont, $goldBrush, $descRect)

        $bgBrush.Dispose(); $borderPen.Dispose(); $iconBrush.Dispose(); $iconPen.Dispose()
        $iconBrushText.Dispose(); $whiteBrush.Dispose(); $goldBrush.Dispose()
        $titleFont.Dispose(); $descFont.Dispose(); $iconFont.Dispose()
        $path.Dispose(); $iconPath.Dispose()
        $shBrush1.Dispose(); $shBrush2.Dispose(); $shPath1.Dispose(); $shPath2.Dispose()
        $borderBrush.Dispose(); $hlPen.Dispose()
        } catch {
            if (-not $script:paintDebugShown) {
                $script:paintDebugShown = $true
                [System.Windows.Forms.MessageBox]::Show(
                    "MAIN TILE PAINT ERROR:`n`n$($_.Exception.GetType().FullName)`n$($_.Exception.Message)`n`n$($_.InvocationInfo.PositionMessage)",
                    "Debug - Paint Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning
                ) | Out-Null
            }
        }
    }.GetNewClosure())

    $tile.Add_Click({
        $targetUrl = $this.Tag
        
        if ($targetUrl -eq "EXIT") {
            $form.Close()
            return
        }
        
        if ($targetUrl -eq "TOOLBOX") {
            Show-ToolboxPage
            return
        }
        
        if ($targetUrl -eq "USB_ANALYZER") {
            Show-UsbAnalyzer
            return
        }

        if ($targetUrl -eq "CACHE_CLEANER") {
            $cleanerPath = "C:\SUIOVOI CONFIG\CacheCleaner.exe"
            if (Test-Path $cleanerPath) {
                Start-Process $cleanerPath
            } else {
                [System.Windows.Forms.MessageBox]::Show(
                    "USB Cache Cleaner not found.`n`nPlace the tool at:`n$cleanerPath",
                    "Suiovoi Configurator",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Warning
                ) | Out-Null
            }
            return
        }
        
        if ($targetUrl -eq "GAMEBAR_FIX") {
            Invoke-GameBarNotificationFix
            return
        }
        
        if ($targetUrl -eq "SELLERS_PAGES") {
            Show-SellerPicker
            return
        }

        if ($targetUrl -eq "UPDATE") {
            # Capture variables locally before running
            $releasesApi = $script:ReleasesApi
            $installPath = $script:InstallPath
            $logFile     = "$script:InstallDir\update.log"
            try {
                $wc = New-Object System.Net.WebClient
                $wc.Headers.Add("User-Agent", "MARIUS-Updater")

                $json        = $wc.DownloadString($releasesApi)
                $tagLine     = (($json -split '"tag_name"\s*:\s*"')[1] -split '"')[0].TrimStart('vV')
                $assetBlock  = ($json -split '"browser_download_url"\s*:\s*"')[1]
                $downloadUrl = ($assetBlock -split '"')[0]

                if (-not $downloadUrl -or $downloadUrl -notlike "*.ps1") {
                    Add-Content -Path $logFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] UPDATE - No .ps1 asset in release v$tagLine - falling back to main branch" -ErrorAction SilentlyContinue
                    $downloadUrl = $script:ScriptUrl

                    try {
                        $mainScript = $wc.DownloadString($script:ScriptUrl)
                        $mainVerLine = ($mainScript -split "`n" | Where-Object { $_ -match '^\$script:CurrentVersion\s*=' } | Select-Object -First 1)
                        $tagLine = ($mainVerLine -replace '.*=\s*"([^"]+)".*', '$1').Trim()
                        Add-Content -Path $logFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] UPDATE - Main branch reports version: $tagLine" -ErrorAction SilentlyContinue
                    } catch {
                        Add-Content -Path $logFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] UPDATE - Could not read version from main branch - skipping" -ErrorAction SilentlyContinue
                        return
                    }
                }

                Add-Content -Path $logFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] UPDATE - Forcing install of v$tagLine from $downloadUrl" -ErrorAction SilentlyContinue

                $tempFile = "$env:TEMP\MARIUS_update_$tagLine.ps1"
                $wc.DownloadFile($downloadUrl, $tempFile)

                if (-not (Test-Path $tempFile)) {
                    Add-Content -Path $logFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] UPDATE - FAILED temp file missing" -ErrorAction SilentlyContinue
                    return
                }
                $dlSize = (Get-Item $tempFile).Length
                if ($dlSize -lt 10000) {
                    Add-Content -Path $logFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] UPDATE - FAILED file too small ($dlSize bytes)" -ErrorAction SilentlyContinue
                    Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
                    return
                }

                Remove-Item -Path $installPath -Force -ErrorAction SilentlyContinue
                Copy-Item   -Path $tempFile -Destination $installPath -Force
                Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue

                if (-not (Test-Path $installPath)) {
                    Add-Content -Path $logFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] UPDATE - FAILED new file not at install path" -ErrorAction SilentlyContinue
                    return
                }
                $instSize = (Get-Item $installPath).Length
                Add-Content -Path $logFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] UPDATE - SUCCESS v$tagLine installed ($instSize bytes) - relaunching" -ErrorAction SilentlyContinue

                $args = "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$installPath`""
                [System.Diagnostics.Process]::Start("cmd.exe", "/c start powershell.exe $args") | Out-Null
                Start-Sleep -Milliseconds 3000
                [System.Diagnostics.Process]::GetCurrentProcess().Kill()
            } catch {
                Add-Content -Path $logFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] UPDATE - ERROR $($_.Exception.Message)" -ErrorAction SilentlyContinue
            }
            return
        }
        
        $defaultBrowser = Get-DefaultBrowser
        $browserPath = Get-BrowserPath $defaultBrowser
        
        if (-not $browserPath) {
            # Try all Chromium browsers in order of preference
            $browsersToTry = @("Chrome", "Edge", "Brave", "Opera", "Vivaldi", "Arc")
            foreach ($browser in $browsersToTry) {
                if ($browser -ne $defaultBrowser) {
                    $browserPath = Get-BrowserPath $browser
                    if ($browserPath) { break }
                }
            }
        }
        
        if ($browserPath) {
            $screen = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
            $windowWidth = 1200
            $windowHeight = 800
            $left = [Math]::Floor(($screen.Width - $windowWidth) / 2)
            $top = [Math]::Floor(($screen.Height - $windowHeight) / 2)
            
            $arguments = "--app=`"$targetUrl`" --window-size=$windowWidth,$windowHeight --window-position=$left,$top"
            
            Start-Process -FilePath $browserPath -ArgumentList $arguments
        } else {
            Start-Process $targetUrl
        }
    })
    
    $mainPanel.Controls.Add($tile)
    $script:mainTiles.Add($tile)
    $index++
}

# ============================================================================
# EXIT TILE - standalone, full-width, centered along the bottom of the grid
# ============================================================================
$exitRow  = $rows - 1
$exitTile = New-Object System.Windows.Forms.Button
$exitTile.Location = New-Object System.Drawing.Point($startX, ($mainHeaderBottom + ($exitRow * ($cardHeight + $rowGap))))
$exitTile.Size = New-Object System.Drawing.Size((($cardWidth * $cols) + ($colGap * ($cols - 1))), $cardHeight)
$exitTile.FlatStyle = "Flat"
$exitTile.FlatAppearance.BorderSize = 0
$exitTile.BackColor = [System.Drawing.Color]::FromArgb(26, 6, 6)
$exitTile.ForeColor = [System.Drawing.Color]::White
$exitTile.Text = ""
$exitTile.TextAlign = "MiddleCenter"
$exitTile.Cursor = [System.Windows.Forms.Cursors]::Hand
$exitTile.Tag = "EXIT"

$exitRoundPath = New-RoundedPath -Rect (New-Object System.Drawing.Rectangle(0, 0, $exitTile.Width, $exitTile.Height)) -Radius 16
$exitTile.Region = New-Object System.Drawing.Region($exitRoundPath)
$script:suiovoiHover[$exitTile] = $false

$exitTile.Add_MouseEnter({ if (-not $script:suiovoiHover) { $script:suiovoiHover = @{} }; $script:suiovoiHover[$this] = $true; $this.Invalidate() })
$exitTile.Add_MouseLeave({ if (-not $script:suiovoiHover) { $script:suiovoiHover = @{} }; $script:suiovoiHover[$this] = $false; $this.Invalidate() })

$exitTile.Add_Paint({
    param($sender, $e)
    $g = $e.Graphics
    try {
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit

    if (-not $script:suiovoiHover) { $script:suiovoiHover = @{} }
    $isHover = $false
    if ($script:suiovoiHover.ContainsKey($sender)) { $isHover = $script:suiovoiHover[$sender] }
    $topColor    = Get-SafeColor $(if ($isHover) { $script:BgTileTopH } else { $script:BgTileTopN }) ([System.Drawing.Color]::FromArgb(42,12,12))
    $botColor    = Get-SafeColor $(if ($isHover) { $script:BgTileBotH } else { $script:BgTileBotN }) ([System.Drawing.Color]::FromArgb(16,3,3))
    $borderTop   = Get-SafeColor $(if ($isHover) { $script:AccentBorderTopH } else { $script:AccentBorderTopN }) ([System.Drawing.Color]::FromArgb(230,210,140))
    $borderBot   = Get-SafeColor $(if ($isHover) { $script:AccentBorderBotH } else { $script:AccentBorderBotN }) ([System.Drawing.Color]::FromArgb(150,120,40))
    $borderColor = Get-SafeColor $(if ($isHover) { $script:AccentGlow } else { $script:AccentColor }) ([System.Drawing.Color]::FromArgb(212,175,55))
    $borderWidth = if ($isHover) { 2 } else { 1 }
    $shadowOff   = 6

    $shRect1 = New-Object System.Drawing.Rectangle(($shadowOff-2), ($shadowOff-2), ($sender.Width-1), ($sender.Height-1))
    $shPath1 = New-RoundedPath -Rect $shRect1 -Radius 16
    $shBrush1 = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(60, 0, 0, 0))
    $g.FillPath($shBrush1, $shPath1)
    $shRect2 = New-Object System.Drawing.Rectangle($shadowOff, $shadowOff, ($sender.Width-1-2), ($sender.Height-1-2))
    $shPath2 = New-RoundedPath -Rect $shRect2 -Radius 16
    $shBrush2 = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(100, 0, 0, 0))
    $g.FillPath($shBrush2, $shPath2)

    $faceW = $sender.Width - 1 - $shadowOff
    $faceH = $sender.Height - 1 - $shadowOff
    $rect = New-Object System.Drawing.Rectangle(0, 0, $faceW, $faceH)
    $path = New-RoundedPath -Rect $rect -Radius 16

    $bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, $topColor, $botColor, 90)
    $g.FillPath($bgBrush, $path)

    $borderRectF = New-Object System.Drawing.Rectangle(0, 0, $faceW, $faceH)
    $borderBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($borderRectF, $borderTop, $borderBot, 90)
    $borderPen = New-Object System.Drawing.Pen($borderBrush, $borderWidth)
    $g.DrawPath($borderPen, $path)

    $hlPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(70, 255, 255, 255), 1)
    $g.DrawLine($hlPen, 14, 3, ($faceW - 14), 3)

    # Centered icon + label (no description line needed for a single action tile)
    $iconSize = 40
    $iconRect = New-Object System.Drawing.Rectangle([int](($faceW - $iconSize) / 2 - 90), [int](($faceH - $iconSize) / 2), $iconSize, $iconSize)
    $iconPath = New-RoundedPath -Rect $iconRect -Radius 10
    $iconBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($iconRect, (Get-SafeColor $script:BgIconTop ([System.Drawing.Color]::FromArgb(90,26,26))), (Get-SafeColor $script:BgIconBot ([System.Drawing.Color]::FromArgb(50,10,10))), 90)
    $g.FillPath($iconBrush, $iconPath)
    $iconPen = New-Object System.Drawing.Pen($borderColor, 1)
    $g.DrawPath($iconPen, $iconPath)

    $iconFont = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
    $iconBrushText = New-Object System.Drawing.SolidBrush($borderColor)
    $iconSf = New-Object System.Drawing.StringFormat
    $iconSf.Alignment = [System.Drawing.StringAlignment]::Center
    $iconSf.LineAlignment = [System.Drawing.StringAlignment]::Center
    $iconRectF = New-Object System.Drawing.RectangleF($iconRect.X, $iconRect.Y, $iconRect.Width, $iconRect.Height)
    $g.DrawString("E", $iconFont, $iconBrushText, $iconRectF, $iconSf)

    $titleFont = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
    $whiteBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    $titleSf = New-Object System.Drawing.StringFormat
    $titleSf.Alignment = [System.Drawing.StringAlignment]::Near
    $titleSf.LineAlignment = [System.Drawing.StringAlignment]::Center
    $titleRectF = New-Object System.Drawing.RectangleF(($iconRect.Right + 16), 0, 200, $faceH)
    $g.DrawString("EXIT", $titleFont, $whiteBrush, $titleRectF, $titleSf)

    $bgBrush.Dispose(); $borderPen.Dispose(); $iconBrush.Dispose(); $iconPen.Dispose()
    $iconBrushText.Dispose(); $whiteBrush.Dispose()
    $titleFont.Dispose(); $iconFont.Dispose()
    $path.Dispose(); $iconPath.Dispose()
    $shBrush1.Dispose(); $shBrush2.Dispose(); $shPath1.Dispose(); $shPath2.Dispose()
    $borderBrush.Dispose(); $hlPen.Dispose()
    } catch {
        if (-not $script:paintDebugShown) {
            $script:paintDebugShown = $true
            [System.Windows.Forms.MessageBox]::Show(
                "EXIT TILE PAINT ERROR:`n`n$($_.Exception.GetType().FullName)`n$($_.Exception.Message)`n`n$($_.InvocationInfo.PositionMessage)",
                "Debug - Paint Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning
            ) | Out-Null
        }
    }
})

$exitTile.Add_Click({ $form.Close() })

$mainPanel.Controls.Add($exitTile)
$script:mainTiles.Add($exitTile)

# Hover tooltip crediting the reskin author (mainToolTip was already
# created near the top of the script, before the tile loops ran)
$script:mainToolTip.SetToolTip($exitTile, "Made by @ImJrid")

# ============================================================================
# SOLID PURPLE BORDER (kept in sync with the tile purple set above)
# ============================================================================
# Tile background/border/hover colors are already purple + dark blue where
# the tiles are created above; this just re-applies the same purple to the
# outer form border so everything matches.
$script:form.BackColor = $script:AccentColor
# ── SETTINGS FILE WATCHER - hot-reload when Settings.ini is edited externally ─
$script:settingsWatcher = $null
try {
    $script:settingsWatcher = New-Object System.IO.FileSystemWatcher
    $script:settingsWatcher.Path   = $script:InstallDir
    $script:settingsWatcher.Filter = "Settings.ini"
    $script:settingsWatcher.NotifyFilter = [System.IO.NotifyFilters]::LastWrite
    $script:settingsWatcher.EnableRaisingEvents = $true

    # Use a short debounce timer so rapid saves don't retrigger multiple times
    $script:watchDebounce = New-Object System.Windows.Forms.Timer
    $script:watchDebounce.Interval = 600

    $script:watchDebounce.Add_Tick({
        $script:watchDebounce.Stop()
        # Read new settings
        Read-Settings
        # Apply volume change immediately if music is playing
        if ($script:MusicEnabled) {
            [MciAudio]::SetVolume($script:MusicVolume)
        } else {
            Stop-Music
        }
        # Refresh volume UI on the UI thread
        if ($muteBtn -and $muteBtn.IsHandleCreated) {
            $muteBtn.Invoke([Action]{
                $muteBtn.Invalidate()
                $volPctLabel.Text = "$($script:MusicVolume)%"
                $script:volSliderPanel.Invalidate()
            })
        }
    })

    Register-ObjectEvent -InputObject $script:settingsWatcher -EventName Changed -MessageData $script:watchDebounce -Action {
        $timer = $Event.MessageData
        $timer.Stop()
        $timer.Start()
    } | Out-Null
} catch {}

# Solid black backdrop for the whole bottom strip - fully spans the panel's
# right/bottom edges so no maroon background peeks through behind the
# version/credits/volume controls that sit on top of it.
$bottomBar = New-Object System.Windows.Forms.Panel
$bottomBar.Location  = New-Object System.Drawing.Point(0, 796)
$bottomBar.Size      = New-Object System.Drawing.Size(850, 34)
$bottomBar.BackColor = [System.Drawing.Color]::Black
$mainPanel.Controls.Add($bottomBar)
$bottomBar.SendToBack()

$versionLabel = New-Object System.Windows.Forms.Label
$versionLabel.Location = New-Object System.Drawing.Point(5, 800)
$versionLabel.Size = New-Object System.Drawing.Size(70, 28)
$versionLabel.Text = "v$script:CurrentVersion"
$versionLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$versionLabel.ForeColor = $script:AccentColor
$versionLabel.TextAlign = "MiddleLeft"
$versionLabel.BackColor = [System.Drawing.Color]::Black
$mainPanel.Controls.Add($versionLabel)

# Credits - full panel width, MiddleCenter, sent to back so controls above it get clicks
$creditsLabel = New-Object System.Windows.Forms.Label
$creditsLabel.Location = New-Object System.Drawing.Point(14, 800)
$creditsLabel.Size = New-Object System.Drawing.Size(766, 28)
$creditsLabel.Text = "Board by @Rilol_8  |  Tool by @ImJrid"
$creditsLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$creditsLabel.ForeColor = $script:AccentColor
$creditsLabel.TextAlign = "MiddleCenter"
$creditsLabel.BackColor = [System.Drawing.Color]::Black
$mainPanel.Controls.Add($creditsLabel)
$creditsLabel.SendToBack()
$versionLabel.BringToFront()

# ── VOLUME CONTROL STRIP ─────────────────────────────────────────────────────
# Right-aligned: [speaker 24px][4][slider 100px][4][pct 34px] = 166px, X=678..844
$script:volSliderDragging = $false

# ── Speaker toggle - GDI+ painted, no Unicode dependency ────────────────────
$muteBtn = New-Object System.Windows.Forms.Button
$muteBtn.Location  = New-Object System.Drawing.Point(678, 800)
$muteBtn.Size      = New-Object System.Drawing.Size(24, 24)
$muteBtn.FlatStyle = "Flat"
$muteBtn.BackColor = [System.Drawing.Color]::Black
$muteBtn.Text      = ""
$muteBtn.Cursor    = [System.Windows.Forms.Cursors]::Hand
$muteBtn.FlatAppearance.BorderSize         = 0
$muteBtn.FlatAppearance.BorderColor        = [System.Drawing.Color]::Black
$muteBtn.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(20, 20, 20)
$muteBtn.FlatAppearance.MouseDownBackColor = [System.Drawing.Color]::Black
$muteBtn.TabStop = $false

$muteBtn.Add_Paint({
    param($sender, $e)
    $g = $e.Graphics
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $on  = $script:MusicEnabled
    $col = if ($on) { $script:AccentGlow } else { [System.Drawing.Color]::FromArgb(80,80,80) }
    $b   = New-Object System.Drawing.SolidBrush($col)
    $p   = New-Object System.Drawing.Pen($col, 1.5)

    # Speaker body: filled trapezoid
    $pts = @(
        [System.Drawing.Point]::new(3,8),
        [System.Drawing.Point]::new(7,8),
        [System.Drawing.Point]::new(11,4),
        [System.Drawing.Point]::new(11,18),
        [System.Drawing.Point]::new(7,14),
        [System.Drawing.Point]::new(3,14)
    )
    $g.FillPolygon($b, $pts)

    if ($on) {
        # Two sound arcs
        $g.DrawArc($p, 12, 7,  5,  8, -50, 100)
        $g.DrawArc($p, 13, 4,  8, 14, -50, 100)
    } else {
        # Red X
        $px = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(210,50,50), 2.0)
        $g.DrawLine($px, 13, 7, 20, 14)
        $g.DrawLine($px, 20, 7, 13, 14)
        $px.Dispose()
    }
    $b.Dispose(); $p.Dispose()
})

$muteBtn.Add_Click({
    Toggle-Music
    $muteBtn.Invalidate()
    $script:volSliderPanel.Invalidate()
})
$mainPanel.Controls.Add($muteBtn)
$muteBtn.BringToFront()

# ── Slim volume slider panel ─────────────────────────────────────────────────
$script:volSliderPanel = New-Object System.Windows.Forms.Panel
$script:volSliderPanel.Location  = New-Object System.Drawing.Point(706, 805)
$script:volSliderPanel.Size      = New-Object System.Drawing.Size(100, 16)
$script:volSliderPanel.BackColor = [System.Drawing.Color]::Black
$script:volSliderPanel.Cursor    = [System.Windows.Forms.Cursors]::Hand

function Get-ThumbX {
    $trackW = $script:volSliderPanel.Width - 10
    return 5 + [int]($script:MusicVolume / 100.0 * $trackW)
}

$script:volSliderPanel.Add_Paint({
    param($sender, $e)
    $g = $e.Graphics
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $on      = $script:MusicEnabled
    $cy      = 7
    $trackW  = $sender.Width - 10
    $thumbX  = Get-ThumbX
    $thumbR  = 5

    # Track bg
    $bgB = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(55,55,55))
    $g.FillRectangle($bgB, 5, ($cy-1), $trackW, 3)
    $bgB.Dispose()

    # Fill + thumb color
    $fc = if ($on) { $script:AccentGlow } else { [System.Drawing.Color]::FromArgb(75,75,75) }
    $fb = New-Object System.Drawing.SolidBrush($fc)
    $fw = [Math]::Max(0, $thumbX - 5)
    if ($fw -gt 0) { $g.FillRectangle($fb, 5, ($cy-1), $fw, 3) }
    $g.FillEllipse($fb, ($thumbX - $thumbR), ($cy - $thumbR + 1), $thumbR*2, $thumbR*2)
    $fb.Dispose()
})

$script:volSliderPanel.Add_MouseDown({
    param($s, $e)
    $script:volSliderDragging = $true
    $raw = [int](([Math]::Max(5,[Math]::Min($s.Width-5,$e.X))-5)/($s.Width-10)*100)
    $script:MusicVolume = [Math]::Max(0,[Math]::Min(100,$raw))
    [MciAudio]::SetVolume($script:MusicVolume)
    $volPctLabel.Text = "$($script:MusicVolume)%"
    $s.Invalidate()
})
$script:volSliderPanel.Add_MouseMove({
    param($s, $e)
    if (-not $script:volSliderDragging) { return }
    $raw = [int](([Math]::Max(5,[Math]::Min($s.Width-5,$e.X))-5)/($s.Width-10)*100)
    $script:MusicVolume = [Math]::Max(0,[Math]::Min(100,$raw))
    [MciAudio]::SetVolume($script:MusicVolume)
    $volPctLabel.Text = "$($script:MusicVolume)%"
    $s.Invalidate()
})
$script:volSliderPanel.Add_MouseUp({
    param($s, $e)
    if (-not $script:volSliderDragging) { return }
    $script:volSliderDragging = $false
    Save-Settings
    $s.Invalidate()
})

$mainPanel.Controls.Add($script:volSliderPanel)
$script:volSliderPanel.BringToFront()

# ── Volume % label ────────────────────────────────────────────────────────────
$volPctLabel = New-Object System.Windows.Forms.Label
$volPctLabel.Location  = New-Object System.Drawing.Point(810, 800)
$volPctLabel.Size      = New-Object System.Drawing.Size(34, 24)
$volPctLabel.Text      = "$($script:MusicVolume)%"
$volPctLabel.Font      = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
$volPctLabel.ForeColor = [System.Drawing.Color]::FromArgb(160,160,160)
$volPctLabel.BackColor = [System.Drawing.Color]::Black
$volPctLabel.TextAlign = "MiddleLeft"
$mainPanel.Controls.Add($volPctLabel)
$volPctLabel.BringToFront()

$form.Controls.Add($mainPanel)

$form.Add_KeyDown({
    param($sender, $e)
    if ($e.KeyCode -eq "Escape") {
        $form.Close()
    }
})

$form.Add_Shown({
    $form.Activate()
    # Sync volume controls to actual loaded settings
    $muteBtn.Invalidate()
    $volPctLabel.Text = "$($script:MusicVolume)%"
    $script:volSliderPanel.Invalidate()
    # Retry music in case mp3 downloaded after initial Start-Music
    if ($script:MusicEnabled) { Start-Music }
})
$form.Add_FormClosing({
    $script:rgbTimer.Stop()
    $script:rgbTimer.Dispose()
    if ($script:settingsWatcher) {
        $script:settingsWatcher.EnableRaisingEvents = $false
        $script:settingsWatcher.Dispose()
    }
    if ($script:watchDebounce) { $script:watchDebounce.Stop(); $script:watchDebounce.Dispose() }
    Stop-Music
})
$form.Add_FormClosed({
    [System.Diagnostics.Process]::GetCurrentProcess().Kill()
})
[void]$form.ShowDialog()
