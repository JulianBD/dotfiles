local sbar = require("sketchybar")
local colors = require("colors")

sbar.default({
  padding_left = 0,
  padding_right = 0,
  icon = {
    font = "Hack Nerd Font:Regular:14.0",
    color = colors.icon_color,
    padding_left = 10,
    padding_right = 10,
  },
  label = {
    font = "Monaspace Neon NF:Bold:14.0",
    color = colors.label_color,
    padding_left = 0,
    padding_right = 10,
  },
  background = {
    padding_left = 4,
    padding_right = 4,
  },
})
