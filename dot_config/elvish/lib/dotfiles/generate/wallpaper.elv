use str
use path

fn write {|palette|
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
