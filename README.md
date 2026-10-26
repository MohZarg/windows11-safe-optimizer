# Windows 11 Safe Optimizer

A conservative, review-first PowerShell utility for inspecting a Windows 11 PC and optionally removing old files from the current user's temporary folder.

> **Status:** Experimental / community review requested. Static checks do not prove runtime safety on every Windows configuration. Review the script before running it.

## What it does

- Reports Windows version, CPU, installed RAM, and available space on `C:` and `M:` when present.
- Lists processes with the largest working sets (RAM) and accumulated CPU time.
- Reports registered startup entries without disabling them.
- Attempts to report Windows System Restore points; it does not create one.
- Offers optional cleanup of files older than 7 days in the current user's TEMP folder, after listing candidates and asking for confirmation.
- Writes a transcript log to the current user's Desktop.

## What it deliberately does not do

- Does not disable Windows services or scheduled tasks.
- Does not edit the registry.
- Does not modify the Windows page file or memory-management settings.
- Does not target Downloads, Documents, Desktop, browser profiles, Recycle Bin, or Windows Update cache.
- Does not run `chkdsk /f`, `chkdsk /r`, defragmentation, or other destructive disk operations.
- Does not promise a speed increase. Diagnosis is the first goal.

## Requirements

- Windows 11
- Windows PowerShell 5.1 (included with Windows 11)
- Standard user permissions for basic reporting; some details may be unavailable without elevation

## Quick start

1. Download the repository ZIP from GitHub, or clone the repository.
2. Extract it to a normal folder.
3. Double-click `Run_Optimizer.bat`.
4. Read each prompt. For `[y/N]`, type `y` only if you agree; pressing Enter declines.
5. Review the log named `Windows11_Optimizer_*.log` on your Desktop.

You can also open PowerShell in the repository folder and run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File .\scripts\Windows11_Optimizer.ps1
```

Do not run scripts you have not reviewed. This project does not require administrator privileges for its basic reports; avoid elevating it unless you understand why a particular diagnostic needs elevation.

## Important notes for HDD + 8 GB RAM systems

- Keep the Windows-managed paging file enabled unless you have a specific, tested reason not to.
- If Disk usage stays at 100%, use Task Manager → Processes → sort by Disk to identify current activity. This script's process list is not a live per-process disk-I/O measurement.
- If a mechanical HDD reports warnings, makes unusual clicking noises, or becomes intermittently inaccessible, prioritize backing up important files before repair attempts.
- A SATA SSD is often the most effective hardware upgrade for an older HDD-based PC.

## Safety model

The only deletion operation is the optional cleanup of old files under the current user's TEMP directory. Candidates are listed and the user must confirm deletion. Files that are locked or inaccessible are skipped. This reduces risk but cannot guarantee that every temporary file is safe to remove on every machine.

The script reports restore-point status only. A restore point is not a substitute for a backup, and this tool does not back up personal files.

## Testing

The GitHub Actions workflow runs repository hygiene checks and PSScriptAnalyzer when available. CI static analysis is not the same as running the script on a real Windows 11 machine. Before relying on it, test in a disposable Windows VM or on a non-critical computer and inspect the resulting log.

## Project structure

```text
.
├── .github/
│   └── workflows/
│       └── static-checks.yml
├── scripts/
│   └── Windows11_Optimizer.ps1
├── Run_Optimizer.bat
├── README.md
├── README.fa.md
├── LICENSE
├── SECURITY.md
├── CONTRIBUTING.md
└── .gitignore
```

## Persian documentation

See [README.fa.md](README.fa.md) for the Persian guide.

## License

MIT. See [LICENSE](LICENSE).
