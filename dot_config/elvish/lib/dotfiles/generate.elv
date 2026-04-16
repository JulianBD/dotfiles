# generate.elv — Coordinator that re-exports all per-tool generators.
#
# Usage:
#   use dotfiles/generate
#   generate:all $palette $name &variant=dark &db=$db
#   generate:obsidian-minimal-all-sevens $db $palette $name &active-variant=dark

use ./generate/ghostty
use ./generate/sketchybar
use ./generate/wallpaper
use ./generate/borders
use ./generate/helix
use ./generate/zed
use ./generate/obsidian
use ./generate/glamour

fn all {|palette name &variant=dark &db=[&]|
  ghostty:write $palette $name
  sketchybar:write $palette
  borders:write $palette
  helix:write $palette $name
  zed:write $palette $name $variant
  glamour:write $palette &variant=$variant
  obsidian:baseline-sevens $palette &variant=$variant
  if (> (count $db) 0) {
    obsidian:minimal-all-sevens $db $palette $name &active-variant=$variant
  }
  wallpaper:write $palette
}

fn obsidian-minimal-all-sevens {|db palette name &active-variant=dark|
  obsidian:minimal-all-sevens $db $palette $name &active-variant=$active-variant
}
