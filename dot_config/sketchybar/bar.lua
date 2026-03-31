local sbar = require("sketchybar")
local colors = require("colors")

sbar.bar({
  position = "top",
  height = 32,
  blur_radius = 0,
  color = colors.bar_color,
  y_offset = 10,
  padding_left = 10,
  padding_right = 10,
})
