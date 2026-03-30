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

OpenCode CLI가 이미 설치되어 있다면, 실제 연동 순서는 아래처럼 진행하면 됩니다.

1. OpenCode를 어느 셸에서 실행할지 먼저 정합니다.

- PowerShell에서 OpenCode를 실행한다면 `opencode.powershell.json`
- `cmd.exe`에서 OpenCode를 실행한다면 `opencode.cmd.json`
- WSL2에서 OpenCode를 실행한다면 `opencode.wsl.json`

2. 선택한 예제 파일의 `hooks` 내용을 현재 사용하는 OpenCode 설정 파일에 반영합니다.

- 이미 OpenCode 설정 파일이 있다면 `hooks` 항목만 병합하면 됩니다.
- 아직 별도 설정이 없다면 예제 파일을 기반으로 시작해도 됩니다.

3. OpenCode가 실행되는 현재 작업 디렉토리 기준으로 경로가 맞는지 확인합니다.

- 예제에 들어 있는 경로는 `Toast4OpenCode` 저장소 루트에서 OpenCode를 실행한다고 가정한 상대경로입니다.
- OpenCode를 다른 디렉토리에서 실행한다면 상대경로 대신 절대경로로 바꾸는 것이 안전합니다.
- 예를 들어 PowerShell에서는 `C:\\tools\\Toast4OpenCode\\scripts\\toast4opencode.ps1` 같은 절대경로를 쓸 수 있습니다.

4. OpenCode를 붙이기 전에 알림 스크립트를 단독으로 먼저 테스트합니다.

- PowerShell:

```powershell
pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\scripts\toast4opencode.ps1 complete
pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\scripts\toast4opencode.ps1 error "OpenCode 오류" "테스트 알림"
```

- `cmd.exe`:

```bat
toast4opencode.cmd complete
toast4opencode.cmd error "OpenCode 오류" "테스트 알림"
```

- WSL2:

```bash
./toast4opencode complete
./toast4opencode error "OpenCode 오류" "테스트 알림"
```

5. 단독 테스트가 정상이라면 OpenCode를 실행해서 실제 이벤트가 발생할 때 훅이 호출되는지 확인합니다.

- 짧은 작업을 하나 실행해서 완료 알림이 오는지 확인합니다.
- 일부러 실패하는 명령이나 잘못된 입력을 줘서 `error` 또는 `input` 이벤트를 확인합니다.
- 권한 승인이 필요한 작업을 유도해서 `permission` 이벤트를 확인합니다.

6. 너무 자주 울리거나 특정 알림이 필요 없으면 `setting.json` 에서 끕니다.

- 예를 들어 완료 알림만 끄고 싶으면 `"complete": false`
- 모든 소리를 끄고 배너만 유지하고 싶으면 `"sound": false`

실사용 팁:

- OpenCode를 항상 같은 위치에서 실행하지 않는다면 훅 명령에 절대경로를 쓰는 편이 더 안정적입니다.
- WSL2에서는 저장소를 `/mnt/c/...` 아래에 두면 Windows 쪽 PowerShell이 스크립트를 찾기 쉽습니다.
- OpenCode가 백그라운드 작업을 자주 만들면 `complete` 는 끄고 `error`, `permission`, `input` 만 남기는 구성이 더 실용적일 수 있습니다.

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

절대경로 예시는 다음과 같습니다.

```json
{
  "hooks": {
    "onComplete": "pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File C:\\\\tools\\\\Toast4OpenCode\\\\scripts\\\\toast4opencode.ps1 complete",
    "onError": "pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File C:\\\\tools\\\\Toast4OpenCode\\\\scripts\\\\toast4opencode.ps1 error",
    "onPermissionRequest": "pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File C:\\\\tools\\\\Toast4OpenCode\\\\scripts\\\\toast4opencode.ps1 permission",
    "onInputRequired": "pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File C:\\\\tools\\\\Toast4OpenCode\\\\scripts\\\\toast4opencode.ps1 input"
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
