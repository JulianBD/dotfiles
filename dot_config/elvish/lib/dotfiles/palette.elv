# palette.elv — Theme palette database management
#
# Clones Prot's theme repos from GitHub and parses their elisp
# palette definitions via babashka into a local JSON database.
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
var repo-dir = ~/.local/share/dotfiles/theme-sources

# Prot's four theme repos
var repos = [
  &ef-themes=https://github.com/protesilaos/ef-themes.git
  &modus-themes=https://github.com/protesilaos/modus-themes.git
  &doric-themes=https://github.com/protesilaos/doric-themes.git
  &standard-themes=https://github.com/protesilaos/standard-themes.git
]

# Find bb — check mise shims first, then PATH
fn find-bb {
  var shim = ~/.local/share/mise/shims/bb
  if (path:is-regular &follow-symlink $shim) {
    put $shim
  } else {
    put (which bb)
  }
}

# Clone or pull a git repo into repo-dir
fn ensure-repo {|name url|
  var dest = $repo-dir/$name
  if (path:is-dir $dest/.git) {
    git -C $dest pull --quiet 2>/dev/null
  } else {
    git clone --quiet --depth 1 $url $dest
  }
}

fn sync {
  # Rebuild the theme database from Prot's git repos
  mkdir -p $config-dir
  mkdir -p $repo-dir

  var bb = (find-bb)
  var themes = [&]

  # Fetch all repos
  keys $repos | each {|name|
    echo "Fetching "$name"..."
    try {
      ensure-repo $name $repos[$name]
    } catch e {
      echo "Warning: failed to fetch "$name >&2
    }
  }

  # ef-themes: each theme is its own file
  try {
    for f [$repo-dir/ef-themes/*-theme.el] {
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
    for f [$repo-dir/modus-themes/modus-themes.el] {
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
    for f [$repo-dir/doric-themes/*-theme.el] {
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

  # standard-themes: each theme is its own file
  try {
    for f [$repo-dir/standard-themes/*-theme.el] {
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
    echo "No standard-themes found" >&2
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
