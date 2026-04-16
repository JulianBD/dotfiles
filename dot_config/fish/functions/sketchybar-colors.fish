function sketchybar-colors --description "Generate sketchybar colors.sh from current ghostty theme"
    set config ~/.config/sketchybar/colors.sh
    set ghostty /Applications/Ghostty.app/Contents/MacOS/ghostty

    set raw ($ghostty +show-config 2>/dev/null | rg "^(background|foreground|palette)")

    if test (count $raw) -eq 0
        echo "Could not read ghostty colors"
        return 1
    end

    set bg (printf '%s\n' $raw | rg "^background" | t 'm/[0-9a-f]{6}/@0')
    set fg (printf '%s\n' $raw | rg "^foreground" | t 'm/[0-9a-f]{6}/@0')

    for i in (seq 0 15)
        set -g "p$i" (printf '%s\n' $raw | rg "^palette = $i=" | t 'm/[0-9a-f]{6}/@0')
    end

    printf '#!/usr/bin/env bash
# Auto-generated from ghostty theme — do not edit manually
# Regenerate with: sketchybar-colors

export BAR_COLOR=0x00000000
export TRANSPARENT=0x00000000

export DEFAULT_ICON_COLOR=0xff%s
export DEFAULT_LABEL_COLOR=0xff%s

export BLACK=0xff%s
export RED=0xff%s
export GREEN=0xff%s
export YELLOW=0xff%s
export BLUE=0xff%s
export MAGENTA=0xff%s
export CYAN=0xff%s
export WHITE=0xff%s

export BRIGHT_BLACK=0xff%s
export BRIGHT_RED=0xff%s
export BRIGHT_GREEN=0xff%s
export BRIGHT_YELLOW=0xff%s
export BRIGHT_BLUE=0xff%s
export BRIGHT_MAGENTA=0xff%s
export BRIGHT_CYAN=0xff%s
export BRIGHT_WHITE=0xff%s

export GREY=0xff%s
export GREY_TRANSP=0x11%s
export ACCENT=0xff%s
export ACCENT_TRANSPARENT=0x44%s
export BRACKET_BG=0xff%s
export BRACKET_BORDER=0x22%s

export TEXT_PRIMARY=0xff%s
export TEXT_MUTED=0xff%s

export SPACE_ACTIVE_COLOR=0xff%s
export SPACE_ACTIVE_BG_COLOR=0x30%s
export SPACE_HIGHLIGHT_COLOR=0xff%s
export SPACE_INACTIVE_COLOR=0xff%s

export SPACE_GROUP1_COLOR=0xff%s
export SPACE_GROUP1_BG=0x30%s
export SPACE_GROUP2_COLOR=0xff%s
export SPACE_GROUP2_BG=0x30%s
export SPACE_GROUP3_COLOR=0xff%s
export SPACE_GROUP3_BG=0x30%s

export FRONT_APP_LAYOUT_ICON_COLOR=0xff%s
export FRONT_APP_LAYOUT_BG_COLOR=0x11%s

export CLOCK_COLOR=0xff%s
export VOLUME_COLOR=0xff%s

export BATTERY_COLOR_NORMAL=0xff%s
export BATTERY_COLOR_WARNING=0xff%s
export BATTERY_COLOR_LOW=0xff%s
export BATTERY_COLOR_CRITICAL=0xff%s
export BATTERY_COLOR_CHARGING=0xff%s
' \
    $fg $fg \
    $p0 $p1 $p2 $p3 $p4 $p5 $p6 $p7 \
    $p8 $p9 $p10 $p11 $p12 $p13 $p14 $p15 \
    $p15 $p15 $p5 $p5 $bg $fg \
    $fg $p15 \
    $fg $fg $fg $p15 \
    $p4 $p4 $p2 $p2 $p5 $p5 \
    $p2 $p2 \
    $p4 $p5 \
    $p1 $p3 $p11 $p1 $p2 \
    > $config

    echo "Generated $config from ghostty theme"

    # SbarLua: `sketchybar --reload` doesn't clear old items; use brew services.
    if type -q brew
        brew services restart sketchybar >/dev/null 2>&1
    end
end
