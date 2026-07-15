-- Progress-pip rendering: represent a count out of a total as a string
-- of filled/empty glyphs, e.g. render(3, 6, "●", "○") -> "●●●○○○".
-- Shared by any item that wants a dial-style progress indicator at a
-- given granularity (clock, but usable elsewhere too).

local M = {}

-- filled: how many units are complete (clamped to [0, total])
-- total: how many units make up the full dial
-- filled_char / empty_char: glyphs for a complete / incomplete unit
function M.render(filled, total, filled_char, empty_char)
  filled = math.max(0, math.min(filled, total))
  return string.rep(filled_char, filled) .. string.rep(empty_char, total - filled)
end

-- Swap a 0xAARRGGBB color's alpha byte, keeping its RGB. Same technique
-- as the `faint` helper in items/spaces.lua. Genuine alpha blending —
-- unlike a "light shade" glyph, which is a dithered/stippled dot
-- pattern baked into the font's glyph outline, not real transparency,
-- and collapses to a flat block at small point sizes.
function M.with_alpha(color, alpha_byte)
  return (color & 0x00FFFFFF) | alpha_byte
end

return M
