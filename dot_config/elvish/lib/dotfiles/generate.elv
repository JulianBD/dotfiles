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

# --- Helix theme ---

fn helix {|palette name|
  var dir = ~/.config/helix/themes
  mkdir -p $dir
  var out = $dir/prot-current.toml

  var bg = $palette[bg-main]
  var fg = $palette[fg-main]
  var cursor = (c $palette cursor $fg)

  # Semantic colors (ef/modus: red, doric: fg-red)
  var red     = (c $palette red (c $palette fg-red $fg))
  var green   = (c $palette green (c $palette fg-green $fg))
  var yellow  = (c $palette yellow (c $palette fg-yellow $fg))
  var blue    = (c $palette blue (c $palette fg-blue $fg))
  var magenta = (c $palette magenta (c $palette fg-magenta $fg))
  var cyan    = (c $palette cyan (c $palette fg-cyan $fg))

  # Warmer/cooler variants
  var red-w     = (c $palette red-warmer $red)
  var green-w   = (c $palette green-warmer $green)
  var yellow-w  = (c $palette yellow-warmer $yellow)
  var blue-w    = (c $palette blue-warmer $blue)
  var magenta-w = (c $palette magenta-warmer $magenta)
  var cyan-w    = (c $palette cyan-warmer $cyan)
  var magenta-cool = (c $palette magenta-cooler $magenta)

  # Background shades
  var bg-dim    = (c $palette bg-dim (c $palette bg-shadow-subtle $bg))
  var bg-active = (c $palette bg-active (c $palette bg-neutral $bg-dim))
  var bg-popup  = (c $palette bg-popup (c $palette bg-shadow-subtle $bg-dim))
  var bg-hl     = (c $palette bg-hl-line (c $palette bg-shadow-subtle $bg-dim))
  var bg-region = (c $palette bg-region (c $palette bg-neutral (c $palette bg-shadow-intense $bg-dim)))

  # Foreground shades
  var fg-dim = (c $palette fg-dim (c $palette fg-neutral $fg))
  var fg-alt = (c $palette fg-alt (c $palette fg-shadow-intense $fg))

  # Diff colors
  var bg-added   = (c $palette bg-added (c $palette bg-green $bg))
  var bg-removed = (c $palette bg-removed (c $palette bg-red $bg))
  var bg-changed = (c $palette bg-changed (c $palette bg-yellow $bg))
  var fg-added   = (c $palette fg-added $green)
  var fg-removed = (c $palette fg-removed $red)

  # Statusline bg
  var bg-mode = (c $palette bg-mode-line-active $bg-active)

  {
    echo '# Auto-generated from palette: '$name
    echo '# Regenerate with: theme:apply '$name
    echo ''

    # --- Syntax scopes (Prot-faithful mapping) ---
    # keyword → magenta-cooler, function → magenta, string → blue-warmer,
    # type → cyan, variable → cyan-warmer, property → blue, constant → blue
    echo '"comment" = { fg = "fg_dim", modifiers = ["italic"] }'
    echo '"constant" = "blue"'
    echo '"constant.character" = "blue_w"'
    echo '"constant.character.escape" = "blue_w"'
    echo '"constant.numeric" = "fg"'
    echo '"constant.builtin" = "blue"'
    echo '"string" = "blue_w"'
    echo '"string.regexp" = "magenta_cool"'
    echo '"string.special" = "blue_w"'
    echo '"string.special.symbol" = "blue_w"'
    echo '"type" = "cyan"'
    echo '"type.builtin" = "cyan_w"'
    echo '"type.enum.variant" = "cyan"'
    echo '"constructor" = "magenta"'
    echo '"function" = "magenta"'
    echo '"function.builtin" = "magenta_w"'
    echo '"function.macro" = "magenta_cool"'
    echo '"keyword" = "magenta_cool"'
    echo '"keyword.control.import" = "magenta_cool"'
    echo '"operator" = "magenta"'
    echo '"label" = "cyan"'
    echo '"namespace" = "cyan_w"'
    echo '"module" = "cyan_w"'
    echo '"tag" = "blue"'
    echo '"attribute" = "red"'
    echo '"variable" = "cyan_w"'
    echo '"variable.builtin" = "magenta_cool"'
    echo '"variable.other.member" = "blue"'
    echo '"variable.parameter" = "cyan_w"'
    echo '"punctuation" = "fg"'
    echo '"special" = "red"'
    echo '"annotation" = "fg_dim"'
    echo ''

    # --- Markup ---
    echo '"markup.heading" = { fg = "fg_dim", modifiers = ["bold"] }'
    echo '"markup.bold" = { modifiers = ["bold"] }'
    echo '"markup.italic" = { modifiers = ["italic"] }'
    echo '"markup.strikethrough" = { modifiers = ["crossed_out"] }'
    echo '"markup.link.text" = { fg = "cyan_w", modifiers = ["italic"] }'
    echo '"markup.link.url" = { fg = "blue_w", modifiers = ["underlined"] }'
    echo '"markup.raw" = "magenta"'
    echo ''

    # --- Diagnostics ---
    echo '"diagnostic" = { underline = { color = "yellow", style = "curl" } }'
    echo '"diagnostic.error" = { underline = { color = "red", style = "curl" } }'
    echo '"diagnostic.warning" = { underline = { color = "yellow_w", style = "curl" } }'
    echo '"diagnostic.info" = { underline = { color = "blue", style = "curl" } }'
    echo '"diagnostic.hint" = { underline = { color = "cyan", style = "curl" } }'
    echo '"error" = "red"'
    echo '"warning" = "yellow_w"'
    echo '"info" = "blue"'
    echo '"hint" = "cyan"'
    echo ''

    # --- Diff ---
    echo '"diff.plus" = "fg_added"'
    echo '"diff.minus" = "fg_removed"'
    echo '"diff.delta" = "yellow"'
    echo ''

    # --- UI ---
    echo '"ui.background" = { bg = "bg" }'
    echo '"ui.text" = "fg"'
    echo '"ui.text.focus" = { fg = "green", bg = "bg_dim" }'
    echo '"ui.text.directory" = "blue"'
    echo ''
    echo '"ui.cursor" = { fg = "bg", bg = "fg_dim" }'
    echo '"ui.cursor.primary" = { fg = "bg", bg = "cursor" }'
    echo '"ui.cursor.insert" = { fg = "bg", bg = "green" }'
    echo '"ui.cursor.select" = { fg = "bg", bg = "yellow" }'
    echo '"ui.cursor.match" = { fg = "fg", bg = "bg_active" }'
    echo '"ui.cursor.primary.insert" = { fg = "bg", bg = "green_w" }'
    echo '"ui.cursor.primary.normal" = { fg = "bg", bg = "cursor" }'
    echo '"ui.cursor.primary.select" = { fg = "bg", bg = "yellow_w" }'
    echo ''
    echo '"ui.cursorline" = { bg = "bg_dim" }'
    echo '"ui.cursorline.primary" = { bg = "bg_hl" }'
    echo ''
    echo '"ui.linenr" = "fg_dim"'
    echo '"ui.linenr.selected" = { fg = "fg", modifiers = ["bold"] }'
    echo ''
    echo '"ui.selection" = { bg = "bg_region" }'
    echo '"ui.selection.primary" = { bg = "bg_active" }'
    echo ''
    echo '"ui.statusline" = { fg = "fg", bg = "bg_mode" }'
    echo '"ui.statusline.inactive" = { fg = "fg_dim", bg = "bg_dim" }'
    echo '"ui.statusline.insert" = { fg = "bg", bg = "green", modifiers = ["bold"] }'
    echo '"ui.statusline.normal" = { fg = "bg", bg = "blue", modifiers = ["bold"] }'
    echo '"ui.statusline.select" = { fg = "bg", bg = "yellow", modifiers = ["bold"] }'
    echo ''
    echo '"ui.popup" = { bg = "bg_popup" }'
    echo '"ui.window" = { bg = "bg_dim" }'
    echo '"ui.help" = { bg = "bg_popup", fg = "fg" }'
    echo '"ui.menu" = { fg = "fg", bg = "bg_popup" }'
    echo '"ui.menu.selected" = { fg = "green", bg = "bg_dim", modifiers = ["bold"] }'
    echo '"ui.menu.scroll" = { fg = "fg_dim", bg = "bg_popup" }'
    echo ''
    echo '"ui.bufferline" = { fg = "fg_dim", bg = "bg_dim" }'
    echo '"ui.bufferline.active" = { fg = "bg", bg = "blue" }'
    echo '"ui.bufferline.background" = { bg = "bg_dim" }'
    echo ''
    echo '"ui.virtual.inlay-hint" = "fg_dim"'
    echo '"ui.virtual.jump-label" = { fg = "magenta_w", modifiers = ["bold"] }'
    echo '"ui.virtual.ruler" = { bg = "bg_dim" }'
    echo '"ui.virtual.whitespace" = "bg_active"'
    echo '"ui.virtual.wrap" = "bg_active"'
    echo ''

    # --- Palette ---
    echo '[palette]'
    echo 'bg = "'$bg'"'
    echo 'fg = "'$fg'"'
    echo 'cursor = "'$cursor'"'
    echo 'fg_dim = "'$fg-dim'"'
    echo 'fg_alt = "'$fg-alt'"'
    echo 'bg_dim = "'$bg-dim'"'
    echo 'bg_active = "'$bg-active'"'
    echo 'bg_popup = "'$bg-popup'"'
    echo 'bg_hl = "'$bg-hl'"'
    echo 'bg_region = "'$bg-region'"'
    echo 'bg_mode = "'$bg-mode'"'
    echo 'red = "'$red'"'
    echo 'green = "'$green'"'
    echo 'yellow = "'$yellow'"'
    echo 'blue = "'$blue'"'
    echo 'magenta = "'$magenta'"'
    echo 'cyan = "'$cyan'"'
    echo 'red_w = "'$red-w'"'
    echo 'green_w = "'$green-w'"'
    echo 'yellow_w = "'$yellow-w'"'
    echo 'blue_w = "'$blue-w'"'
    echo 'magenta_w = "'$magenta-w'"'
    echo 'cyan_w = "'$cyan-w'"'
    echo 'magenta_cool = "'$magenta-cool'"'
    echo 'fg_added = "'$fg-added'"'
    echo 'fg_removed = "'$fg-removed'"'
    echo 'bg_added = "'$bg-added'"'
    echo 'bg_removed = "'$bg-removed'"'
    echo 'bg_changed = "'$bg-changed'"'
  } >$out

  echo "Generated helix theme: "$out
}

# --- Zed theme ---
# Based on Zed's gruvbox theme structure (explicit font_style/font_weight, RGBA hex, full token set)

fn zed {|palette name variant|
  var dir = ~/.config/zed/themes
  mkdir -p $dir
  var out = $dir/prot-current.json

  var bg = $palette[bg-main]
  var fg = $palette[fg-main]
  var cursor = (c $palette cursor $fg)

  # Semantic colors
  var red     = (c $palette red (c $palette fg-red $fg))
  var green   = (c $palette green (c $palette fg-green $fg))
  var yellow  = (c $palette yellow (c $palette fg-yellow $fg))
  var blue    = (c $palette blue (c $palette fg-blue $fg))
  var magenta = (c $palette magenta (c $palette fg-magenta $fg))
  var cyan    = (c $palette cyan (c $palette fg-cyan $fg))

  var red-w     = (c $palette red-warmer $red)
  var green-w   = (c $palette green-warmer $green)
  var yellow-w  = (c $palette yellow-warmer $yellow)
  var blue-w    = (c $palette blue-warmer $blue)
  var magenta-w = (c $palette magenta-warmer $magenta)
  var cyan-w    = (c $palette cyan-warmer $cyan)

  # Cooler variants (Prot uses magenta-cooler heavily for keywords)
  var red-cool     = (c $palette red-cooler $red)
  var magenta-cool = (c $palette magenta-cooler $magenta)
  var cyan-cool    = (c $palette cyan-cooler $cyan)

  # Faint variants
  var red-f     = (c $palette red-faint $red)
  var green-f   = (c $palette green-faint $green)
  var cyan-f    = (c $palette cyan-faint $cyan)
  var blue-f    = (c $palette blue-faint $blue)
  var magenta-f = (c $palette magenta-faint $magenta)

  # Background shades
  var bg-dim    = (c $palette bg-dim (c $palette bg-shadow-subtle $bg))
  var bg-active = (c $palette bg-active (c $palette bg-neutral $bg-dim))
  var bg-alt    = (c $palette bg-alt $bg-dim)
  var bg-popup  = (c $palette bg-popup (c $palette bg-shadow-subtle $bg-dim))
  var bg-hl     = (c $palette bg-hl-line (c $palette bg-shadow-subtle $bg-dim))
  var bg-region = (c $palette bg-region (c $palette bg-neutral (c $palette bg-shadow-intense $bg-dim)))
  var bg-hover  = (c $palette bg-hover (c $palette bg-accent $bg-active))
  var bg-mode   = (c $palette bg-mode-line-active $bg-active)
  var fg-mode   = (c $palette fg-mode-line-active $fg)
  var border-c  = (c $palette border $bg-active)

  # Foreground shades
  var fg-dim = (c $palette fg-dim (c $palette fg-neutral $fg))
  var fg-alt = (c $palette fg-alt (c $palette fg-shadow-intense $fg))

  # Diff/VCS backgrounds
  var bg-added   = (c $palette bg-added (c $palette bg-green $bg))
  var bg-removed = (c $palette bg-removed (c $palette bg-red $bg))
  var bg-changed = (c $palette bg-changed (c $palette bg-yellow $bg))

  # Subtle/intense bg variants
  var bg-blue-subtle    = (c $palette bg-blue-subtle (c $palette bg-blue $bg-dim))
  var bg-red-subtle     = (c $palette bg-red-subtle (c $palette bg-red $bg-dim))
  var bg-yellow-intense = (c $palette bg-yellow-intense (c $palette bg-yellow $bg-active))
  var bg-completion     = (c $palette bg-completion $bg-popup)

  # Element & inactive surfaces
  var element = (c $palette bg-inactive $bg-dim)

  # ANSI terminal colors (bright variants)
  var black-br   = (c $palette bg-active (c $palette bg-neutral $bg-dim))
  var white-br   = (c $palette fg-alt (c $palette fg-shadow-intense $fg))

  # Helper: hex color -> RGBA with ff alpha
  var ff = {|color|
    put $color'ff'
  }
  # Helper: hex color -> RGBA with custom alpha
  var a = {|color alpha|
    put $color$alpha
  }

  {
    echo '{'
    echo '  "author": "Auto-generated from Prot palette",'
    echo '  "name": "Prot Current",'
    echo '  "themes": ['
    echo '    {'
    echo '      "appearance": "'$variant'",'
    echo '      "name": "Prot Current",'
    echo '      "style": {'

    # --- Accents ---
    echo '        "accents": ["'($ff $red)'", "'($ff $green)'", "'($ff $yellow)'", "'($ff $blue)'", "'($ff $magenta)'", "'($ff $cyan)'", "'($ff $red-w)'"],'

    # --- Borders ---
    echo '        "border": "'($ff $border-c)'",'
    echo '        "border.variant": "'($ff $bg-active)'",'
    echo '        "border.focused": "'($ff $blue-f)'",'
    echo '        "border.selected": "'($ff $blue-f)'",'
    echo '        "border.transparent": "#00000000",'
    echo '        "border.disabled": "'($ff $bg-active)'",'

    # --- Surfaces ---
    echo '        "elevated_surface.background": "'($ff $bg-dim)'",'
    echo '        "surface.background": "'($ff $bg-dim)'",'
    echo '        "background": "'($ff $bg-active)'",'
    echo '        "element.background": "'($ff $bg-dim)'",'
    echo '        "element.hover": "'($ff $bg-active)'",'
    echo '        "element.active": "'($ff $bg-hover)'",'
    echo '        "element.selected": "'($ff $bg-hover)'",'
    echo '        "element.disabled": "'($ff $bg-dim)'",'
    echo '        "drop_target.background": "'($a $blue-w 80)'",'

    # --- Ghost elements ---
    echo '        "ghost_element.background": "#00000000",'
    echo '        "ghost_element.hover": "'($ff $bg-active)'",'
    echo '        "ghost_element.active": "'($ff $bg-hover)'",'
    echo '        "ghost_element.selected": "'($ff $bg-hover)'",'
    echo '        "ghost_element.disabled": "'($ff $bg-dim)'",'

    # --- Text ---
    echo '        "text": "'($ff $fg)'",'
    echo '        "text.muted": "'($ff $fg-alt)'",'
    echo '        "text.placeholder": "'($ff $fg-dim)'",'
    echo '        "text.disabled": "'($ff $fg-dim)'",'
    echo '        "text.accent": "'($ff $blue)'",'

    # --- Icons ---
    echo '        "icon": "'($ff $fg)'",'
    echo '        "icon.muted": "'($ff $fg-alt)'",'
    echo '        "icon.disabled": "'($ff $fg-dim)'",'
    echo '        "icon.placeholder": "'($ff $fg-alt)'",'
    echo '        "icon.accent": "'($ff $blue)'",'

    # --- Status bar / title bar / toolbar / tabs ---
    echo '        "status_bar.background": "'($ff $bg-active)'",'
    echo '        "title_bar.background": "'($ff $bg-active)'",'
    echo '        "title_bar.inactive_background": "'($ff $bg-dim)'",'
    echo '        "toolbar.background": "'($ff $bg)'",'
    echo '        "tab_bar.background": "'($ff $bg-dim)'",'
    echo '        "tab.inactive_background": "'($ff $bg-dim)'",'
    echo '        "tab.active_background": "'($ff $bg)'",'

    # --- Search ---
    echo '        "search.match_background": "'($a $blue 66)'",'
    echo '        "search.active_match_background": "'($a $yellow 66)'",'

    # --- Panel ---
    echo '        "panel.background": "'($ff $bg-dim)'",'
    echo '        "panel.focused_border": "'($ff $blue)'",'
    echo '        "pane.focused_border": null,'

    # --- Scrollbar ---
    echo '        "scrollbar.thumb.active_background": "'($a $blue ac)'",'
    echo '        "scrollbar.thumb.hover_background": "'($a $fg 4c)'",'
    echo '        "scrollbar.thumb.background": "'($a $fg-dim 4c)'",'
    echo '        "scrollbar.thumb.border": "'($ff $bg-active)'",'
    echo '        "scrollbar.track.background": "#00000000",'
    echo '        "scrollbar.track.border": "'($ff $bg-dim)'",'

    # --- Editor ---
    echo '        "editor.foreground": "'($ff $fg)'",'
    echo '        "editor.background": "'($ff $bg)'",'
    echo '        "editor.gutter.background": "'($ff $bg)'",'
    echo '        "editor.subheader.background": "'($ff $bg-dim)'",'
    echo '        "editor.active_line.background": "'($a $bg-hl bf)'",'
    echo '        "editor.highlighted_line.background": "'($ff $bg-hl)'",'
    echo '        "editor.line_number": "'($a $fg-dim '')'",'
    echo '        "editor.active_line_number": "'($a $fg '')'",'
    echo '        "editor.hover_line_number": "'($a $fg-alt '')'",'
    echo '        "editor.invisible": "'($ff $fg-dim)'",'
    echo '        "editor.wrap_guide": "'($a $fg 0d)'",'
    echo '        "editor.active_wrap_guide": "'($a $fg 1a)'",'
    echo '        "editor.selection.background": "'($ff $bg-region)'",'
    echo '        "editor.document_highlight.read_background": "'($a $blue 1a)'",'
    echo '        "editor.document_highlight.write_background": "'($a $fg-dim 66)'",'
    echo '        "editor.diff.added_background": "'($ff $bg-added)'",'
    echo '        "editor.diff.deleted_background": "'($ff $bg-removed)'",'
    echo '        "editor.diff.modified_background": "'($ff $bg-changed)'",'
    echo '        "editor.completion.documentation.background": "'($ff $bg-completion)'",'
    echo '        "editor.completion.documentation.foreground": "'($ff $fg)'",'

    # --- Picker ---
    echo '        "picker.input.background": "'($ff $element)'",'
    echo '        "picker.selection.background": "'($ff $bg-region)'",'

    # --- Terminal ---
    echo '        "terminal.background": "'($ff $bg)'",'
    echo '        "terminal.foreground": "'($ff $fg)'",'
    echo '        "terminal.bright_foreground": "'($ff $fg)'",'
    echo '        "terminal.dim_foreground": "'($ff $fg-dim)'",'
    echo '        "terminal.ansi.black": "'($ff $bg)'",'
    echo '        "terminal.ansi.bright_black": "'($ff $black-br)'",'
    echo '        "terminal.ansi.dim_black": "'($ff $fg)'",'
    echo '        "terminal.ansi.red": "'($ff $red)'",'
    echo '        "terminal.ansi.bright_red": "'($ff $red-w)'",'
    echo '        "terminal.ansi.dim_red": "'($ff $red-f)'",'
    echo '        "terminal.ansi.green": "'($ff $green)'",'
    echo '        "terminal.ansi.bright_green": "'($ff $green-w)'",'
    echo '        "terminal.ansi.dim_green": "'($ff $green-f)'",'
    echo '        "terminal.ansi.yellow": "'($ff $yellow)'",'
    echo '        "terminal.ansi.bright_yellow": "'($ff $yellow-w)'",'
    echo '        "terminal.ansi.dim_yellow": "'($ff $yellow)'",'
    echo '        "terminal.ansi.blue": "'($ff $blue)'",'
    echo '        "terminal.ansi.bright_blue": "'($ff $blue-w)'",'
    echo '        "terminal.ansi.dim_blue": "'($ff $blue-f)'",'
    echo '        "terminal.ansi.magenta": "'($ff $magenta)'",'
    echo '        "terminal.ansi.bright_magenta": "'($ff $magenta-w)'",'
    echo '        "terminal.ansi.dim_magenta": "'($ff $magenta-f)'",'
    echo '        "terminal.ansi.cyan": "'($ff $cyan)'",'
    echo '        "terminal.ansi.bright_cyan": "'($ff $cyan-cool)'",'
    echo '        "terminal.ansi.dim_cyan": "'($ff $cyan-f)'",'
    echo '        "terminal.ansi.white": "'($ff $fg-dim)'",'
    echo '        "terminal.ansi.bright_white": "'($ff $fg)'",'
    echo '        "terminal.ansi.dim_white": "'($ff $fg-dim)'",'

    # --- Link ---
    echo '        "link_text.hover": "'($ff $blue)'",'

    # --- VCS ---
    echo '        "version_control.added": "'($ff $green-w)'",'
    echo '        "version_control.modified": "'($ff $yellow-w)'",'
    echo '        "version_control.deleted": "'($ff $red-w)'",'

    # --- Status indicators ---
    echo '        "conflict": "'($ff $yellow-w)'",'
    echo '        "conflict.background": "'($ff $bg-changed)'",'
    echo '        "conflict.border": "'($ff $yellow)'",'
    echo '        "created": "'($ff $green-w)'",'
    echo '        "created.background": "'($ff $bg-added)'",'
    echo '        "created.border": "'($ff $green)'",'
    echo '        "deleted": "'($ff $red-w)'",'
    echo '        "deleted.background": "'($ff $bg-removed)'",'
    echo '        "deleted.border": "'($ff $red)'",'
    echo '        "error": "'($ff $red-w)'",'
    echo '        "error.background": "'($ff $bg-red-subtle)'",'
    echo '        "error.border": "'($ff $red)'",'
    echo '        "hidden": "'($ff $fg-dim)'",'
    echo '        "hidden.background": "'($ff $bg-active)'",'
    echo '        "hidden.border": "'($ff $bg-active)'",'
    echo '        "hint": "'($ff $cyan-f)'",'
    echo '        "hint.background": "'($ff $bg-dim)'",'
    echo '        "hint.border": "'($ff $blue-f)'",'
    echo '        "ignored": "'($ff $fg-dim)'",'
    echo '        "ignored.background": "'($ff $bg-active)'",'
    echo '        "ignored.border": "'($ff $border-c)'",'
    echo '        "info": "'($ff $blue)'",'
    echo '        "info.background": "'($ff $bg-blue-subtle)'",'
    echo '        "info.border": "'($ff $blue-f)'",'
    echo '        "modified": "'($ff $yellow-w)'",'
    echo '        "modified.background": "'($ff $bg-changed)'",'
    echo '        "modified.border": "'($ff $yellow)'",'
    echo '        "predictive": "'($ff $fg-dim)'",'
    echo '        "predictive.background": "'($ff $bg-dim)'",'
    echo '        "predictive.border": "'($ff $bg-active)'",'
    echo '        "renamed": "'($ff $blue)'",'
    echo '        "renamed.background": "'($ff $bg-blue-subtle)'",'
    echo '        "renamed.border": "'($ff $blue-f)'",'
    echo '        "success": "'($ff $green-w)'",'
    echo '        "success.background": "'($ff $bg-added)'",'
    echo '        "success.border": "'($ff $green)'",'
    echo '        "unreachable": "'($ff $fg-alt)'",'
    echo '        "unreachable.background": "'($ff $bg-active)'",'
    echo '        "unreachable.border": "'($ff $border-c)'",'
    echo '        "warning": "'($ff $yellow-w)'",'
    echo '        "warning.background": "'($ff $bg-changed)'",'
    echo '        "warning.border": "'($ff $yellow)'",'

    # --- Players (collaboration cursors) ---
    echo '        "players": ['
    echo '          { "cursor": "'($ff $blue)'", "background": "'($ff $blue)'", "selection": "'($a $blue 3d)'" },'
    echo '          { "cursor": "'($ff $fg-dim)'", "background": "'($ff $fg-dim)'", "selection": "'($a $fg-dim 3d)'" },'
    echo '          { "cursor": "'($ff $red-w)'", "background": "'($ff $red-w)'", "selection": "'($a $red-w 3d)'" },'
    echo '          { "cursor": "'($ff $magenta-w)'", "background": "'($ff $magenta-w)'", "selection": "'($a $magenta-w 3d)'" },'
    echo '          { "cursor": "'($ff $cyan-cool)'", "background": "'($ff $cyan-cool)'", "selection": "'($a $cyan-cool 3d)'" },'
    echo '          { "cursor": "'($ff $red)'", "background": "'($ff $red)'", "selection": "'($a $red 3d)'" },'
    echo '          { "cursor": "'($ff $yellow-w)'", "background": "'($ff $yellow-w)'", "selection": "'($a $yellow-w 3d)'" },'
    echo '          { "cursor": "'($ff $green-w)'", "background": "'($ff $green-w)'", "selection": "'($a $green-w 3d)'" }'
    echo '        ],'

    # --- Syntax (Prot-faithful mapping + gruvbox structure) ---
    # Color assignments follow Prot's Emacs face conventions:
    #   keyword → magenta-cooler, function → magenta, string → blue-warmer,
    #   type → cyan, variable → cyan-warmer, property → blue, constant → blue
    echo '        "syntax": {'
    echo '          "attribute": { "color": "'($ff $red)'", "font_style": null, "font_weight": null },'
    echo '          "boolean": { "color": "'($ff $blue)'", "font_style": null, "font_weight": null },'
    echo '          "comment": { "color": "'($ff $fg-dim)'", "font_style": "italic", "font_weight": null },'
    echo '          "comment.doc": { "color": "'($ff $fg-alt)'", "font_style": "italic", "font_weight": null },'
    echo '          "constant": { "color": "'($ff $blue)'", "font_style": null, "font_weight": null },'
    echo '          "constructor": { "color": "'($ff $magenta)'", "font_style": null, "font_weight": null },'
    echo '          "embedded": { "color": "'($ff $red)'", "font_style": null, "font_weight": null },'
    echo '          "emphasis": { "color": "'($ff $blue)'", "font_style": "italic", "font_weight": null },'
    echo '          "emphasis.strong": { "color": "'($ff $blue)'", "font_style": null, "font_weight": 700 },'
    echo '          "enum": { "color": "'($ff $cyan-w)'", "font_style": null, "font_weight": null },'
    echo '          "function": { "color": "'($ff $magenta)'", "font_style": null, "font_weight": null },'
    echo '          "function.builtin": { "color": "'($ff $magenta-w)'", "font_style": null, "font_weight": null },'
    echo '          "hint": { "color": "'($ff $cyan-f)'", "font_style": null, "font_weight": null },'
    echo '          "keyword": { "color": "'($ff $magenta-cool)'", "font_style": null, "font_weight": null },'
    echo '          "label": { "color": "'($ff $cyan)'", "font_style": null, "font_weight": null },'
    echo '          "link_text": { "color": "'($ff $cyan-w)'", "font_style": "italic", "font_weight": null },'
    echo '          "link_uri": { "color": "'($ff $blue-w)'", "font_style": null, "font_weight": null },'
    echo '          "namespace": { "color": "'($ff $cyan-w)'", "font_style": null, "font_weight": null },'
    echo '          "number": { "color": "'($ff $fg)'", "font_style": null, "font_weight": null },'
    echo '          "operator": { "color": "'($ff $magenta)'", "font_style": null, "font_weight": null },'
    echo '          "predictive": { "color": "'($ff $fg-dim)'", "font_style": "italic", "font_weight": null },'
    echo '          "preproc": { "color": "'($ff $red-cool)'", "font_style": null, "font_weight": null },'
    echo '          "primary": { "color": "'($ff $fg)'", "font_style": null, "font_weight": null },'
    echo '          "property": { "color": "'($ff $blue)'", "font_style": null, "font_weight": null },'
    echo '          "punctuation": { "color": "'($ff $fg)'", "font_style": null, "font_weight": null },'
    echo '          "punctuation.bracket": { "color": "'($ff $fg-dim)'", "font_style": null, "font_weight": null },'
    echo '          "punctuation.delimiter": { "color": "'($ff $fg)'", "font_style": null, "font_weight": null },'
    echo '          "punctuation.list_marker": { "color": "'($ff $fg)'", "font_style": null, "font_weight": null },'
    echo '          "punctuation.markup": { "color": "'($ff $cyan)'", "font_style": null, "font_weight": null },'
    echo '          "punctuation.special": { "color": "'($ff $red)'", "font_style": null, "font_weight": null },'
    echo '          "selector": { "color": "'($ff $magenta-cool)'", "font_style": null, "font_weight": null },'
    echo '          "selector.pseudo": { "color": "'($ff $cyan)'", "font_style": null, "font_weight": null },'
    echo '          "string": { "color": "'($ff $blue-w)'", "font_style": null, "font_weight": null },'
    echo '          "string.escape": { "color": "'($ff $blue-w)'", "font_style": null, "font_weight": null },'
    echo '          "string.regex": { "color": "'($ff $magenta-cool)'", "font_style": null, "font_weight": null },'
    echo '          "string.special": { "color": "'($ff $blue-w)'", "font_style": null, "font_weight": null },'
    echo '          "string.special.symbol": { "color": "'($ff $blue-w)'", "font_style": null, "font_weight": null },'
    echo '          "tag": { "color": "'($ff $blue)'", "font_style": null, "font_weight": null },'
    echo '          "text.literal": { "color": "'($ff $magenta)'", "font_style": null, "font_weight": null },'
    echo '          "title": { "color": "'($ff $fg-dim)'", "font_style": null, "font_weight": null },'
    echo '          "type": { "color": "'($ff $cyan)'", "font_style": null, "font_weight": null },'
    echo '          "variable": { "color": "'($ff $cyan-w)'", "font_style": null, "font_weight": null },'
    echo '          "variable.special": { "color": "'($ff $magenta-cool)'", "font_style": null, "font_weight": null },'
    echo '          "variant": { "color": "'($ff $cyan)'", "font_style": null, "font_weight": null }'
    echo '        }'

    echo '      }'
    echo '    }'
    echo '  ]'
    echo '}'
  } >$out

  echo "Generated Zed theme: "$out
}

# --- All ---

fn all {|palette name &variant=dark|
  ghostty $palette $name
  sketchybar $palette
  borders $palette
  helix $palette $name
  zed $palette $name $variant
  wallpaper $palette
}
