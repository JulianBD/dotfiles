use str
use path
use dotfiles/generate/common

fn write {|palette|
  var out = ~/.config/borders/bordersrc
  mkdir -p ~/.config/borders
  var active = (common:hex (common:c $palette blue (common:c $palette fg-blue $palette[fg-main])))
  var inactive = (common:hex (common:c $palette bg-active (common:c $palette bg-dim $palette[bg-main])))
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
