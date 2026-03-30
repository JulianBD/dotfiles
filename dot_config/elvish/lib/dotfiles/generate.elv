# generate.elv — Generate downstream configs from a theme palette
#
# Each generator takes a palette map (from palette:get) and produces
# the appropriate config file for its target application.
#
# Usage:
#   use dotfiles/generate
#   var p = (palette:get ef-autumn)
#   generate:ghostty $p ef-autumn
#   generate:sketchybar $p
#   generate:wallpaper $p

use str
use path

# Helper: look up a color key in palette with fallback
fn c {|palette key fallback|
  if (has-key $palette $key) {
    put $palette[$key]
  } else {
    put $fallback
  }
}

# Strip # prefix from hex color
fn hex {|color|
  str:trim-prefix $color '#'
}

# --- Ghostty theme file ---

fn ghostty {|palette name|
  var out = ~/.config/ghostty/themes/$name
  var bg = $palette[bg-main]
  var fg = $palette[fg-main]
  var cursor = (c $palette cursor $fg)

  # Map Prot's semantic colors to ANSI 16-color palette
  # Handles both ef/modus naming (red, green) and doric naming (fg-red, fg-green)
  var red     = (c $palette red (c $palette fg-red $fg))
  var green   = (c $palette green (c $palette fg-green $fg))
  var yellow  = (c $palette yellow (c $palette fg-yellow $fg))
  var blue    = (c $palette blue (c $palette fg-blue $fg))
  var magenta = (c $palette magenta (c $palette fg-magenta $fg))
  var cyan    = (c $palette cyan (c $palette fg-cyan $fg))

  var red-br     = (c $palette red-warmer $red)
  var green-br   = (c $palette green-warmer $green)
  var yellow-br  = (c $palette yellow-warmer $yellow)
  var blue-br    = (c $palette blue-warmer $blue)
  var magenta-br = (c $palette magenta-warmer $magenta)
  var cyan-br    = (c $palette cyan-warmer $cyan)

  var black    = (c $palette bg-dim (c $palette bg-shadow-subtle $bg))
  var white    = (c $palette fg-dim (c $palette fg-neutral $fg))
  var black-br = (c $palette bg-active (c $palette bg-neutral $black))
  var white-br = (c $palette fg-alt (c $palette fg-shadow-intense $fg))

  var sel-bg = (c $palette bg-region (c $palette bg-neutral (c $palette bg-shadow-intense $black)))
  var sel-fg = $fg

  printf "# Auto-generated from palette: %s\n" $name >$out
  printf "# Regenerate with: theme:apply %s\n" $name >>$out
  printf "background = %s\n" $bg >>$out
  printf "foreground = %s\n" $fg >>$out
  printf "cursor-color = %s\n" $cursor >>$out
  printf "selection-background = %s\n" $sel-bg >>$out
  printf "selection-foreground = %s\n" $sel-fg >>$out

  var i = 0
  for color [$black $red $green $yellow $blue $magenta $cyan $white $black-br $red-br $green-br $yellow-br $blue-br $magenta-br $cyan-br $white-br] {
    printf "palette = %d=%s\n" $i $color >>$out
    set i = (+ $i 1)
  }

  echo "Generated ghostty theme: "$out
}

# --- Sketchybar colors.sh ---

fn sketchybar {|palette|
  var out-sh = ~/.config/sketchybar/colors.sh
  var out-lua = ~/.config/sketchybar/colors.lua
  var bg = (hex $palette[bg-main])
  var fg = (hex $palette[fg-main])

  var p0  = (hex (c $palette bg-dim (c $palette bg-shadow-subtle $palette[bg-main])))
  var p1  = (hex (c $palette red (c $palette fg-red $palette[fg-main])))
  var p2  = (hex (c $palette green (c $palette fg-green $palette[fg-main])))
  var p3  = (hex (c $palette yellow (c $palette fg-yellow $palette[fg-main])))
  var p4  = (hex (c $palette blue (c $palette fg-blue $palette[fg-main])))
  var p5  = (hex (c $palette magenta (c $palette fg-magenta $palette[fg-main])))
  var p6  = (hex (c $palette cyan (c $palette fg-cyan $palette[fg-main])))
  var p7  = (hex (c $palette fg-dim (c $palette fg-neutral $palette[fg-main])))
  var p8  = (hex (c $palette bg-active (c $palette bg-neutral (c $palette bg-shadow-intense $palette[bg-main]))))
  var p9  = (hex (c $palette red-warmer $p1))
  var p10 = (hex (c $palette green-warmer $p2))
  var p11 = (hex (c $palette yellow-warmer $p3))
  var p12 = (hex (c $palette blue-warmer $p4))
  var p13 = (hex (c $palette magenta-warmer $p5))
  var p14 = (hex (c $palette cyan-warmer $p6))
  var p15 = $fg

  # Helper to write an export line
  var line = {|name prefix color|
    echo 'export '$name'='$prefix$color
  }

  {
    echo '#!/usr/bin/env bash'
    echo '# Auto-generated from theme palette — do not edit manually'
    echo '# Regenerate with: theme:apply'
    echo ''
    $line BAR_COLOR 0x00 000000
    $line TRANSPARENT 0x00 000000
    echo ''
    $line DEFAULT_ICON_COLOR 0xff $fg
    $line DEFAULT_LABEL_COLOR 0xff $fg
    echo ''
    $line BLACK 0xff $p0
    $line RED 0xff $p1
    $line GREEN 0xff $p2
    $line YELLOW 0xff $p3
    $line BLUE 0xff $p4
    $line MAGENTA 0xff $p5
    $line CYAN 0xff $p6
    $line WHITE 0xff $p7
    echo ''
    $line BRIGHT_BLACK 0xff $p8
    $line BRIGHT_RED 0xff $p9
    $line BRIGHT_GREEN 0xff $p10
    $line BRIGHT_YELLOW 0xff $p11
    $line BRIGHT_BLUE 0xff $p12
    $line BRIGHT_MAGENTA 0xff $p13
    $line BRIGHT_CYAN 0xff $p14
    $line BRIGHT_WHITE 0xff $p15
    echo ''
    $line GREY 0xff $p15
    $line GREY_TRANSP 0x11 $p15
    $line ACCENT 0xff $p5
    $line ACCENT_TRANSPARENT 0x44 $p5
    $line BRACKET_BG 0xff $bg
    $line BRACKET_BORDER 0x22 $fg
    echo ''
    $line TEXT_PRIMARY 0xff $fg
    $line TEXT_MUTED 0xff $p15
    echo ''
    $line SPACE_ACTIVE_COLOR 0xff $fg
    $line SPACE_ACTIVE_BG_COLOR 0x30 $fg
    $line SPACE_HIGHLIGHT_COLOR 0xff $fg
    $line SPACE_INACTIVE_COLOR 0xff $p15
    echo ''
    $line SPACE_GROUP1_COLOR 0xff $p4
    $line SPACE_GROUP1_BG 0x30 $p4
    $line SPACE_GROUP2_COLOR 0xff $p2
    $line SPACE_GROUP2_BG 0x30 $p2
    $line SPACE_GROUP3_COLOR 0xff $p5
    $line SPACE_GROUP3_BG 0x30 $p5
    echo ''
    $line FRONT_APP_LAYOUT_ICON_COLOR 0xff $p2
    $line FRONT_APP_LAYOUT_BG_COLOR 0x11 $p2
    echo ''
    $line CLOCK_COLOR 0xff $p4
    $line VOLUME_COLOR 0xff $p5
    echo ''
    $line BATTERY_COLOR_NORMAL 0xff $p1
    $line BATTERY_COLOR_WARNING 0xff $p3
    $line BATTERY_COLOR_LOW 0xff $p11
    $line BATTERY_COLOR_CRITICAL 0xff $p1
    $line BATTERY_COLOR_CHARGING 0xff $p2
  } >$out-sh

  # Also generate colors.lua for SbarLua
  var lua-line = {|name val|
    echo '  '$name' = '$val','
  }

  {
    echo '-- Auto-generated from theme palette — do not edit manually'
    echo '-- Regenerate with: theme:apply'
    echo 'return {'
    $lua-line bar_color       '0x00000000'
    $lua-line transparent     '0x00000000'
    $lua-line icon_color      '0xff'$fg
    $lua-line label_color     '0xff'$fg
    echo ''
    $lua-line black           '0xff'$p0
    $lua-line red             '0xff'$p1
    $lua-line green           '0xff'$p2
    $lua-line yellow          '0xff'$p3
    $lua-line blue            '0xff'$p4
    $lua-line magenta         '0xff'$p5
    $lua-line cyan            '0xff'$p6
    $lua-line white           '0xff'$p7
    echo ''
    $lua-line grey            '0xff'$p15
    $lua-line grey_transp     '0x11'$p15
    $lua-line accent          '0xff'$p5
    $lua-line accent_transp   '0x44'$p5
    $lua-line bracket_bg      '0xff'$bg
    $lua-line bracket_border  '0x22'$fg
    echo ''
    $lua-line text_primary    '0xff'$fg
    $lua-line text_muted      '0xff'$p15
    echo ''
    $lua-line space_active    '0xff'$fg
    $lua-line space_active_bg '0x30'$fg
    $lua-line space_inactive  '0xff'$p15
    echo ''
    $lua-line space_group1    '0xff'$p4
    $lua-line space_group1_bg '0x30'$p4
    $lua-line space_group2    '0xff'$p2
    $lua-line space_group2_bg '0x30'$p2
    $lua-line space_group3    '0xff'$p5
    $lua-line space_group3_bg '0x30'$p5
    echo ''
    $lua-line front_app_layout    '0xff'$p2
    $lua-line front_app_layout_bg '0x11'$p2
    echo ''
    $lua-line clock           '0xff'$p4
    $lua-line volume          '0xff'$p5
    echo ''
    $lua-line battery_normal   '0xff'$p1
    $lua-line battery_warning  '0xff'$p3
    $lua-line battery_low      '0xff'$p11
    $lua-line battery_critical '0xff'$p1
    $lua-line battery_charging '0xff'$p2
    echo '}'
  } >$out-lua

  echo "Generated "$out-sh" + "$out-lua

  # Restart sketchybar
  try { killall sketchybar 2>/dev/null } catch e { }
  sleep 0.5
  bash -c 'sketchybar &disown'
}

# --- Wallpaper ---

fn wallpaper {|palette|
  var bg = $palette[bg-main]
  var dir = ~/.local/share/wallpapers
  mkdir -p $dir

  # Get display resolutions via m-cli
  var displays = [(m display --status 2>/dev/null | rg 'Resolution:' | t 'm/(\d+) x (\d+)/' | t 'r/ x /x/')]

  if (== (count $displays) 0) {
    echo "Warning: could not detect display resolution" >&2
    return
  }

  var idx = 0
  for res $displays {
    var parts = [(str:split x $res)]
    var w = $parts[0]
    var h = $parts[1]
    var wp = $dir/wallpaper-$idx.jpg
    magick -size $w'x'$h 'xc:'$bg -quality 95 $wp
    echo "Generated wallpaper: "$w"x"$h" "$bg" → "$wp
    set idx = (+ $idx 1)
  }

  if (path:is-regular $dir/wallpaper-0.jpg) {
    m wallpaper --set $dir/wallpaper-0.jpg
    echo "Wallpaper set to "$bg
  }
}

# --- JankyBorders ---

fn borders {|palette|
  var out = ~/.config/borders/bordersrc
  mkdir -p ~/.config/borders
  var active = (hex (c $palette blue (c $palette fg-blue $palette[fg-main])))
  var inactive = (hex (c $palette bg-active (c $palette bg-dim $palette[bg-main])))
  {
    echo '#!/bin/bash'
    echo '# Auto-generated from theme palette — do not edit manually'
    echo '# Regenerate with: theme:apply'
    echo 'borders active_color=0xff'$active' inactive_color=0x44'$inactive' width=5.0 style=round hidpi=on'
  } >$out
  chmod +x $out
  # Live-update running borders instance
  try { e:borders active_color=0xff$active inactive_color=0x44$inactive width=5.0 style=round hidpi=on &disown } catch e { }
  echo "Generated "$out
}

# --- All ---

fn all {|palette name|
  ghostty $palette $name
  sketchybar $palette
  borders $palette
  wallpaper $palette
}
