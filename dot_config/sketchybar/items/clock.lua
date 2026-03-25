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
  sbar.exec("date '+%b %d %I:%M %p'", function(result)
    local time = (result or ""):match("^%s*(.-)%s*$")
    clock:set({ label = { string = time } })
  end)
end)
