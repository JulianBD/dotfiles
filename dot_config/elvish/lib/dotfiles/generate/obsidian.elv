use str
use path
use dotfiles/generate/common

# --- Obsidian (Baseline via Style Settings) ---
#
# Baseline declares Style Settings section id: baseline-style
# Overrides are stored per-vault in:
#   <vault>/.obsidian/plugins/obsidian-style-settings/data.json
#
# For now, we only target ~/Documents/sevens and we only update keys that
# already exist in the overrides JSON (no new keys).

fn baseline-sevens {|palette &variant=dark|
  var vault = ~/Documents/sevens
  var appearance-path = $vault/.obsidian/appearance.json
  var data-path = $vault/.obsidian/plugins/obsidian-style-settings/data.json

  if (not (path:is-regular $appearance-path)) {
    echo 'Obsidian: missing '$appearance-path', skipping'
    return
  }

  var appearance = [&]
  try {
    set appearance = (from-json < $appearance-path)
  } catch e {
    echo 'Obsidian: failed to parse '$appearance-path', skipping'
    return
  }

  if (not (has-key $appearance cssTheme)) {
    echo 'Obsidian: no cssTheme in '$appearance-path', skipping'
    return
  }

  if (not-eq $appearance[cssTheme] 'Baseline') {
    echo 'Obsidian: cssTheme is '$appearance[cssTheme]' (not Baseline), skipping'
    return
  }

  if (not (path:is-regular $data-path)) {
    echo 'Obsidian: missing '$data-path', skipping'
    return
  }

  var data = [&]
  try {
    set data = (from-json < $data-path)
  } catch e {
    echo 'Obsidian: failed to parse '$data-path', skipping'
    return
  }

  # Palette-derived colors (match semantic choices used elsewhere)
  var bg = $palette[bg-main]
  var fg = $palette[fg-main]
  var bg-dim    = (common:c $palette bg-dim (common:c $palette bg-shadow-subtle $bg))
  var bg-active = (common:c $palette bg-active (common:c $palette bg-neutral $bg-dim))
  var bg-soft   = (common:c $palette bg-hl-line (common:c $palette bg-inactive $bg-dim))
  var fg-dim = (common:c $palette fg-dim (common:c $palette fg-neutral $fg))
  var fg-alt = (common:c $palette fg-alt (common:c $palette fg-shadow-intense $fg))

  # Baseline id -> palette color
  var map = [&]
  set map[background-primary] = $bg
  # Keep sidebars closer to the editor background
  set map[background-secondary] = $bg

  # Slightly tinted surfaces (if you choose to override them)
  set map[background-primary-alt] = $bg-soft
  set map[code-background] = $bg-soft

  # Keep hover/borders subtle (bg-active was too contrasty on light palettes)
  set map[background-modifier-hover] = $bg-dim
  set map[background-modifier-border] = $bg-dim

  set map[icon-color] = $fg-dim

  set map[text-normal] = $fg
  set map[text-normal-editor] = $fg-dim
  set map[text-muted] = $fg-alt
  set map[text-faint] = $fg-dim

  set map[inline-title-color] = $fg-alt
  set map[h1-color] = $fg-alt
  set map[h2-color] = $fg-alt
  set map[h3-color] = $fg-alt
  set map[h4-color] = $fg-alt

  var changed = $false
  keys $map | each {|id|
    var k = "baseline-style@@"$id"@@"$variant
    if (has-key $data $k) {
      set data[$k] = $map[$id]
      set changed = $true
    }
  }

  if $changed {
    put $data | to-json > $data-path
    echo 'Obsidian: updated Baseline overrides (' $variant ') in ' $vault
  } else {
    echo 'Obsidian: no matching Baseline override keys to update in ' $data-path
  }
}

# --- Obsidian Minimal: all palette color schemes ---
#
# Generates .obsidian/snippets/prot-schemes.css.
# The file has two sections:
#   1. ACTIVE block — targets .theme-light/.theme-dark directly with !important.
#      Rewritten on every theme:apply so Obsidian hot-reloads the active colors.
#   2. Named classes — one per palette (.theme-light.minimal-prot-ef-day etc.)
#      for reference; never change unless you run theme:compile-obsidian-schemes.
#
# Enable the snippet once in Obsidian → Settings → Appearance → CSS snippets.
# After that, theme:apply handles everything.

fn -obsidian-scheme-vars {|p variant &active=$false|
  # Emit CSS variable declarations for a palette.
  # &active=$true uses !important and targets .theme-light/.theme-dark directly.
  var bg        = $p[bg-main]
  var fg        = $p[fg-main]
  var bg-dim    = (common:c $p bg-dim (common:c $p bg-shadow-subtle $bg))
  var bg-active = (common:c $p bg-active (common:c $p bg-neutral $bg-dim))
  # bg-neutral added before bg-inactive so doric themes get a distinct active-item bg
  var bg-hl     = (common:c $p bg-hl-line (common:c $p bg-neutral (common:c $p bg-inactive $bg-dim)))
  # fg-shadow-subtle (doric) gives a muted themed tone; bg-mode-line-active for ef/modus/standard
  var bg-mode   = (common:c $p bg-mode-line-active (common:c $p fg-shadow-subtle (common:c $p fg-neutral $bg-active)))
  var fg-dim    = (common:c $p fg-dim (common:c $p fg-neutral $fg))
  var fg-alt    = (common:c $p fg-alt (common:c $p fg-shadow-subtle $fg-dim))

  var red     = (common:c $p red (common:c $p fg-red $fg))
  var orange  = (common:c $p orange (common:c $p fg-orange $red))
  var yellow  = (common:c $p yellow (common:c $p fg-yellow (common:c $p bg-yellow $fg)))
  var green   = (common:c $p green (common:c $p fg-green $fg))
  var cyan    = (common:c $p cyan (common:c $p fg-cyan (common:c $p fg-accent $fg)))
  var blue    = (common:c $p blue (common:c $p fg-blue (common:c $p fg-accent $fg)))
  var magenta = (common:c $p magenta (common:c $p fg-magenta $fg))
  var pink    = (common:c $p magenta-warmer $magenta)

  var imp = (if $active { put ' !important' } else { put '' })

  var rgb = {|hex|
    var h = (str:trim-prefix $hex '#')
    var r = (printf '%d' '0x'$h[..2])
    var g = (printf '%d' '0x'$h[2..4])
    var b = (printf '%d' '0x'$h[4..6])
    put $r','$g','$b
  }

  var hl1 = 'rgba('($rgb $blue)', 0.3)'
  var hl2 = 'rgba('($rgb $yellow)', 0.3)'

  # --- Minimal theme variables ---
  echo '  --bg1: '$bg$imp';'
  echo '  --bg2: '$bg-dim$imp';'
  echo '  --bg3: '$bg-hl$imp';'
  echo '  --ui1: '$bg-hl$imp';'
  echo '  --ui2: '$bg-active$imp';'
  echo '  --ui3: '$bg-mode$imp';'
  echo '  --tx1: '$fg$imp';'
  echo '  --tx2: '$fg-dim$imp';'
  echo '  --tx3: '$fg-alt$imp';'
  echo '  --hl1: '$hl1$imp';'
  echo '  --hl2: '$hl2$imp';'
  # --- Native Obsidian + Baseline variables ---
  # Backgrounds
  echo '  --background-primary: '$bg$imp';'
  echo '  --background-secondary: '$bg-dim$imp';'
  echo '  --background-primary-alt: '$bg-hl$imp';'
  echo '  --background-modifier-hover: '$bg-hl$imp';'
  echo '  --background-modifier-border: '$bg-active$imp';'
  echo '  --background-modifier-form-field: '$bg-dim$imp';'
  # Text
  echo '  --text-normal: '$fg$imp';'
  echo '  --text-muted: '$fg-dim$imp';'
  echo '  --text-faint: '$fg-alt$imp';'
  echo '  --text-on-accent: '$bg$imp';'
  echo '  --text-selection: rgba('($rgb $blue)', 0.2)'$imp';'
  # Accent — replaces Obsidian default purple everywhere
  echo '  --color-accent: '$blue$imp';'
  echo '  --color-accent-1: '$blue$imp';'
  echo '  --color-accent-2: '$blue$imp';'
  echo '  --color-accent-rgb: '($rgb $blue)$imp';'
  echo '  --interactive-accent: '$blue$imp';'
  echo '  --interactive-accent-hover: rgba('($rgb $blue)', 0.85)'$imp';'
  # Interactive elements (buttons, controls)
  echo '  --interactive-normal: '$bg-active$imp';'
  echo '  --interactive-hover: '$bg-hl$imp';'
  echo '  --interactive-click: '$bg-mode$imp';'
  # Links
  echo '  --link-color: '$blue$imp';'
  echo '  --link-color-hover: '$blue$imp';'
  echo '  --link-external-color: '$cyan$imp';'
  echo '  --link-external-color-hover: '$cyan$imp';'
  echo '  --link-unresolved-color: '$fg-alt$imp';'
  # Named palette colors (Minimal + Baseline both use these)
  echo '  --color-red:    '$red$imp';'
  echo '  --color-orange: '$orange$imp';'
  echo '  --color-yellow: '$yellow$imp';'
  echo '  --color-green:  '$green$imp';'
  echo '  --color-cyan:   '$cyan$imp';'
  echo '  --color-blue:   '$blue$imp';'
  echo '  --color-purple: '$magenta$imp';'
  echo '  --color-pink:   '$pink$imp';'
  echo '  --color-red-rgb:    '($rgb $red)$imp';'
  echo '  --color-orange-rgb: '($rgb $orange)$imp';'
  echo '  --color-yellow-rgb: '($rgb $yellow)$imp';'
  echo '  --color-green-rgb:  '($rgb $green)$imp';'
  echo '  --color-cyan-rgb:   '($rgb $cyan)$imp';'
  echo '  --color-blue-rgb:   '($rgb $blue)$imp';'
  echo '  --color-purple-rgb: '($rgb $magenta)$imp';'
  echo '  --color-pink-rgb:   '($rgb $pink)$imp';'
}

fn minimal-all-sevens {|db active-palette active-name &active-variant=dark|
  var vault = ~/Documents/sevens
  mkdir -p $vault/.obsidian/snippets
  var out = $vault/.obsidian/snippets/prot-schemes.css

  var names = [(keys $db | order)]
  var mode-sel = (if (eq $active-variant dark) { put '.theme-dark' } else { put '.theme-light' })

  {
    echo '/* prot-schemes — auto-generated, do not edit manually */'
    echo '/* Regenerated by theme:apply and theme:compile-obsidian-schemes */'
    echo ''

    # --- Active theme block (rewritten on every theme:apply) ---
    echo '/* ACTIVE: '$active-name' ('$active-variant') */'
    echo $mode-sel' {'
    -obsidian-scheme-vars $active-palette $active-variant &active=$true
    echo '}'
    echo ''

    # --- All named classes (for reference) ---
    echo '/* ---- All prot schemes as named classes ---- */'
    for name $names {
      var entry = $db[$name]
      var variant = $entry[variant]
      var p = $entry[colors]
      if (not (has-key $p bg-main)) { continue }
      var sel = (if (eq $variant dark) { put '.theme-dark' } else { put '.theme-light' })
      echo '/* '$name' ('$variant') */'
      echo $sel'.minimal-prot-'$name' {'
      -obsidian-scheme-vars $p $variant
      echo '}'
      echo ''
    }
  } >$out

  echo 'Obsidian: wrote '$out' (active: '$active-name')'
}
