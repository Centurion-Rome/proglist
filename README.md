# ProgList

Lists all installed Windows programs and system information, exported to a markdown table.

## Features

- **Installed Programs** — machine-wide (HKLM) and per-user (HKCU) registry
- **Startup Programs** — Registry Run keys + Startup Folder
- **License Information** — Windows name, serial number, version, build, product key
- **Portable Apps** — detected from common portable locations
- **Available Updates** — checks winget for outdated packages

## Usage

Double-click `start.bat` or run:

```powershell
pwsh -ExecutionPolicy Bypass -File list-installed.ps1
```

Output is written to `output.md`.
