@echo off
setlocal

set "phase0_script=%~dp0verify_all.ps1"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%phase0_script%" %*
exit /b %ERRORLEVEL%
