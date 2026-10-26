@echo off
setlocal
title MohZarg Safe Optimizer - Windows 11
powershell.exe -NoLogo -NoProfile -ExecutionPolicy RemoteSigned -File "%~dp0scripts\Windows11\Start-Windows11.ps1"
if errorlevel 1 echo The tool reported an error. Review the message above.
pause
endlocal
