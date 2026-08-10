local sbar = require("sketchybar")
local colors = require("colors")
local icons = require("icons")

-- Workspace layout:
--   Single monitor: A1-A4 B1-B4 C1-C4 in one pill, D hidden
--   Dual monitor:   A1-A4 B1-B4 on display 1, C1-C4 D1-D4 on display 2
local ab_workspaces = { "A1","A2","A3","A4","B1","B2","B3","B4" }
local c_workspaces  = { "C1","C2","C3","C4" }
local d_workspaces  = { "D1","D2","D3","D4" }

-- Display labels match the keybind character for each workspace
local keybind_label = {
  A1 = "1", A2 = "2", A3 = "3", A4 = "4",
  B1 = "5", B2 = "6", B3 = "7", B4 = "8",
  C1 = "9", C2 = "0", C3 = "[", C4 = "]",
  D1 = ";", D2 = "'", D3 = ",", D4 = ".",
}

-- y_offset for glyphs that sit low in the label font
local label_y_offset = {
  C2 = 1,
  C3 = 2, C4 = 2,
  D1 = 2, D2 = -3, D3 = 4, D4 = 4,
}

local all_workspaces = {}
for _, ws in ipairs(ab_workspaces) do table.insert(all_workspaces, ws) end
for _, ws in ipairs(c_workspaces) do table.insert(all_workspaces, ws) end
for _, ws in ipairs(d_workspaces) do table.insert(all_workspaces, ws) end

-- Fade a color's alpha to ~40%
local function faint(color)
  return (color & 0x00FFFFFF) | 0x66000000
end

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
      label = {
        string = keybind_label[ws] or ws,
        font = "FiraCode Nerd Font:Bold:10.0",
        color = faint(colors.text_muted),
        padding_left = 4,
        padding_right = 6,
        y_offset = label_y_offset[ws] or 0,
        drawing = "on",
      },
      icon = { drawing = "off" },
      click_script = "aerospace workspace " .. ws .. " 2>/dev/null",
    })

    space_items[ws] = item
    table.insert(items, "space." .. ws)
  end
  return items
end

-- Create all items: A+B on display 1, C+D on display 1 initially (check_displays moves them)
local ab_item_names = create_items(ab_workspaces, 1)
local c_item_names  = create_items(c_workspaces, 1)
local d_item_names  = create_items(d_workspaces, 1)

-- Primary bracket: A+B+C (on single monitor all show; on dual monitor C moves to display 2
-- and the bracket auto-shrinks to just A+B visible on display 1)
local primary_all = {}
for _, n in ipairs(ab_item_names) do table.insert(primary_all, n) end
for _, n in ipairs(c_item_names) do table.insert(primary_all, n) end

sbar.add("bracket", "workspaces_primary", primary_all, {
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

-- Secondary bracket: C+D (on dual monitor both show on display 2; on single monitor
-- C is on display 1 so only D would show here, but D is hidden on single monitor)
local secondary_all = {}
for _, n in ipairs(c_item_names) do table.insert(secondary_all, n) end
for _, n in ipairs(d_item_names) do table.insert(secondary_all, n) end

sbar.add("bracket", "workspaces_secondary", secondary_all, {
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
      label = { color = faint(colors.text_muted) },
    })
  end
  -- Highlight new
  focused_workspace = new_ws
  if new_ws ~= "" and space_items[new_ws] then
    local c, bg = group_colors(new_ws)
    space_items[new_ws]:set({
      background = { color = bg },
      icon = { color = c },
      label = { color = faint(c) },
    })
  end
end

-- Focused workspace's icons take the group accent, everything else stays muted.
-- highlight() owns this too; both must agree, or whichever runs last wins and
-- the focused pill ends up with an accented label above muted icons.
local function icon_color_for(ws)
  if ws == focused_workspace then
    local c = group_colors(ws)
    return c
  end
  return colors.text_muted
end

-- Last icon string pushed per workspace. refresh_all_icons() polls on a timer,
-- so without this every tick would send a :set for all 16 items forever; a
-- steady desktop should cost zero messages.
local last_icon_str = {}

-- Apply the icon set for one workspace item
local function set_ws_icons(ws, apps)
  local item = space_items[ws]
  if not item then return end
  local icon_str = ""
  for _, app in ipairs(apps) do
    icon_str = icon_str .. app_icon(app)
  end
  if last_icon_str[ws] == icon_str then return end
  last_icon_str[ws] = icon_str
  if icon_str == "" then
    local pl = ws == "C2" and 8 or 6
    local pr = ws == "C2" and 8 or 10
    -- Blank the string as well as hiding it: a leftover string would flash the
    -- previous workspace's apps if anything turned drawing back on first.
    item:set({ icon = { string = "", drawing = "off" }, label = { font = "FiraCode Nerd Font:Bold:14.0", padding_left = pl, padding_right = pr } })
  else
    item:set({ icon = { string = icon_str, font = "sketchybar-app-font:Regular:14.0", color = icon_color_for(ws), padding_left = 6, padding_right = 0, drawing = "on" }, label = { font = "FiraCode Nerd Font:Bold:10.0", padding_left = 2, padding_right = 6 } })
  end
end

-- Refresh app icons for ALL workspaces with a single aerospace call.
-- One exec (~40ms) instead of one per workspace — icons stay current
-- everywhere and the bar never queues up a burst of shell-outs.
--
-- The latch is timed out rather than cleared only on reply. It used to be a
-- plain boolean set true before the exec and false inside the callback, which
-- meant a single dropped callback wedged icon refresh permanently: every later
-- request returned early and the bar showed a frozen snapshot until sketchybar
-- was restarted.
local REFRESH_STALE_AFTER = 5
local refresh_started_at = nil
local refresh_pending = false

local function refresh_all_icons()
  if refresh_started_at and (os.time() - refresh_started_at) < REFRESH_STALE_AFTER then
    -- Coalesce, but remember the request: the in-flight aerospace snapshot was
    -- taken before this change, so dropping it outright would lose the update.
    refresh_pending = true
    return
  end
  refresh_started_at = os.time()
  refresh_pending = false
  sbar.exec(
    "aerospace list-windows --all --format '%{workspace}|%{app-name}' 2>/dev/null",
    function(result)
      refresh_started_at = nil
      local by_ws = {}
      for line in (result or ""):gmatch("[^\r\n]+") do
        local ws, app = line:match("^%s*(.-)%s*|%s*(.-)%s*$")
        if ws and app and app ~= "" then
          by_ws[ws] = by_ws[ws] or {}
          local seen = false
          for _, a in ipairs(by_ws[ws]) do
            if a == app then seen = true break end
          end
          if not seen then table.insert(by_ws[ws], app) end
        end
      end
      for _, ws in ipairs(all_workspaces) do
        set_ws_icons(ws, by_ws[ws] or {})
      end
      if refresh_pending then refresh_all_icons() end
    end
  )
end

-- update_freq drives the poll below. aerospace only pushes on workspace
-- *switch*, so opening, closing, or moving a window into another workspace
-- produces no event at all — polling is the only way those land in real time.
local handler = sbar.add("item", "space_handler", { drawing = "off", update_freq = 1 })

handler:subscribe("aerospace_workspace_change", function(env)
  local focused = env.FOCUSED_WORKSPACE or ""
  if focused ~= "" then
    highlight(focused)
  end
  refresh_all_icons()
end)

-- Windows open/close/move without a workspace switch; front-app changes are
-- a cheap proxy for "something changed", and the refresh is a single exec.
handler:subscribe("front_app_switched", function(_)
  refresh_all_icons()
end)

-- front_app_switched misses a lot: a second window of the already-focused app,
-- a window closing, a window moved to a workspace you aren't switching to.
-- The poll catches all of it. Cost is bounded — one ~40ms exec, and set_ws_icons
-- diffs, so an unchanged desktop sends nothing.
handler:subscribe("routine", function(_)
  refresh_all_icons()
end)

-- Display management: move C+D between monitors
sbar.add("event", "display_change")
local display_handler = sbar.add("item", "display_handler", { drawing = "off" })

local function check_displays()
  sbar.exec("aerospace list-monitors --count 2>/dev/null || echo 1", function(result)
    local count = tonumber((result or "1"):match("%d+")) or 1
    multi_monitor = count > 1
    if multi_monitor then
      -- Dual monitor: C+D on display 2
      for _, ws in ipairs(c_workspaces) do
        if space_items[ws] then
          space_items[ws]:set({ display = 2, drawing = "on" })
        end
      end
      for _, ws in ipairs(d_workspaces) do
        if space_items[ws] then
          space_items[ws]:set({ display = 2, drawing = "on" })
        end
      end
      -- Restore edge padding: B4 is last in its bracket, C1 is first in its bracket
      if space_items["B4"] then
        space_items["B4"]:set({ background = { padding_right = 6 } })
      end
      if space_items["C1"] then
        space_items["C1"]:set({ background = { padding_left = 6 } })
      end
    else
      -- Single monitor: C on display 1, D hidden
      for _, ws in ipairs(c_workspaces) do
        if space_items[ws] then
          space_items[ws]:set({ display = 1, drawing = "on" })
        end
      end
      for _, ws in ipairs(d_workspaces) do
        if space_items[ws] then
          space_items[ws]:set({ drawing = "off" })
        end
      end
      -- Close the gap: B4 and C1 are mid-bracket on single monitor
      if space_items["B4"] then
        space_items["B4"]:set({ background = { padding_right = 2 } })
      end
      if space_items["C1"] then
        space_items["C1"]:set({ background = { padding_left = 2 } })
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
refresh_all_icons()
check_displays()
