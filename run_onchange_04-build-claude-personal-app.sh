#!/bin/bash
# Build "Claude Personal.app": launches a second Claude Desktop instance with
# its own Electron user-data dir, so it holds a separate login (personal
# account). The default Claude.app instance keeps the work account.
set -euo pipefail

APP_DIR="$HOME/Applications"
APP="$APP_DIR/Claude Personal.app"
mkdir -p "$APP_DIR"

SRC="$(mktemp -d)/claude-personal.applescript"
cat > "$SRC" <<'EOF'
do shell script "open -n -a \"/Applications/Claude.app\" --args --user-data-dir=\"$HOME/Library/Application Support/Claude-Personal\" > /dev/null 2>&1 &"
EOF

rm -rf "$APP"
osacompile -o "$APP" "$SRC"

# Borrow the real Claude icon so the Dock tile isn't the generic applet
CLAUDE_ICNS="/Applications/Claude.app/Contents/Resources/electron.icns"
if [ -f "$CLAUDE_ICNS" ]; then
  cp "$CLAUDE_ICNS" "$APP/Contents/Resources/applet.icns"
  touch "$APP"
fi

echo "Built $APP"
