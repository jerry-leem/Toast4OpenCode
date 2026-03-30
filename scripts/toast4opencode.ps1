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

if ([string]::IsNullOrWhiteSpace($ConfigPath)) {
    $ConfigPath = Get-DefaultConfigPath
}
else {
    $ConfigPath = [System.IO.Path]::GetFullPath($ConfigPath)
}

$config = Get-Config -Path $ConfigPath

$eventEnabled = Test-BoolSetting -Config $config -Name $Event
$soundEnabled = Test-BoolSetting -Config $config -Name "sound"

if (-not $eventEnabled) {
    Write-Output "toast4opencode: '$Event' notifications are disabled in $ConfigPath"
    exit 0
}

try {
    Import-Module BurntToast -ErrorAction Stop
}
catch {
    Write-ExitError "BurntToast module is not installed. Run 'Install-Module BurntToast -Scope CurrentUser' in PowerShell first." 3
}

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

try {
    if ($Silent.IsPresent -or -not $soundEnabled) {
        New-BurntToastNotification -Text $Title, $Message -Silent | Out-Null
    }
    else {
        New-BurntToastNotification -Text $Title, $Message -Sound $Sound | Out-Null
    }
    Write-Output "toast4opencode: sent '$Event' notification"
}
catch {
    Write-ExitError "Failed to send BurntToast notification.`n$($_.Exception.Message)" 4
}
