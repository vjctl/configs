#!/bin/bash
set -euo pipefail

ZSHRC="$HOME/.zshrc"

echo "Installing tcl-tk and pyenv via Homebrew"
brew install tcl-tk pyenv

# Environment variables for tcl-tk
LDFLAGS_LINE='export LDFLAGS="-L$(brew --prefix tcl-tk)/lib"'
CPPFLAGS_LINE='export CPPFLAGS="-I$(brew --prefix tcl-tk)/include"'
PKG_CONFIG_PATH_LINE='export PKG_CONFIG_PATH="$(brew --prefix tcl-tk)/lib/pkgconfig"'
PATH_LINE='export PATH="$(brew --prefix tcl-tk)/bin:$PATH"'

echo "" 
echo "Add to shell rc:"
echo "$LDFLAGS_LINE"
echo "$CPPFLAGS_LINE"
echo "$PKG_CONFIG_PATH_LINE"
echo "$PATH_LINE"
echo ""

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

PYTHON_VERSION="3.14"

echo "Installing Python $PYTHON_VERSION with pyenv"
pyenv install -s $PYTHON_VERSION
pyenv global $PYTHON_VERSION

echo "Installing uv"
pip install uv
uv pip install --system --upgrade pip
uv pip install --system requests ipython setuptools wheel spyder-kernels pyautogui

echo "Python $PYTHON_VERSION installation complete!"
