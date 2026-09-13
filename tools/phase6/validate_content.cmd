@echo off
setlocal

set "phase6_script=%~dp0validate_content.ps1"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%phase6_script%" %*
exit /b %ERRORLEVEL%
