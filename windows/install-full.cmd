@echo off
REM Installs the baseline with the FULL Office suite (Access, Publisher, etc.).
REM For the normal slimmed Office, use install.cmd instead.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" -FullOffice

echo.
pause
