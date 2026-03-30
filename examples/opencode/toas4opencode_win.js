// toast4opencode.js — Windows(PowerShell/cmd) 환경용 opencode 플러그인
// .cmd 파일을 cmd.exe /c 를 통해 호출
//
// 설치: %USERPROFILE%\.config\opencode\plugins\toast4opencode.js
 
import { execFile } from "child_process"
 
const TOAST_CMD = "D:\\UTIL\\Toast4OpenCode\\toast4opencode.cmd"
 
const EVENT_MAP = {
  "session.idle":     "complete",
  "session.error":    "error",
  "permission.asked": "permission",
  "question":         "input",
}
 
function notify(arg) {
  // Windows에서 .cmd 파일은 cmd.exe /c 를 통해 실행해야 함
  execFile("cmd.exe", ["/c", TOAST_CMD, arg], { timeout: 15000 }, (err) => {
    if (err) console.error("[toast4opencode]", err.message)
  })
}
 
export const Toast4OpenCode = async () => {
  return {
    event: async ({ event }) => {
      const arg = EVENT_MAP[event.type]
      if (arg) notify(arg)
    },
  }
}
 
