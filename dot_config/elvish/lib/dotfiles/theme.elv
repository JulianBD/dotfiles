# theme.elv — Top-level theme management commands
#
# Usage:
#   use dotfiles/theme
#   theme:list                         # list all available themes
#   theme:apply ef-autumn              # apply a theme to all downstream configs
#   theme:pick                         # interactive picker (native elvish)
#   theme:current                      # show current theme name
#   theme:sync                         # rebuild palette database from elpa sources
#   theme:compile-obsidian-schemes     # write all palette themes → prot-schemes.css

use dotfiles/palette
use dotfiles/generate
use path
use str

fn list {
  palette:list
}

fn sync {
  palette:sync
}

fn current {
  palette:current-name
}

fn apply {|name|
  # Apply a theme: update all downstream configs + macOS appearance
  var entry = (palette:get $name)
  var variant = $entry[variant]
  var p = $entry[colors]

  # Set macOS dark/light mode
  if (eq $variant dark) {
    m appearance --darkmode enable
  } else {
    m appearance --darkmode disable
  }

  # Update ghostty config to use this theme
  var ghostty-config = ~/.config/ghostty/config
  if (path:is-regular $ghostty-config) {
    t 'r/^theme = .*/theme = '$name'/' $ghostty-config > $ghostty-config'.tmp'
    mv $ghostty-config'.tmp' $ghostty-config
  }

  # Generate all downstream configs from the palette database
  var db = (palette:load-db)
  generate:all $p $name &variant=$variant &db=$db

  # Record as current theme
  palette:set-current $name

  echo "Applied theme: "$name" ("$variant")"
}

fn -hex-to-rgb {|hex|
  # Convert "#rrggbb" to list [r g b]
  var h = (str:trim-left $hex '#')
  var r = (printf '%d' '0x'$h[..2])
  var g = (printf '%d' '0x'$h[2..4])
  var b = (printf '%d' '0x'$h[4..6])
  put [$r $g $b]
}

fn -color-block {|hex|
  # Render a colored █ block using 24-bit ANSI escapes
  var rgb = (-hex-to-rgb $hex)
  printf "\e[38;2;%s;%s;%sm██\e[0m" $rgb[0] $rgb[1] $rgb[2]
}

fn -preview-line {|name entry|
  # Format: "theme-name    ████████████████" (bg fg red green yellow blue magenta cyan)
  var p = $entry[colors]
  var swatch-keys = [bg-main fg-main red green yellow blue magenta cyan]
  var swatches = ""
  for k $swatch-keys {
    if (has-key $p $k) {
      set swatches = $swatches(-color-block $p[$k])
    }
  }
  printf "%-36s %s\n" $name $swatches
}

fn compile-obsidian-schemes {
  # Regenerate prot-schemes.css: active theme block at top + all named classes.
  # Enable the snippet once in Obsidian → Settings → Appearance → CSS snippets.
  # After that, theme:apply keeps the active block up to date automatically.
  var db = (palette:load-db)
  var name = (palette:current-name)
  var entry = (palette:get $name)
  generate:obsidian-minimal-all-sevens $db $entry[colors] $name &active-variant=$entry[variant]
}

fn pick {
  # Interactive theme picker with color palette preview
  var db = (palette:load-db)
  var names = [(keys $db | order)]
  if (== (count $names) 0) {
    echo "No themes available. Run theme:sync first."
    return
  }

  var chosen = (
    for name $names {
      -preview-line $name $db[$name]
    } | fzf --ansi --prompt "theme > " --no-multi | slurp
  )
  # Extract just the theme name (first field)
  set chosen = (str:trim-space (str:fields $chosen | take 1))
  if (not-eq $chosen "") {
    apply $chosen
  }
}
