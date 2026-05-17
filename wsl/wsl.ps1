# WSL Setup Script
# This script configures WSL and installs necessary packages

Write-Host "Starting WSL setup process" -ForegroundColor Green

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Please run this script as Administrator" -ForegroundColor Red
    exit 1
}

# Install PowerToys context menu
Write-Host "Installing PowerToys context menu" -ForegroundColor Yellow
Invoke-Expression -Command "~\scoop\apps\powertoys\current\install-context.ps1"

# Install WSL and Ubuntu
Write-Host "Installing WSL and Ubuntu" -ForegroundColor Yellow
wsl --install Ubuntu-24.04

Write-Host "WSL setup complete!" -ForegroundColor Green
Write-Host "Please restart your computer to complete WSL installation." -ForegroundColor Yellow
Write-Host "After restart, run the following commands in WSL:" -ForegroundColor Yellow
Write-Host @"
sudo apt-get update
sudo apt-get install build-essential unzip zsh -y
sudo chsh -s /usr/bin/zsh $USER
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.zshrc
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
echo 'eval -- "$(/home/linuxbrew/.linuxbrew/bin/starship init zsh --print-full-init)"' >> ~/.zshrc
brew install gcc zsh-autosuggestions
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
echo 'source /home/linuxbrew/.linuxbrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh' >> ~/.zshrc
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo npm install -g @microsoft/inshellisense
is init --generate-full-configs 
is init zsh >> ~/.zshrc
"@ -ForegroundColor Cyan
