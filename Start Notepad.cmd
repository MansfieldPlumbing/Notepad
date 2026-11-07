@echo off
where pwsh.exe >nul 2>nul
if errorlevel 1 (
  echo This application requires PowerShell 7 ^(pwsh.exe^).
  pause
  exit /b 1
)
start "" pwsh.exe -NoProfile -STA -WindowStyle Hidden -File "%~dp0Notepad.ps1"
