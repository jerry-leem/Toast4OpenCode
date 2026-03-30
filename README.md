# Toast4OpenCode

Windows toast notifications for OpenCode using [BurntToast](https://github.com/Windos/BurntToast). The project is built around one PowerShell script and thin launchers for PowerShell, `cmd.exe`, and WSL2.

## 한국어 안내

`Toast4OpenCode`는 Windows에서 OpenCode 작업 상태를 토스트 알림으로 보여주는 도구입니다. 실제 알림 표시는 PowerShell용 BurntToast 모듈이 담당하고, 이 저장소는 같은 기능을 PowerShell, `cmd.exe`, WSL2에서 공통으로 호출할 수 있게 구성되어 있습니다.

지원 이벤트:

- 작업 완료 `complete`
- 오류 발생 `error`
- 권한 요청 `permission`
- 입력 필요 `input`
- 사운드 알림 `sound`

모든 이벤트는 루트의 [setting.json](./setting.json) 에서 켜고 끌 수 있습니다.

### 빠른 설치

1. 저장소를 클론합니다.

```powershell
git clone https://github.com/jerry-leem/Toast4OpenCode.git
cd Toast4OpenCode
```

2. PowerShell에서 BurntToast를 설치합니다.

```powershell
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
Install-Module BurntToast -Scope CurrentUser
```

3. 필요하면 스크립트 실행 정책을 완화합니다.

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

### 빠른 사용법

PowerShell:

```powershell
pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\scripts\toast4opencode.ps1 complete
pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\scripts\toast4opencode.ps1 error "OpenCode 오류" "현재 작업이 실패했습니다"
```

`cmd.exe`:

```bat
toast4opencode.cmd complete
toast4opencode.cmd permission "권한 필요" "파일 접근 권한을 승인해 주세요"
```

WSL2:

```bash
chmod +x ./toast4opencode
./toast4opencode input "입력 필요" "터미널에서 질문에 답변해 주세요"
./toast4opencode sound "알림" "터미널을 확인해 주세요" -Sound Alarm
```

### 설정 변경

기본 설정 파일은 다음과 같습니다.

```json
{
  "complete": true,
  "error": true,
  "permission": true,
  "input": true,
  "sound": true
}
```

예를 들어 완료 알림과 사운드를 끄고 싶다면 아래처럼 바꾸면 됩니다.

```json
{
  "complete": false,
  "error": true,
  "permission": true,
  "input": true,
  "sound": false
}
```

PowerShell에서 직접 수정하는 예시:

```powershell
$cfg = Get-Content .\setting.json -Raw | ConvertFrom-Json
$cfg.complete = $false
$cfg.sound = $false
$cfg | ConvertTo-Json | Set-Content .\setting.json
```

### OpenCode 연동

OpenCode 훅 예제는 아래 파일에 들어 있습니다.

- `examples/opencode/opencode.powershell.json`
- `examples/opencode/opencode.cmd.json`
- `examples/opencode/opencode.wsl.json`

PowerShell 기준 예시는 다음과 같습니다.

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

### 참고

- WSL2에서는 `pwsh.exe` 또는 `powershell.exe` 를 호출할 수 있어야 합니다.
- WSL2에서 저장소를 사용할 때는 `/mnt/c/...` 같은 Windows 접근 가능 경로에 두는 편이 안전합니다.
- `sound` 가 `false` 이면 일반 알림도 무음으로 전송되고 `sound` 이벤트도 사실상 비활성화됩니다.

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
