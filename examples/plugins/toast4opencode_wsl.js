// wsl에 opencode가 설치된 디렉토리 아래에 plugins 서브디렉토리 만든 후 저장하세요.
// 예 : /home/USERNAME/.config/opencode/plugins/toast4opencode_wsl.js

import { execFile } from "child_process"
 
const TOAST_CMD = "/mnt/d/UTIL/Toast4OpenCode/toast4opencode"
 
const EVENT_MAP = {
  "session.idle":     "complete",
  "session.error":    "error",
  "permission.asked": "permission",
  "question":         "input",
}
 
// Serialize notifications so rapid events don't launch concurrent pwsh.exe
// processes over the WSL bridge (which causes out-of-order / burst delivery).
let _notifyChain = Promise.resolve()

function notify(arg) {
  _notifyChain = _notifyChain.then(
    () => new Promise((resolve) => {
      execFile(TOAST_CMD, [arg], { timeout: 15000 }, (err) => {
        if (err) console.error("[toast4opencode]", err.message)
        resolve()
      })
    })
  )
}

export const Toast4OpenCode = async () => {
  return {
    event: async ({ event }) => {
      const arg = EVENT_MAP[event.type]
      if (arg) notify(arg)
    },
  }
}
 
