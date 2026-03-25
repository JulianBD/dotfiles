local sbar = require("sketchybar")
local colors = require("colors")
local icons = require("icons")

-- Workspace definitions
local all_workspaces = { "1","2","3","4","5","6","7","8","C","M","P1","P2","P3","P4" }

-- Color groups by workspace
local function group_colors(ws)
  local n = tonumber(ws)
  if n and n >= 1 and n <= 4 then
    return colors.space_group1, colors.space_group1_bg
  elseif n and n >= 5 and n <= 8 then
    return colors.space_group2, colors.space_group2_bg
  else
    return colors.space_group3, colors.space_group3_bg
  end
end

-- Look up app icon from icons table
local function app_icon(app_name)
  return icons[app_name] or ":default:"
end

-- Register custom aerospace events
sbar.add("event", "aerospace_workspace_change")
sbar.add("event", "aerospace_mode_changed")

-- Create workspace items
local space_items = {}

for i, ws in ipairs(all_workspaces) do
  local pad_l = 2
  local pad_r = 2
  if i == 1 then pad_l = 6 end
  if i == #all_workspaces then pad_r = 6 end

  local item = sbar.add("item", "space." .. ws, {
    position = "left",
    drawing = "on",
    background = {
      color = colors.grey_transp,
      corner_radius = 6,
      height = 22,
      drawing = "on",
      padding_left = pad_l,
      padding_right = pad_r,
    },
    icon = {
      string = ws,
      font = "Aporetic Sans:Bold:12.0",
      color = colors.text_muted,
      padding_left = 10,
      padding_right = 10,
    },
    label = { drawing = "off" },
    click_script = "aerospace workspace " .. ws,
  })

  space_items[ws] = item
end

-- Bracket bubble behind all workspaces
local bracket_items = {}
for _, ws in ipairs(all_workspaces) do
  table.insert(bracket_items, "space." .. ws)
end

sbar.add("bracket", "workspaces", bracket_items, {
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
})

-- Update a workspace's display (app icons or workspace label)
local function update_workspace(ws)
  local item = space_items[ws]
  if not item then return end

  sbar.exec(
    "aerospace list-windows --workspace " .. ws .. " 2>/dev/null | awk -F'|' '{gsub(/^ *| *$/, \"\", $2); print $2}' | sort -u | grep -v '^$'",
    function(result)
      if not result or result == "" then
        -- Empty workspace: show label
        item:set({
          icon = {
            string = ws,
            font = "Aporetic Sans:Bold:12.0",
            padding_left = 10,
            padding_right = 10,
          },
        })
      else
        -- Has windows: show app icons
        local icon_str = ""
        for app in result:gmatch("[^\r\n]+") do
          app = app:match("^%s*(.-)%s*$") -- trim
          if app ~= "" then
            icon_str = icon_str .. app_icon(app)
          end
        end
        if icon_str ~= "" then
          item:set({
            icon = {
              string = icon_str,
              font = "sketchybar-app-font:Regular:14.0",
              padding_left = 6,
              padding_right = 6,
            },
          })
        end
      end
    end
  )
end

-- Highlight focused workspace with group color
local function highlight_workspace(focused_ws)
  for ws, item in pairs(space_items) do
    if ws == focused_ws then
      local active_color, active_bg = group_colors(ws)
      item:set({
        background = { color = active_bg },
        icon = { color = active_color },
      })
    else
      item:set({
        background = { color = colors.grey_transp },
        icon = { color = colors.text_muted },
      })
    end
  end
end

-- Event handler
local handler = sbar.add("item", "space_handler", { drawing = "off" })

handler:subscribe("aerospace_workspace_change", function(env)
  local focused = env.FOCUSED_WORKSPACE or ""
  highlight_workspace(focused)
  update_workspace(focused)

  if env.PREV_WORKSPACE and env.PREV_WORKSPACE ~= "" then
    update_workspace(env.PREV_WORKSPACE)
  end
end)

-- Initial state
sbar.exec("aerospace list-workspaces --focused", function(result)
  local focused = (result or ""):match("^%s*(.-)%s*$")
  if focused ~= "" then
    highlight_workspace(focused)
  end
end)

for _, ws in ipairs(all_workspaces) do
  update_workspace(ws)
end
