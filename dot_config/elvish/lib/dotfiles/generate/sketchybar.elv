use str
use path
use dotfiles/generate/common

fn write {|palette|
  var out-sh = ~/.config/sketchybar/colors.sh
  var out-lua = ~/.config/sketchybar/colors.lua
  var bg = (common:hex $palette[bg-main])
  var fg = (common:hex $palette[fg-main])

  var p0  = (common:hex (common:c $palette bg-dim (common:c $palette bg-shadow-subtle $palette[bg-main])))
  var p1  = (common:hex (common:c $palette red (common:c $palette fg-red $palette[fg-main])))
  var p2  = (common:hex (common:c $palette green (common:c $palette fg-green $palette[fg-main])))
  var p3  = (common:hex (common:c $palette yellow (common:c $palette fg-yellow $palette[fg-main])))
  var p4  = (common:hex (common:c $palette blue (common:c $palette fg-blue $palette[fg-main])))
  var p5  = (common:hex (common:c $palette magenta (common:c $palette fg-magenta $palette[fg-main])))
  var p6  = (common:hex (common:c $palette cyan (common:c $palette fg-cyan $palette[fg-main])))
  var p7  = (common:hex (common:c $palette fg-dim (common:c $palette fg-neutral $palette[fg-main])))
  var p8  = (common:hex (common:c $palette bg-active (common:c $palette bg-neutral (common:c $palette bg-shadow-intense $palette[bg-main]))))
  var p9  = (common:hex (common:c $palette red-warmer $p1))
  var p10 = (common:hex (common:c $palette green-warmer $p2))
  var p11 = (common:hex (common:c $palette yellow-warmer $p3))
  var p12 = (common:hex (common:c $palette blue-warmer $p4))
  var p13 = (common:hex (common:c $palette magenta-warmer $p5))
  var p14 = (common:hex (common:c $palette cyan-warmer $p6))
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
    $line SPACE_GROUP4_COLOR 0xff $p6
    $line SPACE_GROUP4_BG 0x30 $p6
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
    $lua-line space_group4    '0xff'$p6
    $lua-line space_group4_bg '0x30'$p6
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

  # Reload sketchybar. SbarLua holds a long-running Lua process as the rc
  # entry point; `sketchybar --reload` re-executes the script but doesn't
  # clear old items, so you end up with duplicates stacked on stale ones.
  # The only clean reload under brew services is `brew services restart`.
  if (has-external brew) {
    try { brew services restart sketchybar >/dev/null 2>&1 } catch e { }
  }
}
