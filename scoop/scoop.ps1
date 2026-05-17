# Scoop Installation Script
# This script automates the installation of Scoop and configured packages

Write-Host "Starting Scoop installation process" -ForegroundColor Green

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Please run this script as Administrator" -ForegroundColor Red
    exit 1
}

# Set execution policy
Write-Host "Setting execution policy" -ForegroundColor Yellow
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# Install Scoop if not already installed
if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Scoop" -ForegroundColor Yellow
    Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
}

# Install Git if not already installed
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Git" -ForegroundColor Yellow
    scoop install git
}

# Configure Git
Write-Host "Configuring Git" -ForegroundColor Yellow
git config --global credential.helper manager

# Add extras bucket if not already added
if (-not (scoop bucket list | Select-String "extras")) {
    Write-Host "Adding extras bucket" -ForegroundColor Yellow
    scoop bucket add extras
    scoop bucket add versions
    scoop bucket add knox-scoop https://github.com/KNOXDEV/knox-scoop
    scoop bucket add nonportable
}

# Install packages
Write-Host "Installing packages" -ForegroundColor Yellow

$packages = @(
    "powertoys",
    "extras/glazewm",
    "extras/zebar",
    "extras/motrix",
    "extras/zed",
    "extras/unigetui",
    "notepadplusplus",
    "extras/microsoft-teams",
    "scoop-backup",
    "extras/localsend",
    "nonportable/grammarly-np"
    "sqlite"
)

foreach ($package in $packages) {
    Write-Host "Installing $package" -ForegroundColor Cyan
    scoop install $package
}

Write-Host "Installation complete!" -ForegroundColor Green
Write-Host "You may need to restart your terminal for some changes to take effect." -ForegroundColor Yellow
