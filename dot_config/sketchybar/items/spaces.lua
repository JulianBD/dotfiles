local sbar = require("sketchybar")
local colors = require("colors")
local icons = require("icons")

-- Workspace groups: primary monitor (display 1) and secondary (display 2)
-- On single monitor, C workspaces move to display 1; D workspaces stay hidden.
local primary_workspaces = { "A1","A2","A3","A4","B1","B2","B3","B4" }
local c_workspaces = { "C1","C2","C3","C4" }
local d_workspaces = { "D1","D2","D3","D4" }
local secondary_workspaces = {}
for _, ws in ipairs(c_workspaces) do table.insert(secondary_workspaces, ws) end
for _, ws in ipairs(d_workspaces) do table.insert(secondary_workspaces, ws) end
local all_workspaces = {}
for _, ws in ipairs(primary_workspaces) do table.insert(all_workspaces, ws) end
for _, ws in ipairs(secondary_workspaces) do table.insert(all_workspaces, ws) end

-- Color groups by workspace prefix
local function group_colors(ws)
  local prefix = ws:sub(1, 1)
  if prefix == "A" then
    return colors.space_group1, colors.space_group1_bg
  elseif prefix == "B" then
    return colors.space_group2, colors.space_group2_bg
  elseif prefix == "C" then
    return colors.space_group3, colors.space_group3_bg
  else
    return colors.space_group4 or colors.cyan, colors.space_group4_bg or 0x30005355
  end
end

local function app_icon(app_name)
  return icons[app_name] or ":default:"
end

sbar.add("event", "aerospace_workspace_change")

local focused_workspace = ""
local space_items = {}
local multi_monitor = false

local function create_items(workspaces, display_id)
  local items = {}
  for i, ws in ipairs(workspaces) do
    local pad_l = 2
    local pad_r = 2
    if i == 1 then pad_l = 6 end
    if i == #workspaces then pad_r = 6 end

    local item = sbar.add("item", "space." .. ws, {
      display = display_id,
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
        font = "Monaspace Neon NF:Bold:12.0",
        color = colors.text_muted,
        padding_left = 10,
        padding_right = 10,
      },
      label = { drawing = "off" },
      click_script = "aerospace workspace " .. ws,
    })

    space_items[ws] = item
    table.insert(items, "space." .. ws)
  end
  return items
end

local primary_item_names = create_items(primary_workspaces, 1)
local secondary_item_names = create_items(secondary_workspaces, 2)

sbar.add("bracket", "workspaces_primary", primary_item_names, {
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

sbar.add("bracket", "workspaces_secondary", secondary_item_names, {
  display = 2,
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

-- Simple highlight: one focused workspace, everything else inactive
local function highlight(new_ws)
  -- Unhighlight previous
  if focused_workspace ~= "" and space_items[focused_workspace] then
    space_items[focused_workspace]:set({
      background = { color = colors.grey_transp },
      icon = { color = colors.text_muted },
    })
  end
  -- Highlight new
  focused_workspace = new_ws
  if new_ws ~= "" and space_items[new_ws] then
    local c, bg = group_colors(new_ws)
    space_items[new_ws]:set({
      background = { color = bg },
      icon = { color = c },
    })
  end
end

-- Update app icons for a workspace
local function update_icons(ws)
  local item = space_items[ws]
  if not item then return end
  sbar.exec(
    "aerospace list-windows --workspace " .. ws .. " 2>/dev/null | awk -F'|' '{gsub(/^ *| *$/, \"\", $2); print $2}' | sort -u | grep -v '^$'",
    function(result)
      if not result or result == "" then
        item:set({ icon = { string = ws, font = "Monaspace Neon NF:Bold:12.0", padding_left = 10, padding_right = 10 } })
      else
        local icon_str = ""
        for raw_app in result:gmatch("[^\r\n]+") do
          local app = raw_app:match("^%s*(.-)%s*$")
          if app ~= "" then icon_str = icon_str .. app_icon(app) end
        end
        if icon_str ~= "" then
          item:set({ icon = { string = icon_str, font = "sketchybar-app-font:Regular:14.0", padding_left = 6, padding_right = 6 } })
        end
      end

      -- On single-monitor setups, show C workspaces only if they have windows (or are focused); D stays hidden
      if not multi_monitor then
        for _, cws in ipairs(c_workspaces) do
          if cws == ws and space_items[cws] then
            local has_windows = result and result ~= ""
            local show = has_windows or cws == focused_workspace
            space_items[cws]:set({ drawing = show and "on" or "off" })
          end
        end
      end
    end
  )
end

local handler = sbar.add("item", "space_handler", { drawing = "off" })

handler:subscribe("aerospace_workspace_change", function(env)
  local focused = env.FOCUSED_WORKSPACE or ""
  if focused ~= "" then
    highlight(focused)
    update_icons(focused)
    if env.PREV_WORKSPACE and env.PREV_WORKSPACE ~= "" then
      update_icons(env.PREV_WORKSPACE)
    end
  end
end)

-- Single monitor detection
sbar.add("event", "display_change")
local display_handler = sbar.add("item", "display_handler", { drawing = "off" })

local function check_displays()
  sbar.exec("aerospace list-monitors --count 2>/dev/null || echo 1", function(result)
    local count = tonumber((result or "1"):match("%d+")) or 1
    multi_monitor = count > 1
    if multi_monitor then
      -- Dual monitor: C and D on display 2, all visible
      for _, ws in ipairs(secondary_workspaces) do
        if space_items[ws] then
          space_items[ws]:set({ display = 2, drawing = "on" })
        end
      end
      return
    end

    -- Single monitor: C workspaces move to display 1, show if non-empty or focused
    for _, ws in ipairs(c_workspaces) do
      if space_items[ws] then
        space_items[ws]:set({ display = 1 })
        sbar.exec("aerospace list-windows --workspace " .. ws .. " --count 2>/dev/null || echo 0", function(win_count)
          local n = tonumber((win_count or "0"):match("%d+")) or 0
          local show = (n > 0) or (ws == focused_workspace)
          space_items[ws]:set({ drawing = show and "on" or "off" })
        end)
      end
    end

    -- Single monitor: D workspaces hidden
    for _, ws in ipairs(d_workspaces) do
      if space_items[ws] then
        space_items[ws]:set({ drawing = "off" })
      end
    end
  end)
end

display_handler:subscribe("display_change", function(_) check_displays() end)

-- Init
sbar.exec("aerospace list-workspaces --focused", function(result)
  local focused = (result or ""):match("^%s*(.-)%s*$")
  if focused ~= "" then highlight(focused) end
end)
for _, ws in ipairs(all_workspaces) do update_icons(ws) end
check_displays()
