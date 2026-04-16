use str
use path
use dotfiles/generate/common

fn write {|palette name|
  var dir = ~/.config/helix/themes
  mkdir -p $dir
  var out = $dir/prot-current.toml

  var bg = $palette[bg-main]
  var fg = $palette[fg-main]
  var cursor = (common:c $palette cursor $fg)

  # Semantic colors (ef/modus: red, doric: fg-red)
  var red     = (common:c $palette red (common:c $palette fg-red $fg))
  var green   = (common:c $palette green (common:c $palette fg-green $fg))
  var yellow  = (common:c $palette yellow (common:c $palette fg-yellow $fg))
  var blue    = (common:c $palette blue (common:c $palette fg-blue $fg))
  var magenta = (common:c $palette magenta (common:c $palette fg-magenta $fg))
  var cyan    = (common:c $palette cyan (common:c $palette fg-cyan $fg))

  # Warmer/cooler variants
  var red-w     = (common:c $palette red-warmer $red)
  var green-w   = (common:c $palette green-warmer $green)
  var yellow-w  = (common:c $palette yellow-warmer $yellow)
  var blue-w    = (common:c $palette blue-warmer $blue)
  var magenta-w = (common:c $palette magenta-warmer $magenta)
  var cyan-w    = (common:c $palette cyan-warmer $cyan)
  var magenta-cool = (common:c $palette magenta-cooler $magenta)

  # Background shades
  var bg-dim    = (common:c $palette bg-dim (common:c $palette bg-shadow-subtle $bg))
  var bg-active = (common:c $palette bg-active (common:c $palette bg-neutral $bg-dim))
  var bg-popup  = (common:c $palette bg-popup (common:c $palette bg-shadow-subtle $bg-dim))
  var bg-hl     = (common:c $palette bg-hl-line (common:c $palette bg-shadow-subtle $bg-dim))
  var bg-region = (common:c $palette bg-region (common:c $palette bg-neutral (common:c $palette bg-shadow-intense $bg-dim)))

  # Foreground shades
  var fg-dim = (common:c $palette fg-dim (common:c $palette fg-neutral $fg))
  var fg-alt = (common:c $palette fg-alt (common:c $palette fg-shadow-intense $fg))

  # Diff colors
  var bg-added   = (common:c $palette bg-added (common:c $palette bg-green $bg))
  var bg-removed = (common:c $palette bg-removed (common:c $palette bg-red $bg))
  var bg-changed = (common:c $palette bg-changed (common:c $palette bg-yellow $bg))
  var fg-added   = (common:c $palette fg-added $green)
  var fg-removed = (common:c $palette fg-removed $red)

  # Statusline bg
  var bg-mode = (common:c $palette bg-mode-line-active $bg-active)

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
