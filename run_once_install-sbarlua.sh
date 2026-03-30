#!/bin/bash
set -euo pipefail

if [ -f "$HOME/.local/share/sketchybar_lua/sketchybar.so" ]; then
  echo "SbarLua already installed"
  exit 0
fi

echo "Installing SbarLua..."
git clone https://github.com/FelixKratz/SbarLua.git /tmp/SbarLua
cd /tmp/SbarLua
make install
rm -rf /tmp/SbarLua
echo "SbarLua installed"
