@echo off
setlocal
title Windows 11 Safe Optimizer
echo Windows 11 Safe Optimizer - Review-first mode
echo This tool reports system status and asks before deleting eligible temporary files.
echo.
powershell.exe -NoLogo -NoProfile -ExecutionPolicy RemoteSigned -File "%~dp0scripts\Windows11_Optimizer.ps1"
if errorlevel 1 (
  echo.
  echo The script ended with an error. Review the output above and the log on your Desktop.
)
echo.
pause
endlocal
