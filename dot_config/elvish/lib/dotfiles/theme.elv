# theme.elv — Top-level theme management commands
#
# Usage:
#   use dotfiles/theme
#   theme:list                # list all available themes
#   theme:apply ef-autumn     # apply a theme to all downstream configs
#   theme:pick                # interactive picker (native elvish)
#   theme:current             # show current theme name
#   theme:sync                # rebuild palette database from elpa sources

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
  generate:all $p $name &variant=$variant

  # Record as current theme
  palette:set-current $name

  echo "Applied theme: "$name" ("$variant")"
}

fn pick {
  # Interactive theme picker
  # Uses peco for now; switch to edit:listing:start-custom once
  # daily-driving elvish interactively
  var themes = [(palette:list)]
  if (== (count $themes) 0) {
    echo "No themes available. Run theme:sync first."
    return
  }

  var chosen = (str:trim-space (to-lines $themes | peco --prompt "theme > " | slurp))
  if (not-eq $chosen "") {
    apply $chosen
  }
}
