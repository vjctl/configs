# WSL Configuration

This directory contains configuration files and scripts for setting up Windows Subsystem for Linux (WSL) with Ubuntu 24.04.

## Prerequisites

- Windows 10/11
- PowerShell 5.1 or later
- Administrative privileges
- Scoop installed (for PowerToys context menu)

## Setup Process

1. Open PowerShell as Administrator
2. Run the setup script:

```powershell
.\setup.ps1
```

3. Restart your computer to complete WSL installation
4. After restart, open WSL and run the provided commands to complete the setup

## Installed Components

- Ubuntu 24.04
- Build essential packages
- Homebrew for Linux
- GCC compiler
- Oh My Bash shell framework
- Starship prompt

## Configuration Files

- `setup.ps1`: Windows-side setup script
- `README.md`: This documentation

## Notes

- WSL requires a system restart after initial installation
- The setup script assumes PowerToys is installed via Scoop
- Some commands need to be run in the WSL environment after restart 