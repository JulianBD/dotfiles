local sbar = require("sketchybar")
local colors = require("colors")
local pips = require("pips")

-- Two-tier dial of the current hour, coarsest first, both rendered as
-- alpha-graded rows of the same "■" glyph (see pips.create_alpha_row).
-- This is positional, like digits: every tier shows only units it has
-- *completed*, because the tier below it is already showing the current
-- (partial) one counting up. So the maxima are one short of the naive
-- division:
--   hour tier: 5 x 10-minute blocks -- 60/10 = 6 blocks per hour, but
--     the 6th is never "complete" before the hour rolls over; minutes
--     0-9 are shown by the half tier and bar counting up from empty.
--   half tier: 1 x 5-minute half -- the current 5-minute span is what
--     the bar row below renders, so the only thing left to say is
--     whether this 10-minute block's first half is already behind us.
-- 60's divisors make this scale to other granularities later (e.g.
-- thirds/quarters) without changing the approach, just the tier
-- definitions below (count = 60/unit_minutes - 1 per tier).
local HOUR_TIER = { unit_minutes = 10, count = 5 }
local HALF_TIER = { unit_minutes = 5, count = 1 }

-- Real-time progress through the current 5-minute window: 10 items,
-- one per 30-second segment, ticking every second.
local BAR_UNIT_MINUTES = 5
local BAR_SEGMENTS = 10
local SECONDS_PER_SEGMENT = (BAR_UNIT_MINUTES * 60) / BAR_SEGMENTS

local GLYPH = "■"

-- The divider's *icon* padding is what spaces it (8 on each side, plus
-- default.lua's background 4/4 = GAP on each side). Its label padding
-- must be zeroed even though the label is drawing="off": default.lua
-- reserves label padding_right=10 regardless of drawing, which lands on
-- one side only and pushes the "|" 10px off-center. An earlier attempt
-- at this zeroed the whole recipe, icon padding included -- that made
-- the "|" flush against its neighbors and the zeroing got reverted
-- wholesale. Only the label/background reservations are the problem;
-- the explicit icon padding is the part doing the real work.
local GAP = 12 -- one consistent gap unit between every part of the dial
local function add_divider(name)
  return sbar.add("item", name, {
    position = "right",
    icon = { string = "|", color = colors.clock, padding_left = GAP - 4, padding_right = GAP - 4 },
    label = { drawing = "off", padding_left = 0, padding_right = 0 },
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
-- GAP - 6: right_bracket.lua's bracket already adds padding_right=6
-- between the last item and the pill wall, so the row only supplies the
-- remainder to land on the same GAP as every divider.
local bar_items = pips.create_alpha_row(sbar, "clock.bar", BAR_SEGMENTS, colors.clock, GLYPH, GAP - 6)
local divider2 = add_divider("clock.divider2")
local half_items = pips.create_alpha_row(sbar, "clock.half", HALF_TIER.count, colors.clock, GLYPH, 0)
local divider1 = add_divider("clock.divider1")
local hour_items = pips.create_alpha_row(sbar, "clock.hour", HOUR_TIER.count, colors.clock, GLYPH, 0)

local clock = sbar.add("item", "clock", {
  position = "right",
  update_freq = 1, -- the bar needs second-level ticks
  -- The icon carries no glyph, but default.lua's icon padding (10+10)
  -- is reserved whether or not anything is drawn -- that was 20px of
  -- dead space wedged between the battery item and the date text.
  -- drawing="off" alone does not reclaim it; the padding has to go too.
  icon = {
    string = "",
    drawing = "off",
    color = colors.clock,
    padding_left = 0,
    padding_right = 0,
  },
  -- GAP - 4, the remaining 4 coming from default.lua's background
  -- padding_right, so text -> hour row matches every divider's gap.
  label = {
    color = colors.clock,
    padding_right = GAP - 4,
  },
})

-- No +1 anywhere: floor() already yields *completed* units, which is
-- exactly what each tier renders (see the tier comments above). Every
-- tier therefore starts each of its cycles empty and fills as the finer
-- tiers below it roll over -- at :00 the whole dial is dark except the
-- bar's first segment.
local function update_dial(min)
  local filled_hour = math.floor(min / HOUR_TIER.unit_minutes)
  pips.update_alpha_row(hour_items, filled_hour, colors.clock)

  local within_block = min % HOUR_TIER.unit_minutes
  local filled_half = math.floor(within_block / HALF_TIER.unit_minutes)
  pips.update_alpha_row(half_items, filled_half, colors.clock)
end

local function update_bar(min, sec)
  local elapsed = (min % BAR_UNIT_MINUTES) * 60 + sec
  local filled = math.floor(elapsed / SECONDS_PER_SEGMENT)
  pips.update_alpha_row(bar_items, filled, colors.clock)
end

-- os.date rather than sbar.exec("date"): at update_freq=1 the exec version
-- spawned a subprocess every second (~86k/day) and filled sketchybar's error
-- log with "date: stdout: Broken pipe" — replies the exec layer dropped rather
-- than delivered. Those dropped replies are the same failure that used to
-- freeze the workspace icons (see spaces.lua), so the fewer execs on a timer,
-- the better. The time is local to this process anyway; nothing needs a shell.
clock:subscribe("routine", function()
  local t = os.date("*t")
  clock:set({ label = { string = os.date("%b %d  %H") } })
  update_dial(t.min)
  update_bar(t.min, t.sec)
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
