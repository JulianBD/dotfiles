#!/usr/bin/env bash

source "$CONFIG_DIR/plugins/icon_map.sh"
source "$CONFIG_DIR/colors.sh"

SID="$1"

# Determine color group
case "$SID" in
  [1-4]) ACTIVE_COLOR=$SPACE_GROUP1_COLOR; ACTIVE_BG=$SPACE_GROUP1_BG ;;
  [5-8]) ACTIVE_COLOR=$SPACE_GROUP2_COLOR; ACTIVE_BG=$SPACE_GROUP2_BG ;;
  *)     ACTIVE_COLOR=$SPACE_GROUP3_COLOR; ACTIVE_BG=$SPACE_GROUP3_BG ;;
esac

# Build app icon string
apps=$(aerospace list-windows --workspace "$SID" 2>/dev/null | awk -F' \\| ' '{print $2}' | sort -u)

icon_string=""
if [ -n "$apps" ]; then
  for app in $apps; do
    __icon_map "$app"
    if [ "$icon_result" != ":default:" ]; then
      icon_string+="$icon_result"
    fi
  done
fi

# Set content: app icons OR workspace number
if [ -n "$icon_string" ]; then
  sketchybar --set $NAME \
    icon="$icon_string" \
    icon.font="sketchybar-app-font:Regular:14.0" \
    icon.padding_left=6 \
    icon.padding_right=6
else
  sketchybar --set $NAME \
    icon="$SID" \
    icon.font="SF Pro:Medium:12.0" \
    icon.padding_left=10 \
    icon.padding_right=10
fi

# Highlight focused workspace with group color
if [ "$SID" = "$FOCUSED_WORKSPACE" ]; then
  sketchybar --set $NAME \
    background.color=$ACTIVE_BG \
    icon.color=$ACTIVE_COLOR
else
  sketchybar --set $NAME \
    background.color=$GREY_TRANSP \
    icon.color=$TEXT_MUTED
fi
