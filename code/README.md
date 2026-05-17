# IDE Configuration

This directory contains configuration files for the IDE

## Initial Setup

On macOS, you may need to code sign the application before using it. Run the following command:
```bash
codesign --force --deep --sign - /Applications/Cursor.app
```

## File Locations

The configuration files are stored in:
```bash
~/Library/Application Support/Cursor/User/
```

## Files

### settings.json
- **Purpose**: IDE settings including theme, font, and editor preferences
- **Export Command**:
```bash
cp ~/Library/Application\ Support/Cursor/User/settings.json ./settings.json
```
- **Import Command**:
```bash
cp ./settings.json ~/Library/Application\ Support/Cursor/User/settings.json
```

### keybindings.json
- **Purpose**: Custom keyboard shortcuts
- **Export Command**:
```bash
cp ~/Library/Application\ Support/Cursor/User/keybindings.json ./keybindings.json
```
- **Import Command**:
```bash
cp ./keybindings.json ~/Library/Application\ Support/Cursor/User/keybindings.json
```

### extensions.json
- **Purpose**: List of recommended extensions
- **Generate Command**:
```bash
cursor --list-extensions > extensions.txt
# Then manually format into extensions.json
```
- **Install Extensions**:
```bash
# Install extensions from the recommendations list in extensions.json
# Can be installed through the Extensions panel (Cmd+Shift+X)
```

### tasks.json
- **Purpose**: Custom task configurations
- **Export Command**:
```bash
cp ~/Library/Application\ Support/Cursor/User/tasks.json ./tasks.json
```
- **Import Command**:
```bash
cp ./tasks.json ~/Library/Application\ Support/Cursor/User/tasks.json
```

### clean.sh
- **Purpose**: Script to clean chat and cache
- **Usage**:
  ```bash
  ./clean.sh --help
  ```
## Bulk Operations

### Export All Configurations
```bash
# Create directory if it doesn't exist
mkdir -p cursor

# Copy all configuration files
cp ~/Library/Application\ Support/Cursor/User/settings.json ./settings.json
cp ~/Library/Application\ Support/Cursor/User/keybindings.json ./keybindings.json
cp ~/Library/Application\ Support/Cursor/User/tasks.json ./tasks.json
cursor --list-extensions > extensions.txt
```

### Import All Configurations
```bash
# Create directory if it doesn't exist
mkdir -p ~/Library/Application\ Support/Cursor/User/

# Copy all configuration files
cp ./settings.json ~/Library/Application\ Support/Cursor/User/settings.json
cp ./keybindings.json ~/Library/Application\ Support/Cursor/User/keybindings.json
cp ./tasks.json ~/Library/Application\ Support/Cursor/User/tasks.json
```
