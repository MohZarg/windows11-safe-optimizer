# Windows 11 Optimizer - Conservative, review-first edition
# Compatible with Windows PowerShell 5.1 / Windows 11.
# This script does not disable services, edit registry settings, delete personal files,
# change pagefile settings, or run destructive disk operations.
# Review the proposed actions before accepting them.

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Continue'

function Write-Section([string]$Title) {
    Write-Host ""
    Write-Host ("=" * 68) -ForegroundColor DarkCyan
    Write-Host $Title -ForegroundColor Cyan
    Write-Host ("=" * 68) -ForegroundColor DarkCyan
}

function Confirm-Action([string]$Prompt) {
    $answer = Read-Host "$Prompt [y/N]"
    return ($answer -match '^(y|yes)$')
}

function Format-Bytes([double]$Bytes) {
    if ($Bytes -ge 1TB) { return ('{0:N2} TB' -f ($Bytes / 1TB)) }
    if ($Bytes -ge 1GB) { return ('{0:N2} GB' -f ($Bytes / 1GB)) }
    if ($Bytes -ge 1MB) { return ('{0:N2} MB' -f ($Bytes / 1MB)) }
    return ('{0:N0} bytes' -f $Bytes)
}

$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$desktop = [Environment]::GetFolderPath('Desktop')
$logPath = Join-Path $desktop "Windows11_Optimizer_$timestamp.log"
Start-Transcript -Path $logPath -Force | Out-Null

try {
    Clear-Host
    Write-Host "WINDOWS 11 OPTIMIZER - SAFE / REVIEW-FIRST" -ForegroundColor Green
    Write-Host "This tool reports first and asks before each meaningful action."
    Write-Host "It does NOT promise a speed increase or change critical Windows settings."
    Write-Host "Log file: $logPath"

    Write-Section "1. SYSTEM SUMMARY"
    try {
        $os = Get-CimInstance Win32_OperatingSystem
        $cs = Get-CimInstance Win32_ComputerSystem
        $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
        [pscustomobject]@{
            Windows = $os.Caption
            Version = $os.Version
            Build = $os.BuildNumber
            RAM_Total_GB = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
            CPU = $cpu.Name
            LastBoot = $os.LastBootUpTime
        } | Format-List
    } catch {
        Write-Warning "Could not read all system details: $($_.Exception.Message)"
    }

    Write-Section "2. DRIVE SPACE"
    $drives = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" |
        Where-Object { $_.DeviceID -in @('C:', 'M:') }
    foreach ($drive in $drives) {
        $freePct = if ($drive.Size -gt 0) { [math]::Round(($drive.FreeSpace / $drive.Size) * 100, 1) } else { 0 }
        [pscustomobject]@{
            Drive = $drive.DeviceID
            Label = $drive.VolumeName
            Size = Format-Bytes $drive.Size
            Free = Format-Bytes $drive.FreeSpace
            FreePercent = "$freePct%"
        } | Format-List
        if ($drive.DeviceID -eq 'C:' -and $drive.FreeSpace -lt 15GB) {
            Write-Warning "C: has less than 15 GB free. Windows may run poorly; avoid large downloads/updates until space is recovered."
        }
    }

    Write-Section "3. TOP RESOURCE USERS (READ-ONLY)"
    Write-Host "Top processes by working set (RAM):"
    Get-Process -ErrorAction SilentlyContinue |
        Sort-Object WorkingSet64 -Descending |
        Select-Object -First 10 @{N='Process';E={$_.ProcessName}},
            @{N='RAM_MB';E={[math]::Round($_.WorkingSet64 / 1MB, 1)}},
            Id | Format-Table -AutoSize
    Write-Host ""
    Write-Host "Top processes by accumulated CPU time (not current Disk activity):"
    Get-Process -ErrorAction SilentlyContinue |
        Sort-Object CPU -Descending |
        Select-Object -First 10 @{N='Process';E={$_.ProcessName}},
            @{N='CPU_seconds';E={if ($null -ne $_.CPU) {[math]::Round($_.CPU,1)} else {0}}},
            Id | Format-Table -AutoSize
    Write-Host "Note: Windows PowerShell cannot reliably attribute live disk I/O from this simple snapshot."
    Write-Host "Use Task Manager > Processes > click Disk to identify current disk activity."

    Write-Section "4. STARTUP APPS (REPORT ONLY)"
    try {
        $startup = Get-CimInstance Win32_StartupCommand -ErrorAction Stop |
            Select-Object Name, Command, Location, User
        if ($startup) { $startup | Format-Table -Wrap -AutoSize }
        else { Write-Host "No startup entries returned." }
        Write-Host "No startup items will be disabled automatically."
    } catch {
        Write-Warning "Could not read startup entries: $($_.Exception.Message)"
    }

    Write-Section "5. BACKUP / RESTORE STATUS (REPORT ONLY)"
    try {
        $restorePoints = Get-CimInstance -Namespace root/default -ClassName SystemRestore -ErrorAction Stop |
            Sort-Object CreationTime -Descending |
            Select-Object -First 5 SequenceNumber, Description, CreationTime
        if ($restorePoints) {
            Write-Host "Recent System Restore points reported by Windows:"
            $restorePoints | Format-Table -AutoSize
        } else {
            Write-Warning "No System Restore points were found, or System Protection is not enabled."
        }
    } catch {
        Write-Warning "Could not query System Restore status. This does not prove no backup exists."
        Write-Host "Check manually: Start > search 'Create a restore point' > System Protection."
    }
    Write-Host "This script does not create restore points or back up personal files."

    Write-Section "6. OPTIONAL TEMPORARY-FILE CLEANUP"
    Write-Host "This action targets only files in the current user's TEMP folder that are older than 7 days."
    Write-Host "Files currently in use or inaccessible will be skipped."
    Write-Host "It does not touch Downloads, Documents, Desktop, Recycle Bin, browser profiles, or Windows Update cache."
    $tempPath = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
    Write-Host "Target: $tempPath"
    if (Confirm-Action "List eligible temporary files before cleanup?") {
        try {
            $cutoff = (Get-Date).AddDays(-7)
            $eligible = Get-ChildItem -LiteralPath $tempPath -File -Recurse -Force -ErrorAction SilentlyContinue |
                Where-Object { $_.LastWriteTime -lt $cutoff }
            $eligibleBytes = ($eligible | Measure-Object -Property Length -Sum).Sum
            if ($null -eq $eligibleBytes) { $eligibleBytes = 0 }
            Write-Host ("Eligible files: {0}; total size: {1}" -f @($eligible).Count, (Format-Bytes $eligibleBytes))
            if (@($eligible).Count -gt 0) {
                $eligible | Select-Object -First 20 FullName, @{N='MB';E={[math]::Round($_.Length/1MB,2)}} | Format-Table -Wrap -AutoSize
                if (@($eligible).Count -gt 20) { Write-Host "Showing first 20 entries only." }
                if (Confirm-Action "Delete these eligible old TEMP files?") {
                    $deletedBytes = 0
                    $deletedCount = 0
                    foreach ($file in $eligible) {
                        try {
                            $length = $file.Length
                            Remove-Item -LiteralPath $file.FullName -Force -ErrorAction Stop
                            $deletedBytes += $length
                            $deletedCount++
                        } catch {
                            # Skip in-use, protected, or inaccessible files.
                        }
                    }
                    Write-Host ("Deleted {0} files ({1}). Some files may have been skipped." -f $deletedCount, (Format-Bytes $deletedBytes)) -ForegroundColor Green
                } else {
                    Write-Host "Cleanup skipped by user."
                }
            } else {
                Write-Host "No eligible old temporary files found."
            }
        } catch {
            Write-Warning "Temporary-file review failed: $($_.Exception.Message)"
        }
    } else {
        Write-Host "Temporary-file cleanup skipped."
    }

    Write-Section "7. DISK HEALTH CHECK (READ-ONLY)"
    try {
        Get-PhysicalDisk -ErrorAction Stop |
            Select-Object FriendlyName, MediaType, HealthStatus, OperationalStatus, @{N='Size_GB';E={[math]::Round($_.Size/1GB,1)}} |
            Format-Table -AutoSize
        Write-Host "If no physical disks are listed, use the drive manufacturer's diagnostic tool or Windows drive properties."
    } catch {
        Write-Host "Physical-disk health details are unavailable on this system."
        Write-Host "You can run the non-repairing check manually: open Terminal and run 'chkdsk C:' (do not add /f or /r for this initial check)."
    }

    Write-Section "8. RECOMMENDED NEXT STEPS"
    Write-Host "1. Restart Windows after saving your work if updates or long-running processes are active."
    Write-Host "2. Open Task Manager > Processes > sort by Disk to identify the current 100% disk user."
    Write-Host "3. Keep the Windows-managed paging file enabled; do not disable it on an 8 GB RAM system."
    Write-Host "4. Do not use registry cleaners or 'RAM booster' apps."
    Write-Host "5. If HDD health is warning/bad or clicking, back up important files before further tests."
    Write-Host "6. A SATA SSD is usually the largest performance upgrade for an older HDD-based PC."

    Write-Section "FINISHED"
    Write-Host "No services were disabled. No registry settings were changed."
    Write-Host "No personal folders were targeted. Review the log on your Desktop:"
    Write-Host $logPath -ForegroundColor Yellow
    Read-Host "Press Enter to close"
}
finally {
    Stop-Transcript | Out-Null
}
