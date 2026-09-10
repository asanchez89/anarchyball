@echo off
setlocal

set "phase5_script=%~dp0build_windows.ps1"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%phase5_script%" %*
exit /b %ERRORLEVEL%
