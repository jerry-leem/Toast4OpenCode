# Toast4OpenCode

Windows toast notifications for OpenCode using [BurntToast](https://github.com/Windos/BurntToast). The project is built around one PowerShell script and thin launchers for PowerShell, `cmd.exe`, and WSL2.

## Features

- Completion, error, permission-request, input-needed, and sound alert notifications
- `setting.json` toggles for `complete`, `error`, `permission`, `input`, and `sound`
- Direct PowerShell execution plus wrappers for `cmd.exe` and WSL2
- Sample OpenCode hook configs for each shell style

## Repository Layout

```text
Toast4OpenCode/
|- scripts/toast4opencode.ps1
|- toast4opencode.cmd
|- toast4opencode
|- setting.json
`- examples/opencode/
```

## Requirements

- Windows 10 or later
- PowerShell 7+ (`pwsh`) recommended
- BurntToast PowerShell module
- For WSL2 usage, the repository should live on a Windows-accessible path such as `/mnt/c/...` so the wrapper can hand the script to Windows PowerShell cleanly

## Install

### 1. Clone the repository

```powershell
git clone https://github.com/jerry-leem/Toast4OpenCode.git
cd Toast4OpenCode
```

### 2. Install BurntToast from PowerShell

Run this once in Windows PowerShell or PowerShell 7:

```powershell
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
Install-Module BurntToast -Scope CurrentUser
```

Verify the module:

```powershell
Get-Module BurntToast -ListAvailable
```

### 3. Allow local script execution if needed

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

## `setting.json`

Default file:

```json
{
  "complete": true,
  "error": true,
  "permission": true,
  "input": true,
  "sound": true
}
```

Behavior:

- `complete`, `error`, `permission`, `input`: enable or disable that notification type
- `sound`: master switch for toast sound playback; when `false`, notifications are sent silently and the `sound` event is skipped

Example: disable completion toasts and all sounds

```json
{
  "complete": false,
  "error": true,
  "permission": true,
  "input": true,
  "sound": false
}
```

## Usage

### PowerShell

```powershell
pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\scripts\toast4opencode.ps1 complete
pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\scripts\toast4opencode.ps1 error "OpenCode error" "Build failed"
pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\scripts\toast4opencode.ps1 permission "Permission needed" "Approve filesystem access"
pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\scripts\toast4opencode.ps1 input "Input needed" "OpenCode is waiting for your answer"
pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\scripts\toast4opencode.ps1 sound "Attention" "Check the terminal" -Sound Alarm
```

Use a custom config file:

```powershell
pwsh -File .\scripts\toast4opencode.ps1 complete -ConfigPath .\setting.json
```

### `cmd.exe`

```bat
toast4opencode.cmd complete
toast4opencode.cmd error "OpenCode error" "The current task failed"
toast4opencode.cmd permission "Permission needed" "OpenCode requested elevated access"
toast4opencode.cmd input "Input needed" "Please answer the waiting prompt"
toast4opencode.cmd sound "Attention" "Check the terminal" -Sound Alarm
```

### WSL2

From a WSL2 shell inside the repository:

```bash
chmod +x ./toast4opencode
./toast4opencode complete
./toast4opencode error "OpenCode error" "The current task failed"
./toast4opencode permission "Permission needed" "OpenCode requested elevated access"
./toast4opencode input "Input needed" "Please answer the waiting prompt"
./toast4opencode sound "Attention" "Check the terminal" -Sound Alarm
```

## OpenCode Examples

Sample hook files:

- `examples/opencode/opencode.powershell.json`
- `examples/opencode/opencode.cmd.json`
- `examples/opencode/opencode.wsl.json`

Example PowerShell-oriented hook setup:

```json
{
  "hooks": {
    "onComplete": "pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\\scripts\\toast4opencode.ps1 complete",
    "onError": "pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\\scripts\\toast4opencode.ps1 error",
    "onPermissionRequest": "pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\\scripts\\toast4opencode.ps1 permission",
    "onInputRequired": "pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\\scripts\\toast4opencode.ps1 input"
  }
}
```

Example `cmd.exe`-oriented hook setup:

```json
{
  "hooks": {
    "onComplete": ".\\toast4opencode.cmd complete",
    "onError": ".\\toast4opencode.cmd error",
    "onPermissionRequest": ".\\toast4opencode.cmd permission",
    "onInputRequired": ".\\toast4opencode.cmd input"
  }
}
```

Example WSL2-oriented hook setup:

```json
{
  "hooks": {
    "onComplete": "./toast4opencode complete",
    "onError": "./toast4opencode error",
    "onPermissionRequest": "./toast4opencode permission",
    "onInputRequired": "./toast4opencode input"
  }
}
```

## Change Settings

Edit `setting.json` directly.

PowerShell example:

```powershell
$cfg = Get-Content .\setting.json -Raw | ConvertFrom-Json
$cfg.complete = $false
$cfg.sound = $false
$cfg | ConvertTo-Json | Set-Content .\setting.json
```

Python one-liner from `cmd.exe`:

```bat
python -c "import json, pathlib; p = pathlib.Path('setting.json'); d = json.loads(p.read_text()); d['error'] = False; p.write_text(json.dumps(d, indent=2))"
```

Python one-liner from WSL2:

```bash
python3 -c "import json, pathlib; p = pathlib.Path('setting.json'); d = json.loads(p.read_text()); d['input'] = False; p.write_text(json.dumps(d, indent=2) + '\n')"
```

## Troubleshooting

- If you see `BurntToast module is not installed`, install it from PowerShell and rerun the command.
- If WSL2 cannot start a notification, verify that `pwsh.exe` or `powershell.exe` is callable from WSL2 and that the repository path is reachable from Windows.
- If notifications appear without sound, confirm `sound` is `true` in `setting.json` and that you did not pass `-Silent`.
