local sbar = require("sketchybar")
local colors = require("colors")
local clock = require("items.clock")

-- Bracket bubble behind right-side items
local clock_bar_items = {}
for i = 1, clock.BAR_SEGMENTS do
  table.insert(clock_bar_items, "clock.bar." .. i)
end

sbar.add("bracket", "right_group",
  { "front_app", "separator", "volume", "battery", "clock", table.unpack(clock_bar_items) },
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
