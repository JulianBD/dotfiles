use str

# Helper: look up a color key in palette with fallback
fn c {|palette key fallback|
  if (has-key $palette $key) {
    put $palette[$key]
  } else {
    put $fallback
  }
}

# Strip # prefix from hex color
fn hex {|color|
  str:trim-prefix $color '#'
}
