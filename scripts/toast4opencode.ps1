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
$script:ToastAppId = "JerryLeem.Toast4OpenCode"

if (-not ("Toast4OpenCode.Win32" -as [type])) {
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices.ComTypes;
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

    [ComImport, Guid("00021401-0000-0000-C000-000000000046")]
    public class CShellLink
    {
    }

    [ComImport, InterfaceType(ComInterfaceType.InterfaceIsIUnknown), Guid("000214F9-0000-0000-C000-000000000046")]
    public interface IShellLinkW
    {
        void GetPath([Out, MarshalAs(UnmanagedType.LPWStr)] System.Text.StringBuilder pszFile, int cchMaxPath, IntPtr pfd, uint fFlags);
        void GetIDList(out IntPtr ppidl);
        void SetIDList(IntPtr pidl);
        void GetDescription([Out, MarshalAs(UnmanagedType.LPWStr)] System.Text.StringBuilder pszName, int cchMaxName);
        void SetDescription([MarshalAs(UnmanagedType.LPWStr)] string pszName);
        void GetWorkingDirectory([Out, MarshalAs(UnmanagedType.LPWStr)] System.Text.StringBuilder pszDir, int cchMaxPath);
        void SetWorkingDirectory([MarshalAs(UnmanagedType.LPWStr)] string pszDir);
        void GetArguments([Out, MarshalAs(UnmanagedType.LPWStr)] System.Text.StringBuilder pszArgs, int cchMaxPath);
        void SetArguments([MarshalAs(UnmanagedType.LPWStr)] string pszArgs);
        void GetHotkey(out short pwHotkey);
        void SetHotkey(short wHotkey);
        void GetShowCmd(out int piShowCmd);
        void SetShowCmd(int iShowCmd);
        void GetIconLocation([Out, MarshalAs(UnmanagedType.LPWStr)] System.Text.StringBuilder pszIconPath, int cchIconPath, out int piIcon);
        void SetIconLocation([MarshalAs(UnmanagedType.LPWStr)] string pszIconPath, int iIcon);
        void SetRelativePath([MarshalAs(UnmanagedType.LPWStr)] string pszPathRel, uint dwReserved);
        void Resolve(IntPtr hwnd, uint fFlags);
        void SetPath([MarshalAs(UnmanagedType.LPWStr)] string pszFile);
    }

    [ComImport, InterfaceType(ComInterfaceType.InterfaceIsIUnknown), Guid("886D8EEB-8CF2-4446-8D02-CDBA1DBDCF99")]
    public interface IPropertyStore
    {
        uint GetCount(out uint cProps);
        uint GetAt(uint iProp, out PROPERTYKEY pkey);
        uint GetValue(ref PROPERTYKEY key, out PROPVARIANT pv);
        uint SetValue(ref PROPERTYKEY key, ref PROPVARIANT pv);
        uint Commit();
    }

    [StructLayout(LayoutKind.Sequential, Pack = 4)]
    public struct PROPERTYKEY
    {
        public Guid fmtid;
        public uint pid;

        public PROPERTYKEY(Guid formatId, uint propertyId)
        {
            fmtid = formatId;
            pid = propertyId;
        }
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct PROPVARIANT
    {
        public ushort vt;
        public ushort wReserved1;
        public ushort wReserved2;
        public ushort wReserved3;
        public IntPtr p;
        public int p2;
    }

    public static class ShortcutHelper
    {
        private static readonly PROPERTYKEY AppIdKey = new PROPERTYKEY(new Guid("9F4C2855-9F79-4B39-A8D0-E1D42DE1D5F3"), 5);

        [DllImport("ole32.dll", PreserveSig = false)]
        private static extern void PropVariantClear(ref PROPVARIANT pvar);

        public static void CreateShortcut(string shortcutPath, string targetPath, string arguments, string workingDirectory, string description, string appId, string iconPath)
        {
            var shellLink = (IShellLinkW)new CShellLink();
            shellLink.SetPath(targetPath);
            shellLink.SetArguments(arguments);
            shellLink.SetWorkingDirectory(workingDirectory);
            shellLink.SetDescription(description);
            shellLink.SetIconLocation(iconPath, 0);

            var propertyStore = (IPropertyStore)shellLink;
            var appIdVariant = new PROPVARIANT();
            appIdVariant.vt = 31;
            appIdVariant.p = Marshal.StringToCoTaskMemUni(appId);

            try
            {
                propertyStore.SetValue(ref AppIdKey, ref appIdVariant);
                propertyStore.Commit();
                ((IPersistFile)shellLink).Save(shortcutPath, true);
            }
            finally
            {
                PropVariantClear(ref appIdVariant);
            }
        }
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

function Get-SoundUri {
    param(
        [string]$SoundName,
        [bool]$SoundEnabled,
        [bool]$SilentRequested
    )

    if ($SilentRequested -or -not $SoundEnabled) {
        return $null
    }

    switch ($SoundName) {
        "Default" { return "ms-winsoundevent:Notification.Default" }
        "IM" { return "ms-winsoundevent:Notification.IM" }
        "Mail" { return "ms-winsoundevent:Notification.Mail" }
        "Reminder" { return "ms-winsoundevent:Notification.Reminder" }
        "SMS" { return "ms-winsoundevent:Notification.SMS" }
        "Alarm" { return "ms-winsoundevent:Notification.Looping.Alarm" }
        "Alarm2" { return "ms-winsoundevent:Notification.Looping.Alarm2" }
        "Alarm3" { return "ms-winsoundevent:Notification.Looping.Alarm3" }
        "Alarm4" { return "ms-winsoundevent:Notification.Looping.Alarm4" }
        "Alarm5" { return "ms-winsoundevent:Notification.Looping.Alarm5" }
        "Alarm6" { return "ms-winsoundevent:Notification.Looping.Alarm6" }
        "Alarm7" { return "ms-winsoundevent:Notification.Looping.Alarm7" }
        "Alarm8" { return "ms-winsoundevent:Notification.Looping.Alarm8" }
        "Alarm9" { return "ms-winsoundevent:Notification.Looping.Alarm9" }
        "Alarm10" { return "ms-winsoundevent:Notification.Looping.Alarm10" }
        "Call" { return "ms-winsoundevent:Notification.Looping.Call" }
        "Call2" { return "ms-winsoundevent:Notification.Looping.Call2" }
        "Call3" { return "ms-winsoundevent:Notification.Looping.Call3" }
        "Call4" { return "ms-winsoundevent:Notification.Looping.Call4" }
        "Call5" { return "ms-winsoundevent:Notification.Looping.Call5" }
        "Call6" { return "ms-winsoundevent:Notification.Looping.Call6" }
        "Call7" { return "ms-winsoundevent:Notification.Looping.Call7" }
        "Call8" { return "ms-winsoundevent:Notification.Looping.Call8" }
        "Call9" { return "ms-winsoundevent:Notification.Looping.Call9" }
        "Call10" { return "ms-winsoundevent:Notification.Looping.Call10" }
        default { return "ms-winsoundevent:Notification.Default" }
    }
}

function Ensure-ToastShortcut {
    $repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
    $shortcutDirectory = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs"
    $shortcutPath = Join-Path $shortcutDirectory "Toast4OpenCode.lnk"
    $targetPath = Join-Path $repoRoot "toast4opencode.cmd"

    if (-not (Test-Path -LiteralPath $shortcutDirectory)) {
        New-Item -ItemType Directory -Path $shortcutDirectory -Force | Out-Null
    }

    [Toast4OpenCode.ShortcutHelper]::CreateShortcut(
        $shortcutPath,
        $targetPath,
        "",
        $repoRoot,
        "Toast4OpenCode Windows notifications",
        $script:ToastAppId,
        $targetPath
    )
}

function Show-WindowsToast {
    param(
        [string]$NotificationTitle,
        [string]$NotificationMessage,
        [string]$EventName,
        [string]$SoundName,
        [bool]$SoundEnabled,
        [bool]$SilentRequested
    )

    [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] > $null
    [Windows.UI.Notifications.ToastNotification, Windows.UI.Notifications, ContentType = WindowsRuntime] > $null
    [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] > $null

    Ensure-ToastShortcut

    $escapedTitle = [System.Security.SecurityElement]::Escape($NotificationTitle)
    $escapedMessage = [System.Security.SecurityElement]::Escape($NotificationMessage)
    $soundUri = Get-SoundUri -SoundName $SoundName -SoundEnabled $SoundEnabled -SilentRequested $SilentRequested

    if ($null -eq $soundUri) {
        $audioNode = '<audio silent="true"/>'
    }
    else {
        $audioNode = '<audio src="' + $soundUri + '"/>'
    }

    $toastXmlString = @"
<toast>
  <visual>
    <binding template="ToastGeneric">
      <text>$escapedTitle</text>
      <text>$escapedMessage</text>
    </binding>
  </visual>
  $audioNode
</toast>
"@

    $toastXml = [Windows.Data.Xml.Dom.XmlDocument]::new()
    $toastXml.LoadXml($toastXmlString)

    $toast = [Windows.UI.Notifications.ToastNotification]::new($toastXml)
    $notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($script:ToastAppId)
    $notifier.Show($toast)
}

function Show-LegacyNotification {
    param(
        [string]$NotificationTitle,
        [string]$NotificationMessage
    )

    try {
        [void][reflection.assembly]::LoadWithPartialName("System.Windows.Forms")
        [void][reflection.assembly]::LoadWithPartialName("System.Drawing")

        $notifyIcon = New-Object System.Windows.Forms.NotifyIcon
        $notifyIcon.Icon = [System.Drawing.SystemIcons]::Information
        $notifyIcon.BalloonTipTitle = $NotificationTitle
        $notifyIcon.BalloonTipText = $NotificationMessage
        $notifyIcon.Text = "Toast4OpenCode"
        $notifyIcon.Visible = $true
        $notifyIcon.ShowBalloonTip(3000)
        Start-Sleep -Milliseconds 3500
        $notifyIcon.Dispose()
    }
    catch {
        throw
    }
}

function Send-WindowsNotification {
    param(
        [string]$NotificationTitle,
        [string]$NotificationMessage,
        [string]$EventName,
        [string]$SoundName,
        [bool]$SoundEnabled,
        [bool]$SilentRequested
    )

    try {
        Show-WindowsToast -NotificationTitle $NotificationTitle -NotificationMessage $NotificationMessage -EventName $EventName -SoundName $SoundName -SoundEnabled $SoundEnabled -SilentRequested $SilentRequested
    }
    catch {
        Show-LegacyNotification -NotificationTitle $NotificationTitle -NotificationMessage $NotificationMessage
        if (-not $SilentRequested -and $SoundEnabled) {
            [System.Media.SystemSounds]::Beep.Play()
        }
    }
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

    Send-WindowsNotification -NotificationTitle $Title -NotificationMessage $Message -EventName $Event -SoundName $Sound -SoundEnabled $soundEnabled -SilentRequested $Silent.IsPresent

    if ($taskbarFlashEnabled) {
        [void](Invoke-TaskbarFlash)
    }

    Write-Output "toast4opencode: sent '$Event' notification"
}
catch {
    Write-ExitError "Failed to send Windows notification.`n$($_.Exception.Message)" 4
}
