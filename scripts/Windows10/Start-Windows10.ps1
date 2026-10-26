# Windows 10 edition launcher. Requires Windows PowerShell 5.1.
$ErrorActionPreference='Stop'
if ($PSVersionTable.PSVersion -lt [version]'5.1') {
    Write-Error "Windows PowerShell 5.1 is required. Install it and its prerequisites from official Microsoft sources."
    exit 3
}
$os=Get-CimInstance Win32_OperatingSystem
if ($os.Caption -notmatch 'Windows 10') {
    Write-Error "This launcher is intended for Windows 10 only. Use the matching edition."
    exit 2
}
$choice=Read-Host "Profile: 1 Low-end, 2 Balanced, 3 Performance [default 1]"
switch ($choice) {
    '2' { $selectedProfile='Balanced' }
    '3' { $selectedProfile='Performance' }
    default { $selectedProfile='LowEnd' }
}
& (Join-Path $PSScriptRoot '..\common\Invoke-SafeOptimizer.ps1') -Profile $selectedProfile
