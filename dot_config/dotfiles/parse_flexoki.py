#!/usr/bin/env python3
"""Flexoki palette definitions.

Flexoki is a fixed palette (not parsed from source files). Values taken
from the canonical Flexoki CSS spec and Helix port.

Most apps (Ghostty, Helix, Zed) ship Flexoki themes natively — this
palette feeds the generators that don't: sketchybar, borders, wallpaper,
obsidian, glamour.

Flexoki's accent ramp runs 50 (lightest) → 950 (darkest), 13 stops per hue.
Light themes use 600-level accents; dark themes use 400-level.
Temperature variants (warmer/cooler/faint) are mapped to adjacent ramp stops.
"""

# --- Base ramp (neutral grayscale) ---
# paper=#FFFCF0  50=#F2F0E5  100=#E6E4D9  150=#DAD8CE  200=#CECDC3
# 300=#B7B5AC  400=#9F9D96  500=#878580  600=#6F6E69  700=#575653
# 800=#403E3C  850=#343331  900=#282726  950=#1C1B1A  black=#100F0F

# --- Accent ramp reference (per hue, 50→950) ---
# red:     FFE1D5 FFCABB FDB2A2 F89A8A E8705F D14D41 C03E35 AF3029 942822 6C201C 551B18 3E1715 261312
# orange:  FFE7CE FED3AF FCC192 F9AE77 EC8B49 DA702C CB6120 BC5215 9D4310 71320D 59290D 40200D 27180E
# yellow:  FAEEC6 F6E2A0 F1D67E ECCB60 DFB431 D0A215 BE9207 AD8301 8E6B01 664D01 503D02 3A2D04 241E08
# green:   EDEECF DDE2B2 CDD597 BEC97E A0AF54 879A39 768D21 66800B 536907 3D4C07 313D07 252D09 1A1E0C
# cyan:    DDF1E4 BFE8D9 A2DECE 87D3C3 5ABDAC 3AA99F 2F968D 24837B 1C6C66 164F4A 143F3C 122F2C 101F1D
# blue:    E1ECEB C6DDE8 ABCFE2 92BFDB 66A0C8 4385BE 3171B2 205EA6 1A4F8C 163B66 133051 12253B 101A24
# purple:  F0EAEC E2D9E9 D3CAE6 C4B9E0 A699D0 8B7EC8 735EB5 5E409D 4F3685 3C2A62 31234E 261C39 1A1623
# magenta: FEE4E5 FCCFDA F9B9CF F4A4C2 E47DA8 CE5D97 B74583 A02F6F 87285E 641F46 4F1B39 39172B 24131D


FLEXOKI_LIGHT = {
    # --- Surfaces ---
    "bg-main": "#FFFCF0",
    "bg-dim": "#F2F0E5",
    "bg-active": "#E6E4D9",
    "bg-inactive": "#E6E4D9",
    "bg-hl-line": "#F2F0E5",
    "bg-region": "#DAD8CE",
    "bg-popup": "#F2F0E5",
    "bg-hover": "#DAD8CE",
    "bg-mode-line-active": "#CECDC3",
    "border": "#CECDC3",

    # --- Foreground ---
    "fg-main": "#100F0F",
    "fg-dim": "#6F6E69",
    "fg-alt": "#878580",
    "cursor": "#100F0F",

    # --- Accents (600-level for light) ---
    "red": "#AF3029",
    "orange": "#BC5215",
    "yellow": "#AD8301",
    "green": "#66800B",
    "cyan": "#24837B",
    "blue": "#205EA6",
    "magenta": "#5E409D",

    # --- Warmer (400-level — more saturated/vivid) ---
    "red-warmer": "#D14D41",
    "orange-warmer": "#DA702C",
    "yellow-warmer": "#D0A215",
    "green-warmer": "#879A39",
    "cyan-warmer": "#3AA99F",
    "blue-warmer": "#4385BE",
    "magenta-warmer": "#A02F6F",

    # --- Cooler (700-level — darker/more subdued) ---
    "red-cooler": "#942822",
    "green-cooler": "#536907",
    "magenta-cooler": "#4F3685",
    "cyan-cooler": "#1C6C66",

    # --- Faint (200-level — soft/washed out) ---
    "red-faint": "#F89A8A",
    "green-faint": "#BEC97E",
    "yellow-faint": "#ECCB60",
    "blue-faint": "#92BFDB",
    "magenta-faint": "#C4B9E0",
    "cyan-faint": "#87D3C3",

    # --- Diff ---
    "bg-added": "#EDEECF",
    "bg-removed": "#FFE1D5",
    "bg-changed": "#FAEEC6",
    "fg-added": "#66800B",
    "fg-removed": "#AF3029",
    "fg-changed": "#AD8301",
    "bg-added-fringe": "#66800B",
    "bg-removed-fringe": "#AF3029",
    "bg-changed-fringe": "#AD8301",

    # --- Subtle backgrounds ---
    "bg-red-subtle": "#FFE1D5",
    "bg-blue-subtle": "#E1ECEB",
}

FLEXOKI_DARK = {
    # --- Surfaces ---
    "bg-main": "#100F0F",
    "bg-dim": "#1C1B1A",
    "bg-active": "#282726",
    "bg-inactive": "#282726",
    "bg-hl-line": "#1C1B1A",
    "bg-region": "#343331",
    "bg-popup": "#1C1B1A",
    "bg-hover": "#343331",
    "bg-mode-line-active": "#403E3C",
    "border": "#403E3C",

    # --- Foreground ---
    "fg-main": "#CECDC3",
    "fg-dim": "#878580",
    "fg-alt": "#575653",
    "cursor": "#CECDC3",

    # --- Accents (400-level for dark) ---
    "red": "#D14D41",
    "orange": "#DA702C",
    "yellow": "#D0A215",
    "green": "#879A39",
    "cyan": "#3AA99F",
    "blue": "#4385BE",
    "magenta": "#8B7EC8",

    # --- Warmer (300-level — brighter/more vivid) ---
    "red-warmer": "#E8705F",
    "orange-warmer": "#EC8B49",
    "yellow-warmer": "#DFB431",
    "green-warmer": "#A0AF54",
    "cyan-warmer": "#5ABDAC",
    "blue-warmer": "#66A0C8",
    "magenta-warmer": "#CE5D97",

    # --- Cooler (500-level — slightly muted) ---
    "red-cooler": "#C03E35",
    "green-cooler": "#768D21",
    "magenta-cooler": "#735EB5",
    "cyan-cooler": "#2F968D",

    # --- Faint (700-800 — dim against dark bg) ---
    "red-faint": "#6C201C",
    "green-faint": "#3D4C07",
    "yellow-faint": "#664D01",
    "blue-faint": "#163B66",
    "magenta-faint": "#3C2A62",
    "cyan-faint": "#164F4A",

    # --- Diff ---
    "bg-added": "#252D09",
    "bg-removed": "#3E1715",
    "bg-changed": "#3A2D04",
    "fg-added": "#879A39",
    "fg-removed": "#D14D41",
    "fg-changed": "#D0A215",
    "bg-added-fringe": "#879A39",
    "bg-removed-fringe": "#D14D41",
    "bg-changed-fringe": "#D0A215",

    # --- Subtle backgrounds ---
    "bg-red-subtle": "#3E1715",
    "bg-blue-subtle": "#12253B",
}

# Flexoki's syntax philosophy (from Steph Ango's design doc).
# Maps abstract role → palette key name.
FLEXOKI_ROLES = {
    "keyword":      "green",       # "important control flow"
    "function":     "orange",      # "distinction without aggression"
    "string":       "cyan",        # "high legibility pairing"
    "type":         "yellow",
    "variable":     "blue",        # "neutral, readable accent"
    "constant":     "magenta",     # purple — "categorical separation"
    "comment":      "fg-dim",      # "lower cognitive weight"
    "operator":     "fg-dim",      # "background support"
    "builtin":      "magenta-warmer",
    "preprocessor": "red",
    "docstring":    "cyan",
    "number":       "magenta",     # purple
    "property":     "blue",
    "tag":          "blue",
    "attribute":    "yellow",
    "namespace":    "red",
    "constructor":  "green",
}


def parse_flexoki() -> dict:
    return {
        "flexoki-light": {
            "variant": "light",
            "colors": FLEXOKI_LIGHT,
            "semantic": {},
            "ghostty_theme": "Flexoki Light",
        },
        "flexoki-dark": {
            "variant": "dark",
            "colors": FLEXOKI_DARK,
            "semantic": {},
            "ghostty_theme": "Flexoki Dark",
        },
    }
