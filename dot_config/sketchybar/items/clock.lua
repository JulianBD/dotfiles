local sbar = require("sketchybar")
local colors = require("colors")
local pips = require("pips")

-- Two-tier dial of the current hour, coarsest first:
--   circles: 6 x 10-minute blocks (60 / 10 = 6)
--   squares: 2 x 5-minute halves of the *current* 10-minute block
-- 60's divisors make this scale to other granularities later (e.g.
-- thirds/quarters) without changing the rendering approach, just the
-- tier definitions below.
local TIERS = {
  { unit_minutes = 10, count = 6, filled_char = "●", empty_char = "○" },
  { unit_minutes = 5,  count = 2, filled_char = "■", empty_char = "□" },
}

local function render_dial(min)
  local parts = {}
  local remainder = min
  for _, tier in ipairs(TIERS) do
    local span = tier.unit_minutes * tier.count -- minutes this tier covers
    local within = remainder % span
    local filled = math.floor(within / tier.unit_minutes) + 1
    table.insert(parts, pips.render(filled, tier.count, tier.filled_char, tier.empty_char))
    remainder = within % tier.unit_minutes
  end
  return table.concat(parts, " | ")
end

-- Real-time progress through the current 5-minute square, as a row of
-- small items whose color *opacity* fades in per 30-second segment.
-- A single sketchybar label/icon can only carry one color, so a
-- character-density trick (e.g. shade glyphs) is the only way to fake
-- a gradient in one string -- and shade glyphs are a dithered dot
-- pattern baked into the font, not real alpha, so they read as a flat
-- block instead of a fade. Separate items give each segment its own
-- color, so the fade is genuine transparency.
local BAR_UNIT_MINUTES = 5
local BAR_SEGMENTS = 10
local SECONDS_PER_SEGMENT = (BAR_UNIT_MINUTES * 60) / BAR_SEGMENTS
local EMPTY_ALPHA = 0x66000000
local FULL_ALPHA = 0xff000000

-- position="right" stacks first-added-rightmost, and this whole module
-- loads before battery/volume/etc, so whatever we add first here ends
-- up at the screen's absolute rightmost edge. To read left to right as
-- [date/hour/dial] | [seg1]..[seg10], add order (rightmost first) must
-- be: segment 10, ..., segment 1, THEN the clock text item last -- the
-- text has to be added *after* the segments to land to their left.
local bar_items = {}
for i = BAR_SEGMENTS, 1, -1 do
  -- Segment 10 sits at the bar's far edge, against the pill itself, so
  -- it needs real breathing room; the rest just need a hairline gap
  -- from their neighbor.
  local right_pad = (i == BAR_SEGMENTS) and 6 or 1
  bar_items[i] = sbar.add("item", "clock.bar." .. i, {
    position = "right",
    icon = {
      string = "■",
      color = pips.with_alpha(colors.clock, EMPTY_ALPHA),
      padding_left = 0,
      padding_right = right_pad,
    },
    -- default.lua reserves label/background padding even while hidden
    -- (10px + 4px+4px) -- zero it out or these 10 tiny items end up
    -- spaced ~18px apart instead of forming a tight bar.
    label = { drawing = "off", padding_left = 0, padding_right = 0 },
    background = { padding_left = 0, padding_right = 0 },
  })
end

local clock = sbar.add("item", "clock", {
  position = "right",
  update_freq = 1, -- the bar above needs second-level ticks
  icon = {
    string = "",
    color = colors.clock,
  },
  label = {
    color = colors.clock,
  },
})

local function update_bar(min, sec)
  local elapsed = (min % BAR_UNIT_MINUTES) * 60 + sec
  local filled = math.floor(elapsed / SECONDS_PER_SEGMENT)
  for i, item in ipairs(bar_items) do
    local alpha = i <= filled and FULL_ALPHA or EMPTY_ALPHA
    item:set({ icon = { color = pips.with_alpha(colors.clock, alpha) } })
  end
end

clock:subscribe("routine", function()
  sbar.exec("date '+%b %d %H %M %S'", function(result)
    local trimmed = (result or ""):match("^%s*(.-)%s*$")
    local date, hour, min, sec = trimmed:match("^(.+)%s+(%d+)%s+(%d+)%s+(%d+)$")
    min, sec = tonumber(min), tonumber(sec)
    local dial = render_dial(min)
    -- Trailing "|" is the divider between the dial and the bar segments,
    -- padded to match the " | " already used between circles and
    -- squares so the squares sit centered between both dividers.
    clock:set({ label = { string = date .. "  " .. hour .. "  " .. dial .. " |" } })
    update_bar(min, sec)
  end)
end)

-- Exposed so right_bracket.lua can include the bar segment item names in
-- the pill bracket without hardcoding (and risking drift from) the count.
return { BAR_SEGMENTS = BAR_SEGMENTS }
