#!/bin/sh

source "$CONFIG_DIR/colors.sh"

sketchybar --set "$NAME" label="$(date '+%b %d %I:%M %p')" icon.color="$CLOCK_COLOR" label.color="$CLOCK_COLOR"
