# Windows 11 edition. Requires Windows PowerShell 5.1.
$ErrorActionPreference='Stop'
$os=Get-CimInstance Win32_OperatingSystem
if ($os.Caption -notmatch 'Windows 11') { Write-Error "Windows 11 launcher only."; exit 2 }
if ($PSVersionTable.PSVersion -lt [version]'5.1') { Write-Error "Windows PowerShell 5.1 is required."; exit 3 }
$p=Read-Host "Profile: 1 Low-end, 2 Balanced, 3 Performance [default 1]"
switch ($p) {'2' {$profile='Balanced'} '3' {$profile='Performance'} default {$profile='LowEnd'}}
& (Join-Path $PSScriptRoot '..\common\Invoke-SafeOptimizer.ps1') -Profile $profile
