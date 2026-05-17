# Homebrew

## Brewfile

```bash
brew bundle          # install from Brewfile
brew bundle --verbose
brew bundle check    # verify all deps installed
brew bundle dump --force  # generate Brewfile from current installs
brew bundle cleanup       # show what would be uninstalled
brew bundle cleanup --force
```

## Install formulae

```bash
brew install act \
awscli \
azure-cli \
direnv \
docker-credential-helper \
gcc \
gh \
git \
helm \
imagemagick \
jq \
k9s \
kind \
kubecolor \
kubectx \
kubernetes-cli \
lolcat \
pgcli \
pomerium-cli \
postgresql@14 \
pyenv \
python@3.12 \
shellcheck \
starship \
tcl-tk \
tfenv \
tgenv \
tree \
zsh-autosuggestions \
notunes
```

## Install casks

```bash
brew install --cask aws-vault \
cursor \
zed \
font-ubuntu-mono-nerd-font \
hiddenbar
```

## Common commands

```bash
brew list                 # list installed formulae
brew list --cask          # list installed casks
brew tap                  # list taps
brew update && brew upgrade && brew cleanup
```

## Tap management

```bash
# find which tap a formula belongs to
brew info --json=v2 <formula> | jq -r '.formulae[0].tap // empty'

# find which tap a cask belongs to
brew info --json=v2 --cask <cask> | jq -r '.casks[0].tap // empty'

# list all formulae with their taps
brew info --json=v2 $(brew list --formula) \
  | jq -r '.formulae[] | "\(.name)\t\(.tap // "homebrew/core")"'

# list all casks with their taps
brew info --json=v2 --cask $(brew list --cask) \
  | jq -r '.casks[] | "\(.token)\t\(.tap // "homebrew/cask")"'

# inspect a tap
brew tap-info <user/tap>
brew search <user/tap>/
brew tap-info --json <user/tap> | jq
```

## Uninstall a versioned formula from a custom tap

```bash
brew uninstall <user/tap>/<formula>
brew unlink <user/tap>/<formula>   # if it complains about being linked
brew untap <user/tap>
brew cleanup
brew autoremove
```
