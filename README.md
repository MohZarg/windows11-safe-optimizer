# MohZarg Safe Optimizer

An experimental, review-first toolkit for Windows 7, 8.1, 10, and 11. Each edition has a separate launcher and shares a diagnostic core with three hardware profiles. It does not promise speed gains or silently change critical settings.

## Editions
- Windows 7 SP1: scripts/Windows7/Start-Windows7.ps1 — requires Windows PowerShell 5.1 and prerequisites; out of general support.
- Windows 8.1: scripts/Windows81/Start-Windows81.ps1 — requires Windows PowerShell 5.1; out of general support.
- Windows 10: scripts/Windows10/Start-Windows10.ps1 — requires Windows PowerShell 5.1; standard Windows 10 is out of general support.
- Windows 11: scripts/Windows11/Start-Windows11.ps1 — requires Windows PowerShell 5.1.
The shared core is scripts/common/Invoke-SafeOptimizer.ps1. Launchers verify the OS name and stop on mismatch.

## Hardware profiles
- LowEnd: prioritize disk space, diagnose RAM/disk pressure, reduce concurrent workloads, and avoid RAM-booster utilities.
- Balanced: preserve safe defaults, review startup entries, and measure one change at a time.
- Performance: measure CPU, disk, and memory bottlenecks before choosing a remedy.
Profiles do not automatically disable services or startup apps; this is intentional to avoid breaking required features.

## Quick start
Download and extract the repository. Run the launcher for your OS from PowerShell. Windows 11 example:
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File .\scripts\Windows11\Start-Windows11.ps1

Choose 1 for LowEnd, 2 for Balanced, or 3 for Performance. Type y only to approve optional cleanup of old current-user TEMP files; Enter declines. A log is saved to the Desktop.

## Safety boundaries
- No automatic service, scheduled-task, startup, registry, pagefile, security, or Windows Update policy changes.
- No deletion from personal folders, browser profiles, or Windows Update cache.
- Optional deletion is limited to files older than seven days in the current user's TEMP folder, after listing candidates and obtaining confirmation.
- No disk repair operations and no guaranteed speed increase.
- Keep the Windows-managed paging file enabled. If an HDD reports health warnings, back up important data before further testing.

Windows 7, Windows 8.1, and standard Windows 10 are out of general support. Performance tuning does not restore security updates. CI static analysis is not a substitute for testing on each real or virtualized OS edition.

## License
MIT; see LICENSE.
