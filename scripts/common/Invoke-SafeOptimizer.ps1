# MohZarg Safe Optimizer shared core
# Requires Windows PowerShell 5.1. Review-first: no registry edits, service disabling,
# paging changes, or destructive disk operations.
[CmdletBinding()]
param([ValidateSet('LowEnd','Balanced','Performance')][string]$Profile = 'Balanced')
Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Continue'
function Write-Heading([string]$Text) {
    Write-Host ""; Write-Host ("-" * 64) -ForegroundColor DarkCyan
    Write-Host $Text -ForegroundColor Cyan; Write-Host ("-" * 64) -ForegroundColor DarkCyan
}
function Ask-YesNo([string]$Text) { return ((Read-Host "$Text [y/N]") -match '^(y|yes)$') }
function To-ReadableSize([double]$Bytes) {
    if ($Bytes -ge 1TB) { return ('{0:N2} TB' -f ($Bytes / 1TB)) }
    if ($Bytes -ge 1GB) { return ('{0:N2} GB' -f ($Bytes / 1GB)) }
    if ($Bytes -ge 1MB) { return ('{0:N2} MB' -f ($Bytes / 1MB)) }
    return ('{0:N0} bytes' -f $Bytes)
}
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$desktop = [Environment]::GetFolderPath('Desktop')
$logPath = Join-Path $desktop "MohZarg_Optimizer_$stamp.log"
Start-Transcript -Path $logPath -Force | Out-Null
try {
    Write-Host "MohZarg Safe Optimizer" -ForegroundColor Green
    Write-Host "Profile: $Profile | Review-first mode"
    Write-Host "Log: $logPath"
    Write-Heading "1. OS and hardware"
    $os = Get-CimInstance Win32_OperatingSystem
    $computer = Get-CimInstance Win32_ComputerSystem
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    [pscustomobject]@{
        OS=$os.Caption; Version=$os.Version; Build=$os.BuildNumber
        PowerShell=$PSVersionTable.PSVersion.ToString(); CPU=$cpu.Name
        LogicalProcessors=$computer.NumberOfLogicalProcessors
        RAM_GB=[math]::Round($computer.TotalPhysicalMemory/1GB,2)
    } | Format-List
    Write-Heading "2. Drive space"
    Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" |
        Select-Object DeviceID,VolumeName,@{N='Size';E={To-ReadableSize $_.Size}},
        @{N='Free';E={To-ReadableSize $_.FreeSpace}},
        @{N='FreePercent';E={if ($_.Size -gt 0) {[math]::Round(100*$_.FreeSpace/$_.Size,1)} else {0}}} |
        Format-Table -AutoSize
    Write-Heading "3. Disk model and RAM-heavy processes"
    try { Get-CimInstance Win32_DiskDrive | Select-Object Model,MediaType,InterfaceType,@{N='Size_GB';E={[math]::Round($_.Size/1GB,1)}} | Format-Table -AutoSize } catch { Write-Host "Disk model information unavailable." }
    Get-Process -ErrorAction SilentlyContinue | Sort-Object WorkingSet64 -Descending |
        Select-Object -First 12 @{N='Process';E={$_.ProcessName}},@{N='RAM_MB';E={[math]::Round($_.WorkingSet64/1MB,1)}},Id |
        Format-Table -AutoSize
    Write-Host "For live disk activity, open Task Manager > Processes > sort by Disk."
    Write-Heading "4. Startup inventory (report only)"
    try { Get-CimInstance Win32_StartupCommand | Select-Object Name,Command,Location,User | Format-Table -Wrap -AutoSize } catch { Write-Warning "Startup inventory unavailable." }
    Write-Host "No startup item will be disabled automatically."
    Write-Heading "5. Recommendations for selected profile"
    $ramGB=[math]::Round($computer.TotalPhysicalMemory/1GB,1)
    switch ($Profile) {
      'LowEnd' {
        Write-Host "LOW-END: prioritize disk free space, diagnose 100% disk activity, close unneeded concurrent apps, and review startup entries manually."
        if ($ramGB -le 8) { Write-Host "Keep the Windows-managed paging file enabled; avoid RAM booster apps." }
        Write-Host "If using an HDD, back up data and consider a compatible SATA SSD."
      }
      'Balanced' {
        Write-Host "BALANCED: preserve safe Windows defaults, review startup entries and disk space, and measure one change at a time."
        Write-Host "Keep security software and Windows security features enabled."
      }
      'Performance' {
        Write-Host "PERFORMANCE: measure CPU, disk and memory bottlenecks before selecting a remedy."
        Write-Host "Use vendor-supported drivers and power settings suitable for the device; do not trade security for unverified tweaks."
      }
    }
    if ($ramGB -le 4) { Write-Warning "RAM <= 4 GB: multitasking may be limited; do not disable the paging file." }
    elseif ($ramGB -le 8) { Write-Host "RAM tier: entry-level (up to 8 GB)." }
    elseif ($ramGB -le 16) { Write-Host "RAM tier: mainstream (8-16 GB)." }
    else { Write-Host "RAM tier: high-memory (over 16 GB)." }
    Write-Heading "6. Optional old TEMP cleanup"
    $tempPath=[IO.Path]::GetFullPath([IO.Path]::GetTempPath())
    Write-Host "Only current-user TEMP files older than 7 days are eligible: $tempPath"
    Write-Host "Personal folders, browser profiles, and Windows Update cache are excluded."
    if (Ask-YesNo "List eligible files?") {
      $cutoff=(Get-Date).AddDays(-7)
      $items=@(Get-ChildItem -LiteralPath $tempPath -File -Recurse -Force -ErrorAction SilentlyContinue | Where-Object {$_.LastWriteTime -lt $cutoff})
      $total=($items | Measure-Object -Property Length -Sum).Sum
      if ($null -eq $total) {$total=0}
      Write-Host ("Candidates: {0}; total: {1}" -f $items.Count,(To-ReadableSize $total))
      $items | Select-Object -First 25 FullName,@{N='MB';E={[math]::Round($_.Length/1MB,2)}} | Format-Table -Wrap -AutoSize
      if ($items.Count -gt 0 -and (Ask-YesNo "Delete eligible old TEMP files?")) {
        $removed=0
        foreach ($item in $items) { try { Remove-Item -LiteralPath $item.FullName -Force -ErrorAction Stop; $removed++ } catch {} }
        Write-Host "Removed files: $removed. Locked or inaccessible files may be skipped."
      } else { Write-Host "No files deleted." }
    } else { Write-Host "Cleanup skipped." }
    Write-Heading "7. Safety notes"
    Write-Host "No registry, service, scheduled-task, startup, security, or pagefile changes were made."
    Write-Host "Windows 7/8.1 and standard Windows 10 are out of general support; tuning does not restore security support."
    Write-Host "This tool does not guarantee a speed increase. Review log: $logPath"
    Read-Host "Press Enter to close"
} catch {
    Write-Error "Unexpected error: $($_.Exception.Message)"
} finally { Stop-Transcript | Out-Null }
