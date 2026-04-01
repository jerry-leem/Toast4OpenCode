# Toast4OpenCode

Windows notifications for OpenCode using built-in PowerShell, .NET, and Win32 APIs. The project is built around one PowerShell script and thin launchers for PowerShell, `cmd.exe`, and WSL2.

## Language Guide

- Korean guide: [한국어 안내](#korean-guide--한국어-안내)
- English guide: [English Guide](#english-guide)

## Korean Guide / 한국어 안내

`Toast4OpenCode`는 Windows에서 OpenCode 작업 상태를 알림으로 보여주는 도구입니다. 외부 PowerShell 모듈 없이 Windows 기본 PowerShell, .NET, Win32 기능만 사용하므로, 저장소를 클론한 뒤 바로 쓸 수 있도록 구성되어 있습니다.

지원 이벤트:

- 작업 완료 `complete`
- 오류 발생 `error`
- 권한 요청 `permission`
- 입력 필요 `input`
- 사운드 알림 `sound`
- 작업표시줄 깜빡임 `taskbarFlash`
  - 완료별 `taskbarFlash.complete`
  - 오류별 `taskbarFlash.error`
  - 권한요청별 `taskbarFlash.permission`
  - 입력필요별 `taskbarFlash.input`
  - 사운드알림별 `taskbarFlash.sound`

모든 이벤트는 루트의 [setting.json](./setting.json) 에서 켜고 끌 수 있습니다.

### 빠른 설치

1. 저장소를 클론합니다.

```powershell
git clone https://github.com/jerry-leem/Toast4OpenCode.git
cd Toast4OpenCode
```

2. 추가 모듈 설치는 필요하지 않습니다.

- `BurntToast` 같은 외부 PowerShell 모듈을 받지 않습니다.
- 회사 내 폐쇄망처럼 외부 다운로드가 막힌 환경도, 기본 Windows PowerShell/.NET 구성만 있으면 그대로 사용할 수 있습니다.
- 첫 실행 시 사용자 Start Menu 아래에 `Toast4OpenCode` 바로가기를 자동 생성해서 Windows 10/11 실제 토스트 API를 사용할 수 있게 준비합니다.

3. 필요하면 스크립트 실행 정책을 완화합니다.

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

설명:

- 이 단계는 항상 먼저 해야 하는 필수 단계는 아닙니다.
- PowerShell에서 `toast4opencode.ps1` 실행 시 스크립트 실행이 차단되거나, `running scripts is disabled on this system` 같은 메시지가 나올 때 적용하면 됩니다.
- `toast4opencode.cmd` 나 OpenCode 플러그인이 내부적으로 PowerShell 스크립트를 호출할 때도 같은 정책 제한에 걸릴 수 있습니다.
- 이미 회사 정책이나 개인 설정으로 PowerShell 스크립트 실행이 허용되어 있다면 이 단계는 건너뛰어도 됩니다.
- 예제에서는 `-Scope CurrentUser` 를 사용하므로 현재 로그인한 사용자에게만 적용되고, 시스템 전체 정책을 바꾸지는 않습니다.
- `RemoteSigned` 는 로컬에서 만든 스크립트는 실행할 수 있게 하고, 인터넷에서 내려받은 스크립트는 서명 여부를 더 엄격하게 보게 하는 비교적 무난한 설정입니다.

언제 적용하면 좋은가:

- 처음 설치 후 `pwsh -File ...\\toast4opencode.ps1 complete` 테스트에서 실행 정책 오류가 났을 때
- OpenCode CLI 플러그인은 등록했는데 실제 이벤트에서 알림이 전혀 뜨지 않고 PowerShell 실행 오류가 보일 때
- `cmd.exe` 나 WSL2에서 래퍼를 호출했는데 내부 PowerShell 스크립트 단계에서 막힐 때

언제 굳이 하지 않아도 되는가:

- `pwsh` 또는 `powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File ...` 방식으로 이미 정상 실행되고 있을 때
- 조직 보안 정책상 실행 정책을 변경하면 안 되는 환경일 때
- 이미 사용자 범위 또는 시스템 범위에서 적절한 정책이 설정되어 있을 때

### 빠른 사용법

PowerShell:

```powershell
pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\scripts\toast4opencode.ps1 complete
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\scripts\toast4opencode.ps1 error "OpenCode 오류" "현재 작업이 실패했습니다"
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
  "sound": true,
  "taskbarFlash": {
    "complete": true,
    "error": true,
    "permission": true,
    "input": true,
    "sound": true
  }
}
```

예를 들어 완료 알림과 사운드를 끄고 싶다면 아래처럼 바꾸면 됩니다.

```json
{
  "complete": false,
  "error": true,
  "permission": true,
  "input": true,
  "sound": false,
  "taskbarFlash": {
    "complete": false,
    "error": true,
    "permission": true,
    "input": false,
    "sound": false
  }
}
```

PowerShell에서 직접 수정하는 예시:

```powershell
$cfg = Get-Content .\setting.json -Raw | ConvertFrom-Json
$cfg.complete = $false
$cfg.sound = $false
$cfg.taskbarFlash.complete = $false
$cfg.taskbarFlash.input = $false
$cfg.taskbarFlash.sound = $false
$cfg | ConvertTo-Json | Set-Content .\setting.json
```

## OpenCode 연동

Windows에서 OpenCode CLI를 설치해 쓰는 경우, 플러그인 파일은 보통 `C:\Users\<사용자이름>\.config\opencode\plugins` 아래에 있습니다. 이 섹션은 그 기준으로 Toast4OpenCode를 연결하는 방법을 설명합니다.

OpenCode 플러그인 예제는 아래 파일에 들어 있습니다.

- `examples/plugins/toast4opencode_win.js`
- `examples/plugins/toast4opencode_wsl.js`

OpenCode CLI가 이미 설치되어 있다면, 실제 적용 순서는 아래처럼 진행하면 됩니다.

1. 먼저 Toast4OpenCode 저장소를 Windows에서 절대 경로에 둡니다.

- 예시: `C:\tools\Toast4OpenCode`
- OpenCode 설정 파일은 사용자 홈 아래에 있고, 알림 스크립트는 별도 저장소에 있으므로 상대경로보다 절대경로가 안전합니다.

2. OpenCode를 어느 셸에서 실행할지 먼저 정합니다.

- PowerShell, `cmd.exe` 에서 OpenCode를 실행한다면 `toast4opencode_win.js` 파일을 `C:\Users\<사용자이름>\.config\opencode\plugins` 에 저장
- WSL2에서 OpenCode를 실행한다면 `toast4opencode_wsl.js` 파일을 `/home/USERNAME/.config/opencode/plugins` 에 저장

3. `toast4opencode_wsl.js`이나 `toast4opencode_win.js` 파일 내용 중 설치된 절대 경로를 바꿔서 저장합니다.

- OpenCode는 다양한 작업 디렉토리에서 실행될 수 있으므로 `.\scripts\...` 같은 상대경로보다 `C:\\tools\\Toast4OpenCode\\...` 같은 절대경로가 더 안정적입니다.
- 특히 OpenCode 설정 파일이 `C:\Users\<사용자이름>\.config\opencode\` 아래에 있어도, 실제 작업 디렉토리는 프로젝트마다 달라질 수 있습니다.

- WSL
```bash
...
import { execFile } from "child_process"
 
const TOAST_CMD = "/mnt/d/UTIL/Toast4OpenCode/toast4opencode"
 
const EVENT_MAP = {
  "session.idle":     "complete",
  "session.error":    "error",
  "permission.asked": "permission",
  "question":         "input",
}
...
```

- Windows (Powershell, cmd)
```powershell
...
import { execFile } from "child_process"
 
const TOAST_CMD = "D:\\UTIL\\Toast4OpenCode\\toast4opencode.cmd"
 
const EVENT_MAP = {
  "session.idle":     "complete",
  "session.error":    "error",
  "permission.asked": "permission",
  "question":         "input",
}
...
```

4. OpenCode를 붙이기 전에 Toast4OpenCode를 단독으로 먼저 테스트합니다.

- PowerShell:

```powershell
pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File C:\tools\Toast4OpenCode\scripts\toast4opencode.ps1 complete
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File C:\tools\Toast4OpenCode\scripts\toast4opencode.ps1 error "OpenCode 오류" "테스트 알림"
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

5. OpenCode를 실행해서 실제 이벤트가 발생할 때 알림이 오는지 확인합니다.

- 짧은 작업을 하나 실행해서 완료 알림이 오는지 확인합니다.
- 일부러 실패하는 명령이나 잘못된 입력을 줘서 `error` 또는 `input` 이벤트를 확인합니다.
- 권한 승인이 필요한 작업을 유도해서 `permission` 이벤트를 확인합니다.

6. 너무 자주 울리거나 특정 알림이 필요 없으면 `C:\tools\Toast4OpenCode\setting.json` 에서 끕니다.

- 예를 들어 완료 알림만 끄고 싶으면 `"complete": false`
- 모든 소리를 끄고 배너만 유지하고 싶으면 `"sound": false`
- 완료 시 작업표시줄 깜빡임만 끄고 싶으면 `taskbarFlash.complete` 를 `false` 로 둡니다
- 오류만 작업표시줄을 깜빡이게 하고 싶으면 `taskbarFlash.error` 만 `true` 로 두면 됩니다

실사용 팁:

- Windows OpenCode CLI 설정 경로와 Toast4OpenCode 저장소 경로는 서로 다릅니다. 설정은 `C:\Users\<사용자이름>\.config\opencode\`, 실제 알림 스크립트는 `C:\tools\Toast4OpenCode` 같은 별도 위치에 둔다고 생각하면 됩니다.
- OpenCode를 항상 같은 위치에서 실행하지 않는다면 플러그인 명령에 절대경로를 쓰는 편이 더 안정적입니다.
- WSL2에서는 저장소를 `/mnt/c/...` 아래에 두면 Windows 쪽 PowerShell이 스크립트를 찾기 쉽습니다.
- OpenCode가 백그라운드 작업을 자주 만들면 `complete` 는 끄고 `error`, `permission`, `input` 만 남기는 구성이 더 실용적일 수 있습니다.

### 참고

- WSL2에서는 `pwsh.exe` 또는 `powershell.exe` 를 호출할 수 있어야 합니다.
- WSL2에서 저장소를 사용할 때는 `/mnt/c/...` 같은 Windows 접근 가능 경로에 두는 편이 안전합니다.
- `sound` 가 `false` 이면 일반 알림도 무음으로 전송되고 `sound` 이벤트도 사실상 비활성화됩니다.
- `taskbarFlash` 는 이벤트별 객체입니다. 예를 들어 `taskbarFlash.error` 만 `true` 로 두면 오류 때만 작업표시줄 깜빡임을 요청합니다.
- 이전 단일 불리언 형식인 `"taskbarFlash": true` 도 호환 차원에서 계속 읽습니다.
- 작업표시줄 깜빡임은 현재 포그라운드 창(예: Windows Terminal)을 먼저 대상으로 시도하고, 없으면 콘솔 창 핸들로 폴백합니다. 둘 다 없으면 경고 메시지를 출력하고 건너뜁니다. 깜빡임 결과는 출력 메시지에 `(taskbar flash applied)` 또는 `(taskbar flash unavailable)` 로 구분됩니다.
- WSL2에서 이벤트가 빠르게 연속 발생해도 알림이 순서대로 전달됩니다. 플러그인 내부에서 직렬화 큐를 사용하므로 한꺼번에 몰려서 오는 현상이 발생하지 않습니다.
- 이 프로젝트는 외부 다운로드 없이 동작하도록 되어 있지만, Windows 자체에서 `System.Windows.Forms` 와 `System.Drawing` 을 사용할 수 있는 기본 .NET Desktop 구성은 필요합니다.
- 기본 경로에서는 Windows 토스트 API를 사용하고, 매우 제한적인 환경에서만 레거시 풍선 알림으로 폴백합니다.

---

## English Guide

## Features

- Completion, error, permission-request, input-needed, and sound alert notifications
- Optional taskbar flashing via Win32 `FlashWindowEx`
- `setting.json` toggles for `complete`, `error`, `permission`, `input`, and `sound`
- Per-event `taskbarFlash.complete`, `taskbarFlash.error`, `taskbarFlash.permission`, `taskbarFlash.input`, and `taskbarFlash.sound`
- Direct PowerShell execution plus wrappers for `cmd.exe` and WSL2
- No external PowerShell module download required
- Automatically registers a per-user Start Menu shortcut so unpackaged Windows toast notifications work
- Sample OpenCode plugin configs for each shell style

## Repository Layout

```text
Toast4OpenCode/
|- scripts/toast4opencode.ps1
|- toast4opencode.cmd
|- toast4opencode
|- setting.json
`- examples/plugins/
```

## Requirements

- Windows 10 or later
- PowerShell 7+ (`pwsh`) recommended
- Built-in Windows PowerShell/.NET support for `System.Windows.Forms`, `System.Drawing`, and Win32 interop
- For WSL2 usage, the repository should live on a Windows-accessible path such as `/mnt/c/...` so the wrapper can hand the script to Windows PowerShell cleanly

## Install

### 1. Clone the repository

```powershell
git clone https://github.com/jerry-leem/Toast4OpenCode.git
cd Toast4OpenCode
```

### 2. No external module installation is required

- This project no longer depends on `BurntToast`.
- It uses built-in Windows PowerShell, .NET, and Win32 APIs, so `git clone` is enough even in closed-network environments where external downloads are blocked.
- If your Windows image already includes the standard .NET Desktop components, no additional package fetch is required.
- On first execution, the script creates a per-user Start Menu shortcut with an AppUserModelID so native Windows 10/11 toast notifications can be shown from an unpackaged script.

### 3. Allow local script execution if needed

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

Notes:

- This step is not always required.
- Apply it when PowerShell blocks `toast4opencode.ps1` and you see messages such as `running scripts is disabled on this system`.
- The same policy restriction can also affect `toast4opencode.cmd` and OpenCode plugins because they eventually invoke a PowerShell script.
- If PowerShell scripts already run correctly in your environment, you can skip this step.
- The example uses `-Scope CurrentUser`, so it affects only the current Windows user and does not change the machine-wide policy.
- `RemoteSigned` is a practical default: locally created scripts can run, while downloaded scripts are treated more strictly.

When you should do this:

- Your first `pwsh -File ...\toast4opencode.ps1 complete` test fails with an execution-policy error
- OpenCode plugins are configured, but notifications never appear because the underlying PowerShell script is blocked
- `cmd.exe` or WSL2 wrappers launch, but fail when the PowerShell stage starts

When you may not need it:

- `pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File ...` already works in your environment
- Your organization manages PowerShell execution policy and you should not override it
- A suitable user or system policy is already configured

## `setting.json`

Default file:

```json
{
  "complete": true,
  "error": true,
  "permission": true,
  "input": true,
  "sound": true,
  "taskbarFlash": {
    "complete": true,
    "error": true,
    "permission": true,
    "input": true,
    "sound": true
  }
}
```

Behavior:

- `complete`, `error`, `permission`, `input`: enable or disable that notification type
- `sound`: master switch for toast sound playback; when `false`, notifications are sent silently and the `sound` event is skipped
- `taskbarFlash.complete`, `taskbarFlash.error`, `taskbarFlash.permission`, `taskbarFlash.input`, `taskbarFlash.sound`: request a taskbar or console-window flash for that specific event
- For backward compatibility, the older boolean form `"taskbarFlash": true` or `"taskbarFlash": false` is still accepted

Example: disable completion toasts and all sounds

```json
{
  "complete": false,
  "error": true,
  "permission": true,
  "input": true,
  "sound": false,
  "taskbarFlash": {
    "complete": false,
    "error": true,
    "permission": true,
    "input": false,
    "sound": false
  }
}
```

## Usage

### PowerShell

```powershell
pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\scripts\toast4opencode.ps1 complete
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\scripts\toast4opencode.ps1 error "OpenCode error" "Build failed"
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\scripts\toast4opencode.ps1 permission "Permission needed" "Approve filesystem access"
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\scripts\toast4opencode.ps1 input "Input needed" "OpenCode is waiting for your answer"
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\scripts\toast4opencode.ps1 sound "Attention" "Check the terminal" -Sound Alarm
```

Use a custom config file:

```powershell
powershell -File .\scripts\toast4opencode.ps1 complete -ConfigPath .\setting.json
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

For a typical Windows OpenCode CLI setup, the plugin files usually live under `C:\Users\<your-user>\.config\opencode\pulgins`. This section explains how to wire Toast4OpenCode into that layout.

Sample plugin files:

- `examples/plugins/toast4opencode_win.js`
- `examples/plugins/toast4opencode_wsl.js`

If OpenCode CLI is already installed, use this sequence:

1. Place the Toast4OpenCode repository in a stable Windows path.

- Example: `C:\tools\Toast4OpenCode`
- Your OpenCode config lives under your user profile, while the notifier script lives in this repository, so absolute paths are safer than relative ones.

2. Decide which shell normally runs OpenCode.

- PowerShell or `cmd.exe` : Save the toast4opencode_win.js file in `C:\Users\<username>\.config\opencode\plugins`.
- WSL2 :  Save the toast4opencode_wsl.js file in `/home/<USERNAME>/.config/opencode/plugins`.

3. Replace the installed full path inside either `toast4opencode_wsl.js` or `toast4opencode_win.js` and save the file.

- OpenCode may run from many different project directories, so `.\scripts\...` is fragile.
- A path like `C:\\tools\\Toast4OpenCode\\...` is stable even when your current working directory changes.


Windows PowerShell (`cmd.exe`):

```powershell
...
import { execFile } from "child_process"
 
const TOAST_CMD = "D:\\UTIL\\Toast4OpenCode\\toast4opencode.cmd"
 
const EVENT_MAP = {
  "session.idle":     "complete",
  "session.error":    "error",
  "permission.asked": "permission",
  "question":         "input",
}
...
```

WSL2:

```bash
...
import { execFile } from "child_process"
 
const TOAST_CMD = "/mnt/d/UTIL/Toast4OpenCode/toast4opencode"
 
const EVENT_MAP = {
  "session.idle":     "complete",
  "session.error":    "error",
  "permission.asked": "permission",
  "question":         "input",
}
...
```

4. Test Toast4OpenCode by itself before wiring it into OpenCode.

PowerShell:
```powershell
pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File C:\tools\Toast4OpenCode\scripts\toast4opencode.ps1 complete
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File C:\tools\Toast4OpenCode\scripts\toast4opencode.ps1 error "OpenCode 오류" "테스트 알림"
```

cmd.exe:
```shell
C:\tools\Toast4OpenCode\toast4opencode.cmd complete
C:\tools\Toast4OpenCode\toast4opencode.cmd error "OpenCode 오류" "테스트 알림"
```

WSL2:
```bash
/mnt/c/tools/Toast4OpenCode/toast4opencode complete
/mnt/c/tools/Toast4OpenCode/toast4opencode error "OpenCode 오류" "테스트 알림"
```

5. Run real OpenCode tasks and verify that the plugins fire on actual events.

- Run a short task and confirm the completion toast appears
- Trigger a failure to confirm the error toast appears
- Trigger a permission request or input prompt to verify those plugins

6. Tune noise level in `C:\tools\Toast4OpenCode\setting.json`.

- Set `"complete": false` if completion toasts are too noisy
- Set `"sound": false` if you want visual toasts without sound
- Set `taskbarFlash.complete = false` if you want completion toasts without taskbar flashing
- Keep only `taskbarFlash.error = true` if you want flashing only for failures

Practical tips:

- The OpenCode config directory and the Toast4OpenCode repository are separate locations. Think of config under `C:\Users\<your-user>\.config\opencode\` and the notifier itself under `C:\tools\Toast4OpenCode`.
- Absolute paths are more reliable than relative paths for OpenCode plugins.
- For WSL2, keeping the repository under `/mnt/c/...` makes it easier for Windows PowerShell to reach the script.
- If OpenCode runs many background tasks, keeping only `error`, `permission`, and `input` enabled can be more practical than enabling every completion toast.

## Change Settings

Edit `setting.json` directly.

PowerShell example:

```powershell
$cfg = Get-Content .\setting.json -Raw | ConvertFrom-Json
$cfg.complete = $false
$cfg.sound = $false
$cfg.taskbarFlash.complete = $false
$cfg.taskbarFlash.input = $false
$cfg.taskbarFlash.sound = $false
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

- If WSL2 cannot start a notification, verify that `pwsh.exe` or `powershell.exe` is callable from WSL2 and that the repository path is reachable from Windows.
- If notifications appear without sound, confirm `sound` is `true` in `setting.json` and that you did not pass `-Silent`.
- If taskbar flashing does not happen, the script now tries the foreground window (e.g. Windows Terminal) first, then falls back to the console window handle. If neither is available, a warning is printed and the flash is skipped. The output line will say `(taskbar flash unavailable)` when this happens.
- Under WSL2, rapid successive events are serialized through an internal queue in the plugin, so toasts always arrive in order and never burst all at once.
- If notification display fails on a very minimal Windows image, confirm that `System.Windows.Forms` and `System.Drawing` are available in PowerShell.
- If native toast registration fails for some reason, the script falls back to a legacy balloon notification so you still get a visible alert.
