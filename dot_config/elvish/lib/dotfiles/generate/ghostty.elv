use str
use path
use dotfiles/generate/common

fn write {|palette name|
  var out = ~/.config/ghostty/themes/$name
  var bg = $palette[bg-main]
  var fg = $palette[fg-main]
  var cursor = (common:c $palette cursor $fg)

  # Map Prot's semantic colors to ANSI 16-color palette
  # Handles both ef/modus naming (red, green) and doric naming (fg-red, fg-green)
  var red     = (common:c $palette red (common:c $palette fg-red $fg))
  var green   = (common:c $palette green (common:c $palette fg-green $fg))
  var yellow  = (common:c $palette yellow (common:c $palette fg-yellow $fg))
  var blue    = (common:c $palette blue (common:c $palette fg-blue $fg))
  var magenta = (common:c $palette magenta (common:c $palette fg-magenta $fg))
  var cyan    = (common:c $palette cyan (common:c $palette fg-cyan $fg))

  var red-br     = (common:c $palette red-warmer $red)
  var green-br   = (common:c $palette green-warmer $green)
  var yellow-br  = (common:c $palette yellow-warmer $yellow)
  var blue-br    = (common:c $palette blue-warmer $blue)
  var magenta-br = (common:c $palette magenta-warmer $magenta)
  var cyan-br    = (common:c $palette cyan-warmer $cyan)

  var black    = (common:c $palette bg-dim (common:c $palette bg-shadow-subtle $bg))
  var white    = (common:c $palette fg-dim (common:c $palette fg-neutral $fg))
  var black-br = (common:c $palette bg-active (common:c $palette bg-neutral $black))
  var white-br = (common:c $palette fg-alt (common:c $palette fg-shadow-intense $fg))

  var sel-bg = (common:c $palette bg-region (common:c $palette bg-neutral (common:c $palette bg-shadow-intense $black)))
  var sel-fg = $fg

  printf "# Auto-generated from palette: %s\n" $name >$out
  printf "# Regenerate with: theme:apply %s\n" $name >>$out
  printf "background = %s\n" $bg >>$out
  printf "foreground = %s\n" $fg >>$out
  printf "cursor-color = %s\n" $cursor >>$out
  printf "selection-background = %s\n" $sel-bg >>$out
  printf "selection-foreground = %s\n" $sel-fg >>$out

  var i = 0
  for color [$black $red $green $yellow $blue $magenta $cyan $white $black-br $red-br $green-br $yellow-br $blue-br $magenta-br $cyan-br $white-br] {
    printf "palette = %d=%s\n" $i $color >>$out
    set i = (+ $i 1)
  }

  echo "Generated ghostty theme: "$out
}
