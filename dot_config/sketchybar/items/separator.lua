local sbar = require("sketchybar")
local colors = require("colors")

sbar.add("item", "separator", {
  position = "right",
  icon = {
    string = "|",
    color = colors.text_muted,
    padding_left = 8,
    padding_right = 8,
  },
  label = { drawing = "off" },
})
