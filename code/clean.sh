#!/bin/bash

VERBOSE=false
log() { $VERBOSE && echo "$@"; return 0; }

# Help function
show_help() {
    echo "Usage: $(basename $0) [option] [-v]"
    echo "Options:"
    echo "  -d, --db       Clear only DBs"
    echo "  -a, --all      Clear everything (DBs and caches)"
    echo "  -v, --verbose  Show detailed output"
    echo "  -h, --help     Show this help message"
    echo ""
}

# Check if Cursor is running
check() {
    if pgrep -f "Cursor.app" > /dev/null || { [ -n "$CURSOR_SERVER" ] && tasklist.exe 2>/dev/null | grep -qi "cursor.exe"; }; then
        echo "⚠️  Please close Cursor"
        exit 1
    fi
}

CURSOR_SUPPORT="$HOME/Library/Application Support/Cursor"
CURSOR_SERVER=""
if uname -r | grep -qi wsl; then
    CURSOR_SUPPORT="/mnt/c/Users/User/AppData/Roaming/Cursor"
    CURSOR_SERVER="$HOME/.cursor-server/data/User"
fi

clean() {
    for dir in "$@"; do
        if [ -d "$dir" ]; then
            rm -rf "$dir"/*
            log "✅ Cleared $dir"
        fi
    done
}

clear() {
    check
    log "📝 Clearing DBs"
    local base="$HOME"
    [ -n "$CURSOR_SERVER" ] && base="/mnt/c/Users/User"
    local db="$base/.cursor/ai-tracking/ai-code-tracking.db"
    sqlite3 "$db" "SELECT 'DELETE FROM ' || name || ';' FROM sqlite_master WHERE type='table';" | sqlite3 "$db"
    log "✅ Cleared $db"
    sqlite3 "$CURSOR_SUPPORT/User/globalStorage/state.vscdb" "DELETE FROM cursorDiskKV;"
    log "✅ Cleared $CURSOR_SUPPORT/User/globalStorage/state.vscdb"
    clean "$HOME/.cursor/projects"
}

cache() {
    log "🗑️  Clearing caches"
    clean \
        "$CURSOR_SUPPORT/Cache" \
        "$CURSOR_SUPPORT/CachedData" \
        "$CURSOR_SUPPORT/CachedExtensionVSIXs" \
        "$CURSOR_SUPPORT/CachedProfilesData" \
        "$CURSOR_SUPPORT/Code Cache" \
        "$CURSOR_SUPPORT/Crashpad" \
        "$CURSOR_SUPPORT/GPUCache" \
        "$CURSOR_SUPPORT/User/History" \
        "$CURSOR_SUPPORT/User/workspaceStorage"
    [ -n "$CURSOR_SERVER" ] && clean "$CURSOR_SERVER/History" "$CURSOR_SERVER/workspaceStorage"
}

# Main script
ACTION=""
for arg in "$@"; do
    case $arg in -v|--verbose) VERBOSE=true;; *) ACTION="$arg";; esac
done

case "$ACTION" in
    -d|--db)
        clear
        ;;
    -a|--all)
        clear
        cache
        ;;
    -h|--help)
        show_help
        ;;
    *)
        echo "⚠️  Invalid option"
        show_help
        exit 1
        ;;
esac

log "✨ All done!"
