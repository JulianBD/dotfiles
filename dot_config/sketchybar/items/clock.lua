local sbar = require("sketchybar")
local colors = require("colors")

local clock = sbar.add("item", "clock", {
  position = "right",
  update_freq = 10,
  icon = {
    string = "",
    color = colors.clock,
  },
  label = {
    color = colors.clock,
  },
})

clock:subscribe("routine", function()
  sbar.exec("date '+%b %d %M'", function(result)
    local trimmed = (result or ""):match("^%s*(.-)%s*$")
    local date, min = trimmed:match("^(.+)%s+(%d+)$")
    local fifth = math.floor(tonumber(min) / 12) + 1
    local pips = string.rep("●", fifth) .. string.rep("○", 5 - fifth)
    clock:set({ label = { string = date .. "  " .. pips } })
  end)
end)
