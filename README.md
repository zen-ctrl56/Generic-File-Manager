# Generic File Manager V1.0

A manual, menu-driven PowerShell file cleanup utility for Windows.

## Features
- Choose a target folder by entering its path
- Set a maximum number of files (1–1000)
- Filter by last-modified date range and extension
- Optionally include subfolders
- Preview matching files, oldest first
- Choose Recycle Bin or permanent deletion
- Explicitly type `DELETE` before files are removed

## Running
Right-click `Generic_File_Manager.ps1` and select **Run with PowerShell**, where your organization's policy permits scripts. Alternatively, run it from an already-open PowerShell session using `.\Generic_File_Manager.ps1`.

## Safety
Runs only when launched manually, without elevation, background tasks, policy changes, or security bypasses. It cannot delete files without the current user's permissions. Recycle Bin behavior is not guaranteed on network locations; network paths are rejected in Recycle Bin mode. Permanent deletion may be unrecoverable. Test on disposable files first. Avoid system and production-critical folders.
