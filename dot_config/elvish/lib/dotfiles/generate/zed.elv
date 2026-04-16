use str
use path
use dotfiles/generate/common

fn write {|palette name variant|
  var dir = ~/.config/zed/themes
  mkdir -p $dir
  var out = $dir/prot-current.json

  var bg = $palette[bg-main]
  var fg = $palette[fg-main]
  var cursor = (common:c $palette cursor $fg)

  # Semantic colors
  var red     = (common:c $palette red (common:c $palette fg-red $fg))
  var green   = (common:c $palette green (common:c $palette fg-green $fg))
  var yellow  = (common:c $palette yellow (common:c $palette fg-yellow $fg))
  var blue    = (common:c $palette blue (common:c $palette fg-blue $fg))
  var magenta = (common:c $palette magenta (common:c $palette fg-magenta $fg))
  var cyan    = (common:c $palette cyan (common:c $palette fg-cyan $fg))

  var red-w     = (common:c $palette red-warmer $red)
  var green-w   = (common:c $palette green-warmer $green)
  var yellow-w  = (common:c $palette yellow-warmer $yellow)
  var blue-w    = (common:c $palette blue-warmer $blue)
  var magenta-w = (common:c $palette magenta-warmer $magenta)
  var cyan-w    = (common:c $palette cyan-warmer $cyan)

  # Cooler variants (Prot uses magenta-cooler heavily for keywords)
  var red-cool     = (common:c $palette red-cooler $red)
  var magenta-cool = (common:c $palette magenta-cooler $magenta)
  var cyan-cool    = (common:c $palette cyan-cooler $cyan)

  # Faint variants
  var red-f     = (common:c $palette red-faint $red)
  var green-f   = (common:c $palette green-faint $green)
  var cyan-f    = (common:c $palette cyan-faint $cyan)
  var blue-f    = (common:c $palette blue-faint $blue)
  var magenta-f = (common:c $palette magenta-faint $magenta)

  # Background shades
  var bg-dim    = (common:c $palette bg-dim (common:c $palette bg-shadow-subtle $bg))
  var bg-active = (common:c $palette bg-active (common:c $palette bg-neutral $bg-dim))
  var bg-alt    = (common:c $palette bg-alt $bg-dim)
  var bg-popup  = (common:c $palette bg-popup (common:c $palette bg-shadow-subtle $bg-dim))
  var bg-hl     = (common:c $palette bg-hl-line (common:c $palette bg-shadow-subtle $bg-dim))
  var bg-region = (common:c $palette bg-region (common:c $palette bg-neutral (common:c $palette bg-shadow-intense $bg-dim)))
  var bg-hover  = (common:c $palette bg-hover (common:c $palette bg-accent $bg-active))
  var bg-mode   = (common:c $palette bg-mode-line-active $bg-active)
  var fg-mode   = (common:c $palette fg-mode-line-active $fg)
  var border-c  = (common:c $palette border $bg-active)

  # Foreground shades
  var fg-dim = (common:c $palette fg-dim (common:c $palette fg-neutral $fg))
  var fg-alt = (common:c $palette fg-alt (common:c $palette fg-shadow-intense $fg))

  # Diff/VCS backgrounds
  var bg-added   = (common:c $palette bg-added (common:c $palette bg-green $bg))
  var bg-removed = (common:c $palette bg-removed (common:c $palette bg-red $bg))
  var bg-changed = (common:c $palette bg-changed (common:c $palette bg-yellow $bg))

  # Subtle/intense bg variants
  var bg-blue-subtle    = (common:c $palette bg-blue-subtle (common:c $palette bg-blue $bg-dim))
  var bg-red-subtle     = (common:c $palette bg-red-subtle (common:c $palette bg-red $bg-dim))
  var bg-yellow-intense = (common:c $palette bg-yellow-intense (common:c $palette bg-yellow $bg-active))
  var bg-completion     = (common:c $palette bg-completion $bg-popup)

  # Element & inactive surfaces
  var element = (common:c $palette bg-inactive $bg-dim)

  # ANSI terminal colors (bright variants)
  var black-br   = (common:c $palette bg-active (common:c $palette bg-neutral $bg-dim))
  var white-br   = (common:c $palette fg-alt (common:c $palette fg-shadow-intense $fg))

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
