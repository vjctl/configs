# Starship

```bash
cp ~/.config/starship.toml starship/

cp starship/starship.toml ~/.config/starship.toml
```

## Installation

1. Install Starship:
```bash
brew install starship

# official install script
curl -sS https://starship.rs/install.sh | sh
```

2. Add to shell configuration (already included in .zshrc):
```bash
# Add to ~/.zshrc
echo 'eval "$(starship init zsh)"' >> ~/.zshrc
```
