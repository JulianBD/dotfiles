#!/bin/bash
# Apply current theme to all downstream configs via elvish
set -euo pipefail

eval "$($([ -f /opt/homebrew/bin/brew ] && echo /opt/homebrew/bin/brew || echo /usr/local/bin/brew) shellenv)"

if ! command -v elvish &>/dev/null; then
    echo "elvish not installed yet, skipping theme apply"
    exit 0
fi

# Only apply if a theme is currently set
CURRENT_THEME_FILE="$HOME/.config/dotfiles/current-theme"
if [ ! -f "$CURRENT_THEME_FILE" ]; then
    echo "No theme set yet, skipping theme apply"
    exit 0
fi

THEME=$(cat "$CURRENT_THEME_FILE" | tr -d '[:space:]')
echo "Applying theme: $THEME"
elvish -c "use dotfiles/theme; theme:apply $THEME"
