local sbar = require("sketchybar")
local colors = require("colors")
local clock = require("items.clock")

-- Bracket bubble behind right-side items. clock.item_names already
-- includes "clock" itself plus every dial/bar sub-item it creates, so
-- the count can't drift out of sync with what clock.lua actually adds.
local members = { "front_app", "separator", "volume", "battery" }
for _, name in ipairs(clock.item_names) do
  table.insert(members, name)
end

sbar.add("bracket", "right_group",
  members,
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
