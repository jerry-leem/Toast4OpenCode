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

설명:

- 이 단계는 항상 먼저 해야 하는 필수 단계는 아닙니다.
- PowerShell에서 `toast4opencode.ps1` 실행 시 스크립트 실행이 차단되거나, `running scripts is disabled on this system` 같은 메시지가 나올 때 적용하면 됩니다.
- `toast4opencode.cmd` 나 OpenCode 훅이 내부적으로 PowerShell 스크립트를 호출할 때도 같은 정책 제한에 걸릴 수 있습니다.
- 이미 회사 정책이나 개인 설정으로 PowerShell 스크립트 실행이 허용되어 있다면 이 단계는 건너뛰어도 됩니다.
- 예제에서는 `-Scope CurrentUser` 를 사용하므로 현재 로그인한 사용자에게만 적용되고, 시스템 전체 정책을 바꾸지는 않습니다.
- `RemoteSigned` 는 로컬에서 만든 스크립트는 실행할 수 있게 하고, 인터넷에서 내려받은 스크립트는 서명 여부를 더 엄격하게 보게 하는 비교적 무난한 설정입니다.

언제 적용하면 좋은가:

- 처음 설치 후 `pwsh -File ...\\toast4opencode.ps1 complete` 테스트에서 실행 정책 오류가 났을 때
- OpenCode CLI 훅은 등록했는데 실제 이벤트에서 알림이 전혀 뜨지 않고 PowerShell 실행 오류가 보일 때
- `cmd.exe` 나 WSL2에서 래퍼를 호출했는데 내부 PowerShell 스크립트 단계에서 막힐 때

언제 굳이 하지 않아도 되는가:

- `pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File ...` 방식으로 이미 정상 실행되고 있을 때
- 조직 보안 정책상 실행 정책을 변경하면 안 되는 환경일 때
- 이미 사용자 범위 또는 시스템 범위에서 적절한 정책이 설정되어 있을 때

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

Windows에서 OpenCode CLI를 설치해 쓰는 경우, 설정 파일은 보통 `C:\Users\<사용자이름>\.config\opencode\` 아래에 있습니다. 이 섹션은 그 기준으로 Toast4OpenCode를 연결하는 방법을 설명합니다.

OpenCode 훅 예제는 아래 파일에 들어 있습니다.

- `examples/opencode/opencode.powershell.json`
- `examples/opencode/opencode.cmd.json`
- `examples/opencode/opencode.wsl.json`

OpenCode CLI가 이미 설치되어 있다면, 실제 적용 순서는 아래처럼 진행하면 됩니다.

1. 먼저 Toast4OpenCode 저장소를 Windows에서 고정 경로에 둡니다.

- 예시: `C:\tools\Toast4OpenCode`
- OpenCode 설정 파일은 사용자 홈 아래에 있고, 알림 스크립트는 별도 저장소에 있으므로 상대경로보다 절대경로가 안전합니다.

2. OpenCode를 어느 셸에서 실행할지 먼저 정합니다.

- PowerShell에서 OpenCode를 실행한다면 `opencode.powershell.json`
- `cmd.exe`에서 OpenCode를 실행한다면 `opencode.cmd.json`
- WSL2에서 OpenCode를 실행한다면 `opencode.wsl.json`

3. `C:\Users\<사용자이름>\.config\opencode\` 아래에서 현재 OpenCode CLI가 읽는 설정 파일을 엽니다.

- 이미 OpenCode 설정이 있다면 `hooks` 항목만 추가하거나 병합하면 됩니다.
- 여러 설정 파일을 나눠 쓰고 있다면, 실제로 OpenCode CLI가 읽는 활성 설정 파일에 넣어야 합니다.
- 파일 이름이 무엇이든 핵심은 `hooks` 항목에 Toast4OpenCode 명령을 추가하는 것입니다.

4. OpenCode 설정 파일 안의 훅 명령은 절대경로로 넣습니다.

- OpenCode는 다양한 작업 디렉토리에서 실행될 수 있으므로 `.\scripts\...` 같은 상대경로보다 `C:\\tools\\Toast4OpenCode\\...` 같은 절대경로가 더 안정적입니다.
- 특히 OpenCode 설정 파일이 `C:\Users\<사용자이름>\.config\opencode\` 아래에 있어도, 실제 작업 디렉토리는 프로젝트마다 달라질 수 있습니다.

5. OpenCode를 붙이기 전에 Toast4OpenCode를 단독으로 먼저 테스트합니다.

- PowerShell:

```powershell
pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File C:\tools\Toast4OpenCode\scripts\toast4opencode.ps1 complete
pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File C:\tools\Toast4OpenCode\scripts\toast4opencode.ps1 error "OpenCode 오류" "테스트 알림"
```

- `cmd.exe`:

```bat
C:\tools\Toast4OpenCode\toast4opencode.cmd complete
C:\tools\Toast4OpenCode\toast4opencode.cmd error "OpenCode 오류" "테스트 알림"
```

- WSL2:

```bash
/mnt/c/tools/Toast4OpenCode/toast4opencode complete
/mnt/c/tools/Toast4OpenCode/toast4opencode error "OpenCode 오류" "테스트 알림"
```

6. 단독 테스트가 정상이라면 OpenCode 설정 파일의 `hooks` 에 명령을 넣습니다.

PowerShell에서 OpenCode를 실행할 때 가장 안전한 예시는 다음과 같습니다.

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

`cmd.exe` 에서 OpenCode를 실행한다면 다음 형태로 넣으면 됩니다.

```json
{
  "hooks": {
    "onComplete": "C:\\\\tools\\\\Toast4OpenCode\\\\toast4opencode.cmd complete",
    "onError": "C:\\\\tools\\\\Toast4OpenCode\\\\toast4opencode.cmd error",
    "onPermissionRequest": "C:\\\\tools\\\\Toast4OpenCode\\\\toast4opencode.cmd permission",
    "onInputRequired": "C:\\\\tools\\\\Toast4OpenCode\\\\toast4opencode.cmd input"
  }
}
```

WSL2에서 OpenCode를 실행한다면 다음 형태가 맞습니다.

```json
{
  "hooks": {
    "onComplete": "/mnt/c/tools/Toast4OpenCode/toast4opencode complete",
    "onError": "/mnt/c/tools/Toast4OpenCode/toast4opencode error",
    "onPermissionRequest": "/mnt/c/tools/Toast4OpenCode/toast4opencode permission",
    "onInputRequired": "/mnt/c/tools/Toast4OpenCode/toast4opencode input"
  }
}
```

7. OpenCode를 실행해서 실제 이벤트가 발생할 때 훅이 호출되는지 확인합니다.

- 짧은 작업을 하나 실행해서 완료 알림이 오는지 확인합니다.
- 일부러 실패하는 명령이나 잘못된 입력을 줘서 `error` 또는 `input` 이벤트를 확인합니다.
- 권한 승인이 필요한 작업을 유도해서 `permission` 이벤트를 확인합니다.

8. 너무 자주 울리거나 특정 알림이 필요 없으면 `C:\tools\Toast4OpenCode\setting.json` 에서 끕니다.

- 예를 들어 완료 알림만 끄고 싶으면 `"complete": false`
- 모든 소리를 끄고 배너만 유지하고 싶으면 `"sound": false`

실사용 팁:

- Windows OpenCode CLI 설정 경로와 Toast4OpenCode 저장소 경로는 서로 다릅니다. 설정은 `C:\Users\<사용자이름>\.config\opencode\`, 실제 알림 스크립트는 `C:\tools\Toast4OpenCode` 같은 별도 위치에 둔다고 생각하면 됩니다.
- OpenCode를 항상 같은 위치에서 실행하지 않는다면 훅 명령에 절대경로를 쓰는 편이 더 안정적입니다.
- WSL2에서는 저장소를 `/mnt/c/...` 아래에 두면 Windows 쪽 PowerShell이 스크립트를 찾기 쉽습니다.
- OpenCode가 백그라운드 작업을 자주 만들면 `complete` 는 끄고 `error`, `permission`, `input` 만 남기는 구성이 더 실용적일 수 있습니다.

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
