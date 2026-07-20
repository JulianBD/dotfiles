-- Alpha-graded progress rows: build a strip of N sketchybar items, all
-- the same glyph, where each unit's *color opacity* (not glyph shape)
-- marks whether it's reached yet. A single sketchybar label/icon can
-- only carry one color, so this is the only way to get a real
-- per-unit gradient -- a filled/outline glyph pair or a dithered
-- "shade" glyph both bake the distinction into the font's glyph
-- outline, and shade glyphs in particular collapse to a flat block at
-- small point sizes instead of reading as a fade.

local M = {}

-- Swap a 0xAARRGGBB color's alpha byte, keeping its RGB. Same technique
-- as the `faint` helper in items/spaces.lua.
function M.with_alpha(color, alpha_byte)
  return (color & 0x00FFFFFF) | alpha_byte
end

local EMPTY_ALPHA = 0x66000000
local FULL_ALPHA = 0xff000000

-- sbar: the require()'d "sketchybar" module (passed in so this file has
--   no direct sketchybar dependency of its own).
-- id_prefix: unique item-name prefix, e.g. "clock.hour" -> "clock.hour.1".
-- count: number of units in the row.
-- color: base 0xAARRGGBB color; only the alpha byte varies per unit.
-- glyph: the single character drawn for every unit (e.g. "■").
-- edge_padding: right padding on the row's rightmost unit, for
--   breathing room against whatever follows (a divider, the pill edge).
--
-- position="right" stacks first-added-rightmost, so this adds units in
-- reverse (count down to 1): the last unit (rightmost on screen) is
-- added first, the first unit (leftmost) added last. Combined across
-- multiple rows/dividers in one module, add everything for the
-- rightmost row first and work left, ending with whatever text should
-- appear furthest left.
function M.create_alpha_row(sbar, id_prefix, count, color, glyph, edge_padding)
  local items = {}
  for i = count, 1, -1 do
    local right_pad = (i == count) and (edge_padding or 6) or 1
    items[i] = sbar.add("item", id_prefix .. "." .. i, {
      position = "right",
      icon = {
        string = glyph,
        color = M.with_alpha(color, EMPTY_ALPHA),
        padding_left = 0,
        padding_right = right_pad,
      },
      -- default.lua reserves label/background padding even while
      -- hidden (10px + 4px+4px) -- zero it out or tightly-packed rows
      -- like this end up spaced ~18px apart instead of forming a
      -- continuous strip.
      label = { drawing = "off", padding_left = 0, padding_right = 0 },
      background = { padding_left = 0, padding_right = 0 },
    })
  end
  return items
end

-- Set alpha per unit in a row built by create_alpha_row: full opacity
-- for the first `filled` units (reached so far), faint for the rest.
function M.update_alpha_row(items, filled, color)
  for i, item in ipairs(items) do
    local alpha = (i <= filled) and FULL_ALPHA or EMPTY_ALPHA
    item:set({ icon = { color = M.with_alpha(color, alpha) } })
  end
end

return M
