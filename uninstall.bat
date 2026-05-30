@echo off
:: ClaudeTeleport — Uninstaller
echo.
echo [36m  ClaudeTeleport Uninstaller[0m
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0uninstall.ps1"
echo.
echo Press any key to exit...
pause >nul
