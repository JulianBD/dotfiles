local sbar = require("sketchybar")
local colors = require("colors")
local icons = require("icons")

-- Front app name + icon
local front_app = sbar.add("item", "front_app", {
  position = "right",
  icon = {
    drawing = "on",
    font = "sketchybar-app-font:Regular:16.0",
  },
  label = {
    drawing = "on",
    color = colors.text_muted,
  },
})

front_app:subscribe("front_app_switched", function(env)
  local app = env.INFO or ""
  local icon = icons[app] or ":default:"
  front_app:set({
    label = { string = app },
    icon = { string = icon },
  })
end)
