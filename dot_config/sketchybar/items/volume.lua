local sbar = require("sketchybar")
local colors = require("colors")

local volume = sbar.add("item", "volume", {
  position = "right",
})

volume:subscribe("volume_change", function(env)
  local vol = tonumber(env.INFO) or 0
  local icon

  if vol >= 60 then
    icon = "󰕾"
  elseif vol >= 30 then
    icon = "󰖀"
  elseif vol > 0 then
    icon = "󰕿"
  else
    icon = "󰖁"
  end

  volume:set({
    icon = { string = icon, color = colors.volume },
    label = { string = vol .. "%", color = colors.volume },
  })
end)
