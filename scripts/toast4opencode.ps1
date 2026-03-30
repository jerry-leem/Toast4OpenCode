[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateSet("complete", "error", "permission", "input", "sound")]
    [string]$Event,

    [Parameter(Position = 1)]
    [string]$Title,

    [Parameter(Position = 2)]
    [string]$Message,

    [string]$ConfigPath,

    [ValidateSet(
        "Default",
        "IM",
        "Mail",
        "Reminder",
        "SMS",
        "Alarm",
        "Alarm2",
        "Alarm3",
        "Alarm4",
        "Alarm5",
        "Alarm6",
        "Alarm7",
        "Alarm8",
        "Alarm9",
        "Alarm10",
        "Call",
        "Call2",
        "Call3",
        "Call4",
        "Call5",
        "Call6",
        "Call7",
        "Call8",
        "Call9",
        "Call10"
    )]
    [string]$Sound = "Default",

    [switch]$Silent
)

$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

if (-not ("Toast4OpenCode.Win32" -as [type])) {
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

namespace Toast4OpenCode {
    [StructLayout(LayoutKind.Sequential)]
    public struct FLASHWINFO {
        public UInt32 cbSize;
        public IntPtr hwnd;
        public UInt32 dwFlags;
        public UInt32 uCount;
        public UInt32 dwTimeout;
    }

    public static class Win32 {
        public const UInt32 FLASHW_STOP = 0;
        public const UInt32 FLASHW_CAPTION = 1;
        public const UInt32 FLASHW_TRAY = 2;
        public const UInt32 FLASHW_ALL = FLASHW_CAPTION | FLASHW_TRAY;
        public const UInt32 FLASHW_TIMERNOFG = 12;

        [DllImport("kernel32.dll")]
        public static extern IntPtr GetConsoleWindow();

        [DllImport("user32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool FlashWindowEx(ref FLASHWINFO pwfi);
    }
}
"@
}

function Write-ExitError {
    param(
        [string]$Text,
        [int]$Code = 1
    )

    [Console]::Error.WriteLine($Text)
    exit $Code
}

function Get-DefaultConfigPath {
    return [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\\setting.json"))
}

function Get-Config {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        Write-ExitError "Config file not found: $Path" 2
    }

    try {
        $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
        $config = $raw | ConvertFrom-Json
    }
    catch {
        Write-ExitError "Failed to read config file: $Path`n$($_.Exception.Message)" 2
    }

    foreach ($name in @("complete", "error", "permission", "input", "sound")) {
        if ($null -eq $config.PSObject.Properties[$name]) {
            Write-ExitError "Config file is missing required setting '$name'." 2
        }
    }

    return $config
}

function Test-BoolSetting {
    param(
        [object]$Config,
        [string]$Name
    )

    $value = $Config.$Name
    if ($value -is [bool]) {
        return $value
    }

    Write-ExitError "Config setting '$Name' must be true or false." 2
}

function Get-EventDefaults {
    param([string]$Name)

    switch ($Name) {
        "complete" {
            return @{
                Title = "OpenCode complete"
                Message = "The current OpenCode task completed successfully."
                Sound = "Default"
            }
        }
        "error" {
            return @{
                Title = "OpenCode error"
                Message = "OpenCode reported an error for the current task."
                Sound = "Alarm"
            }
        }
        "permission" {
            return @{
                Title = "OpenCode permission"
                Message = "OpenCode is waiting for a permission decision."
                Sound = "Call"
            }
        }
        "input" {
            return @{
                Title = "OpenCode input needed"
                Message = "OpenCode is waiting for user input."
                Sound = "Reminder"
            }
        }
        "sound" {
            return @{
                Title = "OpenCode alert"
                Message = "OpenCode played an attention sound."
                Sound = "SMS"
            }
        }
    }
}

function Get-TaskbarFlashSetting {
    param(
        [object]$Config,
        [string]$EventName
    )

    if ($null -eq $Config.PSObject.Properties["taskbarFlash"]) {
        return $false
    }

    $taskbarFlash = $Config.taskbarFlash

    if ($taskbarFlash -is [bool]) {
        return $taskbarFlash
    }

    if ($taskbarFlash -isnot [System.Management.Automation.PSCustomObject]) {
        Write-ExitError "Config setting 'taskbarFlash' must be true, false, or an object with per-event booleans." 2
    }

    $eventProperty = $taskbarFlash.PSObject.Properties[$EventName]
    if ($null -eq $eventProperty) {
        return $false
    }

    if ($eventProperty.Value -is [bool]) {
        return $eventProperty.Value
    }

    Write-ExitError "Config setting 'taskbarFlash.$EventName' must be true or false." 2
}

function Invoke-TaskbarFlash {
    param(
        [uint32]$Count = 3
    )

    $windowHandle = [Toast4OpenCode.Win32]::GetConsoleWindow()
    if ($windowHandle -eq [IntPtr]::Zero) {
        return $false
    }

    $flashInfo = New-Object Toast4OpenCode.FLASHWINFO
    $flashInfo.cbSize = [System.Runtime.InteropServices.Marshal]::SizeOf([type][Toast4OpenCode.FLASHWINFO])
    $flashInfo.hwnd = $windowHandle
    $flashInfo.dwFlags = [Toast4OpenCode.Win32]::FLASHW_ALL
    $flashInfo.uCount = $Count
    $flashInfo.dwTimeout = 0

    [void][Toast4OpenCode.Win32]::FlashWindowEx([ref]$flashInfo)
    return $true
}

function Get-TooltipIcon {
    param([string]$EventName)

    switch ($EventName) {
        "error" { return [System.Windows.Forms.ToolTipIcon]::Error }
        "permission" { return [System.Windows.Forms.ToolTipIcon]::Warning }
        "input" { return [System.Windows.Forms.ToolTipIcon]::Warning }
        default { return [System.Windows.Forms.ToolTipIcon]::Info }
    }
}

function Play-NotificationSound {
    param(
        [string]$SoundName,
        [bool]$SoundEnabled,
        [bool]$SilentRequested
    )

    if ($SilentRequested -or -not $SoundEnabled) {
        return
    }

    switch ($SoundName) {
        { $_ -in @("Alarm", "Alarm2", "Alarm3", "Alarm4", "Alarm5", "Alarm6", "Alarm7", "Alarm8", "Alarm9", "Alarm10", "Call", "Call2", "Call3", "Call4", "Call5", "Call6", "Call7", "Call8", "Call9", "Call10") } {
            [System.Media.SystemSounds]::Hand.Play()
            return
        }
        { $_ -in @("Reminder", "Mail", "SMS") } {
            [System.Media.SystemSounds]::Asterisk.Play()
            return
        }
        { $_ -in @("IM", "Default") } {
            [System.Media.SystemSounds]::Beep.Play()
            return
        }
        default {
            [System.Media.SystemSounds]::Exclamation.Play()
            return
        }
    }
}

function Show-WindowsNotification {
    param(
        [string]$NotificationTitle,
        [string]$NotificationMessage,
        [string]$EventName
    )

    $notifyIcon = New-Object System.Windows.Forms.NotifyIcon
    $notifyIcon.Icon = [System.Drawing.SystemIcons]::Information
    $notifyIcon.BalloonTipIcon = Get-TooltipIcon -EventName $EventName
    $notifyIcon.BalloonTipTitle = $NotificationTitle
    $notifyIcon.BalloonTipText = $NotificationMessage
    $notifyIcon.Text = "Toast4OpenCode"
    $notifyIcon.Visible = $true
    $notifyIcon.ShowBalloonTip(3000)

    Start-Sleep -Milliseconds 3500
    $notifyIcon.Dispose()
}

if ([string]::IsNullOrWhiteSpace($ConfigPath)) {
    $ConfigPath = Get-DefaultConfigPath
}
else {
    $ConfigPath = [System.IO.Path]::GetFullPath($ConfigPath)
}

$config = Get-Config -Path $ConfigPath

$eventEnabled = Test-BoolSetting -Config $config -Name $Event
$soundEnabled = Test-BoolSetting -Config $config -Name "sound"
$taskbarFlashEnabled = Get-TaskbarFlashSetting -Config $config -EventName $Event

if (-not $eventEnabled) {
    Write-Output "toast4opencode: '$Event' notifications are disabled in $ConfigPath"
    exit 0
}

try {
    $defaults = Get-EventDefaults -Name $Event

    if ([string]::IsNullOrWhiteSpace($Title)) {
        $Title = $defaults.Title
    }

    if ([string]::IsNullOrWhiteSpace($Message)) {
        $Message = $defaults.Message
    }

    if ($PSBoundParameters.ContainsKey("Sound") -eq $false) {
        $Sound = $defaults.Sound
    }

    Play-NotificationSound -SoundName $Sound -SoundEnabled $soundEnabled -SilentRequested $Silent.IsPresent
    Show-WindowsNotification -NotificationTitle $Title -NotificationMessage $Message -EventName $Event

    if ($taskbarFlashEnabled) {
        [void](Invoke-TaskbarFlash)
    }

    Write-Output "toast4opencode: sent '$Event' notification"
}
catch {
    Write-ExitError "Failed to send Windows notification.`n$($_.Exception.Message)" 4
}
