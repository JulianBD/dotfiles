local sbar = require("sketchybar")
local colors = require("colors")

-- Bracket bubble behind right-side items
sbar.add("bracket", "right_group",
  { "front_app", "separator", "volume", "battery", "clock" },
  {
    background = {
      color = colors.bracket_bg,
      corner_radius = 10,
      height = 32,
      padding_left = 6,
      padding_right = 6,
      border_color = colors.bracket_border,
      border_width = 1,
      drawing = "on",
    },
  }
)
