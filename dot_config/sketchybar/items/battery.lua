local sbar = require("sketchybar")
local colors = require("colors")

local battery = sbar.add("item", "battery", {
  position = "right",
  update_freq = 120,
  icon = {
    font = "Hack Nerd Font:Regular:14.0",
    drawing = "on",
  },
})

local function update_battery()
  sbar.exec("pmset -g batt", function(result)
    if not result then return end

    local pct = tonumber(result:match("(%d+)%%"))
    if not pct then return end

    local charging = result:match("AC Power") ~= nil
    local icon, color

    if charging then
      icon = "󱐋"
      color = colors.battery_charging
    elseif pct >= 90 then
      icon = ""
      color = colors.battery_normal
    elseif pct >= 60 then
      icon = ""
      color = colors.battery_normal
    elseif pct >= 30 then
      icon = ""
      color = colors.battery_warning
    elseif pct >= 10 then
      icon = ""
      color = colors.battery_low
    else
      icon = ""
      color = colors.battery_critical
    end

    battery:set({
      icon = { string = icon, color = color },
      label = { string = pct .. "%", color = color },
    })
  end)
end

battery:subscribe({ "routine", "system_woke", "power_source_change" }, function()
  update_battery()
end)

update_battery()
