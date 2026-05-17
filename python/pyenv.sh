#!/bin/bash
# install_python.sh
# Script to install Python using pyenv on macOS
# Usage: bash install_python.sh

set -e

ZSHRC="$HOME/.zshrc"

# Install dependencies
if ! command -v brew &>/dev/null; then
  echo "Homebrew is not installed. Please install Homebrew first."
  exit 1
fi

echo "Installing tcl-tk and pyenv via Homebrew"
brew install tcl-tk pyenv

# Set environment variables for tcl-tk
LDFLAGS_LINE='export LDFLAGS="-L$(brew --prefix tcl-tk)/lib"'
CPPFLAGS_LINE='export CPPFLAGS="-I$(brew --prefix tcl-tk)/include"'
PKG_CONFIG_PATH_LINE='export PKG_CONFIG_PATH="$(brew --prefix tcl-tk)/lib/pkgconfig"'
PATH_LINE='export PATH="$(brew --prefix tcl-tk)/bin:$PATH"'

echo "" 
echo "Add the following lines to your shell configuration file (e.g., ~/.zshrc or ~/.bash_profile):"
echo "$LDFLAGS_LINE"
echo "$CPPFLAGS_LINE"
echo "$PKG_CONFIG_PATH_LINE"
echo "$PATH_LINE"
echo ""
echo "You can copy and paste them into your config file."

# Export for current session
export LDFLAGS="-L$(brew --prefix tcl-tk)/lib"
export CPPFLAGS="-I$(brew --prefix tcl-tk)/include"
export PKG_CONFIG_PATH="$(brew --prefix tcl-tk)/lib/pkgconfig"
export PATH="$(brew --prefix tcl-tk)/bin:$PATH"

# Initialize pyenv
if ! command -v pyenv &>/dev/null; then
  echo "pyenv is not installed correctly"
  exit 1
fi

eval "$(pyenv init - zsh)"

PYTHON_VERSION="3.12"

echo "Installing Python $PYTHON_VERSION with pyenv"
pyenv install -s $PYTHON_VERSION
pyenv global $PYTHON_VERSION

echo "Upgrading pip and installing packages"
pip install --upgrade pip
pip install uv
uv pip install --system --upgrade pip
uv pip install --system requests ipython setuptools wheel spyder-kernels

echo "Python $PYTHON_VERSION installation complete!"
