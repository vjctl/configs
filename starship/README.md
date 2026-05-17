# Starship Prompt Configuration

This directory contains configuration for the [Starship](https://starship.rs/) cross-shell prompt.

## File Locations

The configuration files are stored in:
```bash
~/.config/starship.toml    # Main configuration file
```

## Files

### starship.toml
- **Purpose**: Customizes the appearance and behavior of the Starship prompt
- **Export Command**:
```bash
# Export current configuration
cp ~/.config/starship.toml ./starship.toml
```
- **Import Command**:
```bash
# Create config directory if it doesn't exist
mkdir -p ~/.config

# Copy configuration
cp ./starship.toml ~/.config/starship.toml
```

## Installation

1. Install Starship:
```bash
# Using Homebrew (already included in Brewfile)
brew install starship

# Or using the official install script
curl -sS https://starship.rs/install.sh | sh
```

2. Add to shell configuration (already included in .zshrc):
```bash
# Add to ~/.zshrc
eval "$(starship init zsh)"
```

## Configuration Sections

The `starship.toml` includes customizations for:

- Prompt format and styling
- Git status and branch information
- Python environment (pyenv, virtualenv)
- Node.js version (via nvm)
- Kubernetes context and namespace
- AWS profile
- Command duration
- Shell status
- Directory truncation
- Time format

## Customization

To modify the prompt:

1. Edit `starship.toml`
2. Reference the [Starship Configuration Guide](https://starship.rs/config/)
3. Test changes in a new terminal window
4. Export updated configuration using the command above

## Common Customizations

### Change Prompt Symbol
```toml
[character]
success_symbol = "[➜](bold green)"
error_symbol = "[➜](bold red)"
```

### Customize Directory Display
```toml
[directory]
truncation_length = 3
truncate_to_repo = true
```

### Modify Git Information
```toml
[git_branch]
symbol = "🌱 "
truncation_length = 4
truncation_symbol = ""
```

### Configure Kubernetes Display
```toml
[kubernetes]
format = 'on [⛵ $context \($namespace\)](dimmed green) '
disabled = false
```

## Debugging

If the prompt isn't displaying correctly:

1. Check shell integration:
```bash
echo $STARSHIP_SHELL
```

2. Verify configuration:
```bash
starship explain
```

3. Print debug information:
```bash
STARSHIP_LOG=trace starship explain
```

## Updating

To update Starship:
```bash
# Using Homebrew
brew upgrade starship

# Using the install script
curl -sS https://starship.rs/install.sh | sh
```

## Resources

- [Official Documentation](https://starship.rs/guide/)
- [Configuration Reference](https://starship.rs/config/)
- [Presets Gallery](https://starship.rs/presets/)
- [Advanced Configuration](https://starship.rs/advanced-config/) 