@echo off
:: ClaudeTeleport — One-Click Installer
:: Right-click → "Run as administrator" NOT required
echo.
echo [36m  ClaudeTeleport Installer[0m
echo [90m  Running from: %~dp0[0m
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1"
echo.
echo Press any key to exit...
pause >nul
