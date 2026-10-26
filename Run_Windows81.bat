@echo off
setlocal
title MohZarg Safe Optimizer - Windows 8.1
powershell.exe -NoLogo -NoProfile -ExecutionPolicy RemoteSigned -File "%~dp0scripts\Windows81\Start-Windows81.ps1"
if errorlevel 1 echo The tool reported an error. Review the message above.
pause
endlocal
