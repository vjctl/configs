# Homebrew

```bash
brew bundle               # install from Brewfile
brew bundle --verbose
brew bundle check         # verify all deps installed
brew bundle dump --force  # generate Brewfile from current installs
brew bundle cleanup       # show what would be uninstalled
brew bundle cleanup --force
brew list                 # list installed formulae
brew list --cask          # list installed casks
brew tap                  # list taps
brew update && brew upgrade && brew cleanup

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

brew uninstall <user/tap>/<formula>
brew unlink <user/tap>/<formula>
brew untap <user/tap>
brew cleanup
brew autoremove
```
