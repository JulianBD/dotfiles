local sbar = require("sketchybar")
local colors = require("colors")

sbar.bar({
  position = "top",
  height = 40,
  blur_radius = 30,
  color = colors.bar_color,
  y_offset = 4,
  padding_left = 10,
  padding_right = 10,
})
