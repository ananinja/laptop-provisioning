@echo off
REM Easy uninstaller: double-click this file, or run  .\windows\uninstall.cmd
REM Runs uninstall.ps1, which removes the apps in apps.json (after a
REM confirmation prompt) and prints a summary at the end.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0uninstall.ps1"

echo.
pause
