@echo off
REM Easy installer: double-click this file, or run  .\windows\install.cmd
REM Installs the standard app baseline from apps.json (next to this file).
REM Already-installed apps are skipped; missing ones are installed.

echo ==^> Installing standard apps...
winget import --import-file "%~dp0apps.json" --accept-package-agreements --accept-source-agreements --ignore-unavailable

echo.
echo ==^> Done. Reminder: sign into Microsoft 365 to activate Office.
pause
