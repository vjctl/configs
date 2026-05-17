## Configurations
```bash
cp ~/.config/zed/*.json zed/

cp zed/*.json ~/.config/zed/
```
```powershell
cp $env:APPDATA\Zed\*.json zed/

cp zed\*.json $env:APPDATA\Zed\
```

## Extensions
```
~/Library/Application Support/Zed/extensions
~/.local/share/zed/extensions/installed
%LOCALAPPDATA%\Zed\extensions
```

## Reauth

```powershell
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\Zed"
Remove-Item -Recurse -Force "$env:APPDATA\Zed"
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\github-copilot"

wsl -e bash -c "sudo apt-get update -qq && sudo apt-get install -y wslu 2>&1 | tail -5"
wsl -e bash -c "rm -rf ~/.local/share/zed ~/.config/zed ~/.copilot ~/.zed_server ~/.config/github-copilot'"
wsl -e bash -c "grep -n 'BROWSER' ~/.zshrc 2>/dev/null"
wsl -e bash -c "echo 'export BROWSER=wslview' >> ~/.zshrc"
rm -rf ~/.copilot/session-state/*
rm -rf ~/.cusor/projects/* ~/.cusor/chats/* ~/.cursor/ai*/*.db

```

```bash
sudo apt install libsecret-tools
secret-tool clear service cursor-access-token account cursor-user
secret-tool clear service cursor-refresh-token account cursor-user
ls -la ~/.local/share/zed/external_agents/
```

```zsh
security delete-generic-password -s "cursor-access-token" -a "cursor-user"
security delete-generic-password -s "cursor-refresh-token" -a "cursor-user"
```
