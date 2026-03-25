#!/bin/bash
# Set default browser to Helium
set -euo pipefail

eval "$($([ -f /opt/homebrew/bin/brew ] && echo /opt/homebrew/bin/brew || echo /usr/local/bin/brew) shellenv)"

if ! command -v m &>/dev/null; then
    echo "m-cli not installed yet, skipping default browser setup"
    exit 0
fi

echo "Setting default browser to Helium..."
m defaultbrowser com.nickvision.helium
