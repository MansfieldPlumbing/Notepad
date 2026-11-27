@echo off
if exist "%~dp0build\Notepad.exe" (
  start "" "%~dp0build\Notepad.exe" %*
  exit /b
)
where pwsh.exe >nul 2>nul
if errorlevel 1 (
  echo This application requires PowerShell 7 ^(pwsh.exe^).
  pause
  exit /b 1
)
start "" pwsh.exe -NoProfile -STA -WindowStyle Hidden -File "%~dp0Start Notepad from Source.ps1" %*
