@echo off
setlocal
title MohZarg Safe Optimizer - Windows 10
powershell.exe -NoLogo -NoProfile -ExecutionPolicy RemoteSigned -File "%~dp0scripts\Windows10\Start-Windows10.ps1"
if errorlevel 1 echo The tool reported an error. Review the message above.
pause
endlocal
