# Python Installation (macOS)

This guide describes how to install Python on macOS using Homebrew and pyenv

## Quick Install

```bash
bash install_python.sh
```

This script will:
- Install Homebrew dependencies (`tcl-tk` and `pyenv`)
- Set up the necessary environment variables for building Python with `tcl-tk` support
- Initialize `pyenv`
- Install Python 3.12 (customizable in the script)
- Set the installed Python version as global
- Upgrade `pip` and install useful Python packages (`uv`, `requests`, `ipython`, `setuptools`, `wheel`, `spyder-kernels`)
