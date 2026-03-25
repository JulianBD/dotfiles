# palette.elv — Theme palette database management
#
# Reads Prot's elisp theme palettes via babashka and maintains
# a local JSON database of all available palettes.
#
# Usage:
#   use dotfiles/palette
#   palette:sync              # rebuild database from elpa sources
#   palette:get ef-autumn     # get a theme's palette as a map
#   palette:list              # list all available theme names
#   palette:current           # get the currently active palette

use path
use str

# Paths
var config-dir = ~/.config/dotfiles
var db-path = $config-dir/themes.json
var state-path = $config-dir/current-theme
var bb-script = $config-dir/parse-palette.bb

# Find bb — check mise shims first, then PATH
fn find-bb {
  var shim = ~/.local/share/mise/shims/bb
  if (path:is-regular &follow-symlink $shim) {
    put $shim
  } else {
    put (which bb)
  }
}

fn sync {
  # Rebuild the theme database from all installed Prot themes
  mkdir -p $config-dir

  var bb = (find-bb)
  var themes = [&]
  var elpa = ~/.emacs.d/var/elpa

  # ef-themes: each theme is its own file
  try {
    for f [$elpa/ef-themes-*/*-theme.el] {
      if (path:is-regular $f) {
        try {
          var parsed = ($bb $bb-script $f | from-json)
          set themes[$parsed[name]] = [&variant=$parsed[variant] &colors=$parsed[colors]]
        } catch e {
          echo "Warning: failed to parse "$f >&2
        }
      }
    }
  } catch e {
    echo "No ef-themes found" >&2
  }

  # modus-themes: palettes live in modus-themes.el
  try {
    for f [$elpa/modus-themes-*/modus-themes.el] {
      if (path:is-regular $f) {
        for name [modus-operandi modus-operandi-tinted modus-operandi-deuteranopia modus-operandi-tritanopia modus-vivendi modus-vivendi-tinted modus-vivendi-deuteranopia modus-vivendi-tritanopia] {
          try {
            var parsed = ($bb $bb-script $f $name | from-json)
            if (> (count $parsed[colors]) 0) {
              set themes[$parsed[name]] = [&variant=$parsed[variant] &colors=$parsed[colors]]
            }
          } catch e {
            # Some variants may not exist in this version
          }
        }
      }
    }
  } catch e {
    echo "No modus-themes found" >&2
  }

  # doric-themes: each theme is its own file
  try {
    for f [$elpa/doric-themes-*/*-theme.el] {
      if (path:is-regular $f) {
        try {
          var parsed = ($bb $bb-script $f | from-json)
          set themes[$parsed[name]] = [&variant=$parsed[variant] &colors=$parsed[colors]]
        } catch e {
          echo "Warning: failed to parse "$f >&2
        }
      }
    }
  } catch e {
    echo "No doric-themes found" >&2
  }

  # Write database
  put $themes | to-json >$db-path
  echo "Synced "(count $themes)" themes to "$db-path
}

fn load-db {
  # Load the theme database, syncing first if it doesn't exist
  if (not (path:is-regular $db-path)) {
    sync
  }
  from-json < $db-path
}

fn list {
  # List all available theme names
  var db = (load-db)
  keys $db | order
}

fn get {|name|
  # Get a theme's color palette as a map
  var db = (load-db)
  if (has-key $db $name) {
    put $db[$name]
  } else {
    fail "Theme '"$name"' not found. Run palette:sync to update."
  }
}

fn set-current {|name|
  # Set the active theme name
  mkdir -p $config-dir
  echo $name > $state-path
}

fn current-name {
  # Get the currently active theme name
  if (path:is-regular $state-path) {
    str:trim-space (slurp < $state-path)
  } else {
    put ""
  }
}

fn current {
  # Get the currently active theme entry (with variant and colors)
  var name = (current-name)
  if (eq $name "") {
    fail "No theme set. Use theme:apply <name> to set one."
  }
  get $name
}

fn variant {|name|
  # Get a theme's variant ("dark" or "light")
  var entry = (get $name)
  put $entry[variant]
}
