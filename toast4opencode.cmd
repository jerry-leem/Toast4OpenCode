@echo off
setlocal
set SCRIPT_DIR=%~dp0
set "PS_EXE="

where pwsh >nul 2>&1
if %ERRORLEVEL% EQU 0 set "PS_EXE=pwsh"

if not defined PS_EXE (
    where powershell >nul 2>&1
    if %ERRORLEVEL% EQU 0 set "PS_EXE=powershell"
)

if not defined PS_EXE (
    echo toast4opencode.cmd: neither 'pwsh' nor 'powershell' was found in PATH. 1>&2
    exit /b 9009
)

"%PS_EXE%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%scripts\toast4opencode.ps1" %*
exit /b %ERRORLEVEL%
