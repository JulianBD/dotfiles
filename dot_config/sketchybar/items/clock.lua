local sbar = require("sketchybar")
local colors = require("colors")
local pips = require("pips")

-- Two-tier dial of the current hour, coarsest first, both rendered as
-- alpha-graded rows of the same "■" glyph (see pips.create_alpha_row):
--   hour tier: 6 x 10-minute blocks (60 / 10 = 6)
--   half tier: 2 x 5-minute halves of the *current* 10-minute block
-- 60's divisors make this scale to other granularities later (e.g.
-- thirds/quarters) without changing the approach, just the tier
-- definitions below.
local HOUR_TIER = { unit_minutes = 10, count = 6 }
local HALF_TIER = { unit_minutes = 5, count = 2 }

-- Real-time progress through the current 5-minute window: 10 items,
-- one per 30-second segment, ticking every second.
local BAR_UNIT_MINUTES = 5
local BAR_SEGMENTS = 10
local SECONDS_PER_SEGMENT = (BAR_UNIT_MINUTES * 60) / BAR_SEGMENTS

local GLYPH = "■"

-- Matches the existing standalone "separator" item's own recipe: only
-- icon padding is set. Unlike the alpha rows, background/label padding
-- is NOT zeroed here -- that zeroing is for tightly-packed *repeated*
-- items where default.lua's reserved space compounds across many of
-- them; for one single divider, default.lua's normal padding is what
-- actually produces its visible gap (zeroing it made the "|" flush
-- against its neighbors).
local function add_divider(name)
  return sbar.add("item", name, {
    position = "right",
    icon = { string = "|", color = colors.clock, padding_left = 8, padding_right = 8 },
    label = { drawing = "off" },
  })
end

-- position="right" stacks first-added-rightmost, and this whole module
-- loads before battery/volume/etc, so whatever's added first here ends
-- up at the screen's absolute rightmost edge. To read left to right as
-- [date/hour text] [hour row] | [half row] | [bar row], add order
-- (rightmost first) is: bar row, divider, half row, divider, hour row,
-- THEN the clock text item last.
-- Rows next to a divider get edge_padding=0: the divider's own
-- padding_left/right=8 already provides the gap on both sides, so
-- adding more here would make that side wider than the other (a
-- lopsided "|" instead of one centered in even space). Only the bar's
-- far edge, against the pill wall rather than a divider, needs its own
-- padding.
local bar_items = pips.create_alpha_row(sbar, "clock.bar", BAR_SEGMENTS, colors.clock, GLYPH, 6)
local divider2 = add_divider("clock.divider2")
local half_items = pips.create_alpha_row(sbar, "clock.half", HALF_TIER.count, colors.clock, GLYPH, 0)
local divider1 = add_divider("clock.divider1")
local hour_items = pips.create_alpha_row(sbar, "clock.hour", HOUR_TIER.count, colors.clock, GLYPH, 0)

local clock = sbar.add("item", "clock", {
  position = "right",
  update_freq = 1, -- the bar needs second-level ticks
  icon = {
    string = "",
    color = colors.clock,
  },
  label = {
    color = colors.clock,
  },
})

local function update_dial(min)
  local within_hour = min % (HOUR_TIER.unit_minutes * HOUR_TIER.count)
  local filled_hour = math.floor(within_hour / HOUR_TIER.unit_minutes) + 1
  pips.update_alpha_row(hour_items, filled_hour, colors.clock)

  local within_block = within_hour % HOUR_TIER.unit_minutes
  local filled_half = math.floor(within_block / HALF_TIER.unit_minutes) + 1
  pips.update_alpha_row(half_items, filled_half, colors.clock)
end

local function update_bar(min, sec)
  local elapsed = (min % BAR_UNIT_MINUTES) * 60 + sec
  local filled = math.floor(elapsed / SECONDS_PER_SEGMENT)
  pips.update_alpha_row(bar_items, filled, colors.clock)
end

clock:subscribe("routine", function()
  sbar.exec("date '+%b %d %H %M %S'", function(result)
    local trimmed = (result or ""):match("^%s*(.-)%s*$")
    local date, hour, min, sec = trimmed:match("^(.+)%s+(%d+)%s+(%d+)%s+(%d+)$")
    min, sec = tonumber(min), tonumber(sec)
    clock:set({ label = { string = date .. "  " .. hour } })
    update_dial(min)
    update_bar(min, sec)
  end)
end)

-- Exposed so right_bracket.lua can include all of this module's item
-- names in the pill bracket without hardcoding (and risking drift
-- from) the counts.
local item_names = { "clock" }
for i = 1, HOUR_TIER.count do table.insert(item_names, "clock.hour." .. i) end
table.insert(item_names, "clock.divider1")
for i = 1, HALF_TIER.count do table.insert(item_names, "clock.half." .. i) end
table.insert(item_names, "clock.divider2")
for i = 1, BAR_SEGMENTS do table.insert(item_names, "clock.bar." .. i) end

return { item_names = item_names }
