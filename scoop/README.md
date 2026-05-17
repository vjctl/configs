# Windows Scoop Configuration

This directory contains configuration files and scripts for managing Windows packages using [Scoop](https://scoop.sh/), a command-line installer for Windows.

## Prerequisites

- Windows 10/11
- PowerShell 5.1 or later
- Administrative privileges (for some installations)

## Initial Setup

1. Open PowerShell as Administrator
2. Run the following commands:

```powershell
# Allow script execution
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Install Scoop
Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression

# Install Git (required for Scoop)
scoop install git

# Configure Git credential helper
git config --global credential.helper manager

# Add the extras bucket
scoop bucket add extras
```

## Installed Packages

The following packages are configured in this setup:

- **PowerToys**: Windows system utilities
- **GlazeWM**: Tiling window manager
- **Zebar**: Modern taskbar replacement
- **Motrix**: Download manager
- **Cursor**: Modern IDE
- **Notepad++**: Advanced text editor

## Configuration Files

- `packages.json`: List of installed packages
- `install.ps1`: Installation script

## Usage

To install all configured packages, run:

```powershell
.\install.ps1
```

## Maintenance

To update all installed packages:

```powershell
scoop update *
scoop cleanup *
```

## Notes

- Some packages may require additional configuration after installation
- Keep this repository updated with your package preferences
- Consider using `scoop export` to backup your package list
