@echo off
REM Easy installer: double-click this file, or run  .\windows\install.cmd
REM Runs install.ps1, which installs the apps in apps.json and prints a
REM summary (installed / already present / failed) at the end.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1"

echo.
pause
