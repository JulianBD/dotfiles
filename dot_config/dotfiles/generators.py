#!/usr/bin/env python3
"""Theme generators: translate a unified palette into per-app config files.

Each generator is a function that takes (palette, name, variant) and writes
the appropriate config file. palette is a flat dict of {key: "#hex"}.

Generators pull keys directly from the palette. Missing keys are OK —
the .get() default is explicit per-generator, not a generic fallback chain.
"""

import json
import subprocess
from pathlib import Path


def hex_strip(color: str) -> str:
    """Strip the '#' prefix from a hex color."""
    return color.lstrip("#")


def get(palette: dict, key: str, fallback: str | None = None) -> str | None:
    """Look up a palette key, returning fallback (or None) if absent."""
    return palette.get(key, fallback)


def require(palette: dict, *keys: str) -> str:
    """Return the first key that exists in the palette, or raise."""
    for k in keys:
        if k in palette:
            return palette[k]
    raise KeyError(f"None of {keys} found in palette")


# ---------------------------------------------------------------------------
# Ghostty
# ---------------------------------------------------------------------------

def generate_ghostty(palette: dict, name: str, variant: str):
    """Write a Ghostty theme file to ~/.config/ghostty/themes/<name>.

    Maps Prot's palette to Ghostty's color configuration:
    - background/foreground from bg-main/fg-main
    - cursor-color from cursor (per-theme), cursor-text from bg-main
    - selection from bg-region
    - ANSI 16 from modus term mappings (preferred), named colors, or
      doric fg-COLOR names (via normalization)
    """
    out = Path.home() / ".config/ghostty/themes" / name
    out.parent.mkdir(parents=True, exist_ok=True)

    bg = palette["bg-main"]
    fg = palette["fg-main"]
    cursor = get(palette, "cursor", fg)
    cursor_text = bg  # text under block cursor shows background

    # ANSI normal (0-7): prefer explicit term mappings from modus, then named colors
    red     = get(palette, "fg-term-red",     get(palette, "red",     fg))
    green   = get(palette, "fg-term-green",   get(palette, "green",   fg))
    yellow  = get(palette, "fg-term-yellow",  get(palette, "yellow",  fg))
    blue    = get(palette, "fg-term-blue",    get(palette, "blue",    fg))
    magenta = get(palette, "fg-term-magenta", get(palette, "magenta", fg))
    cyan    = get(palette, "fg-term-cyan",    get(palette, "cyan",    fg))

    # ANSI bright (8-15): prefer explicit term bright mappings, then warmer variants
    red_br     = get(palette, "fg-term-red-bright",     get(palette, "red-warmer",     red))
    green_br   = get(palette, "fg-term-green-bright",   get(palette, "green-warmer",   green))
    yellow_br  = get(palette, "fg-term-yellow-bright",  get(palette, "yellow-warmer",  yellow))
    blue_br    = get(palette, "fg-term-blue-bright",    get(palette, "blue-warmer",    blue))
    magenta_br = get(palette, "fg-term-magenta-bright", get(palette, "magenta-warmer", magenta))
    cyan_br    = get(palette, "fg-term-cyan-bright",    get(palette, "cyan-warmer",    cyan))

    # Black/white ANSI slots
    black    = get(palette, "bg-term-black",        get(palette, "bg-dim", bg))
    white    = get(palette, "fg-term-white",        fg)
    black_br = get(palette, "bg-term-black-bright", get(palette, "bg-active", black))
    white_br = get(palette, "fg-term-white-bright", get(palette, "fg-alt", fg))

    sel_bg = get(palette, "bg-region", get(palette, "bg-active", black))
    sel_fg = fg

    lines = [
        f"# Auto-generated from palette: {name}",
        f"background = {bg}",
        f"foreground = {fg}",
        f"cursor-color = {cursor}",
        f"cursor-text = {cursor_text}",
        f"selection-background = {sel_bg}",
        f"selection-foreground = {sel_fg}",
    ]

    ansi = [black, red, green, yellow, blue, magenta, cyan, white,
            black_br, red_br, green_br, yellow_br, blue_br, magenta_br, cyan_br, white_br]
    for i, color in enumerate(ansi):
        lines.append(f"palette = {i}={color}")

    out.write_text("\n".join(lines) + "\n")
    print(f"Generated ghostty theme: {out}")


# ---------------------------------------------------------------------------
# Sketchybar (colors.sh + colors.lua)
# ---------------------------------------------------------------------------

def generate_sketchybar(palette: dict, name: str, variant: str):
    """Write sketchybar color files (shell + lua)."""
    out_sh = Path.home() / ".config/sketchybar/colors.sh"
    out_lua = Path.home() / ".config/sketchybar/colors.lua"

    bg = hex_strip(palette["bg-main"])
    fg = hex_strip(palette["fg-main"])

    p = [None] * 16
    p[0]  = hex_strip(get(palette, "bg-dim", palette["bg-main"]))
    p[1]  = hex_strip(get(palette, "red", palette["fg-main"]))
    p[2]  = hex_strip(get(palette, "green", palette["fg-main"]))
    p[3]  = hex_strip(get(palette, "yellow", palette["fg-main"]))
    p[4]  = hex_strip(get(palette, "blue", palette["fg-main"]))
    p[5]  = hex_strip(get(palette, "magenta", palette["fg-main"]))
    p[6]  = hex_strip(get(palette, "cyan", palette["fg-main"]))
    p[7]  = hex_strip(get(palette, "fg-dim", palette["fg-main"]))
    p[8]  = hex_strip(get(palette, "bg-active", p[0]))
    p[9]  = hex_strip(get(palette, "red-warmer", p[1]))
    p[10] = hex_strip(get(palette, "green-warmer", p[2]))
    p[11] = hex_strip(get(palette, "yellow-warmer", p[3]))
    p[12] = hex_strip(get(palette, "blue-warmer", p[4]))
    p[13] = hex_strip(get(palette, "magenta-warmer", p[5]))
    p[14] = hex_strip(get(palette, "cyan-warmer", p[6]))
    p[15] = fg

    def sh_export(name, prefix, color):
        return f"export {name}={prefix}{color}"

    sh_lines = [
        "#!/usr/bin/env bash",
        "# Auto-generated from theme palette",
        "",
        sh_export("BAR_COLOR", "0x00", "000000"),
        sh_export("TRANSPARENT", "0x00", "000000"),
        "",
        sh_export("DEFAULT_ICON_COLOR", "0xff", fg),
        sh_export("DEFAULT_LABEL_COLOR", "0xff", fg),
        "",
    ]
    color_names = ["BLACK", "RED", "GREEN", "YELLOW", "BLUE", "MAGENTA", "CYAN", "WHITE",
                   "BRIGHT_BLACK", "BRIGHT_RED", "BRIGHT_GREEN", "BRIGHT_YELLOW",
                   "BRIGHT_BLUE", "BRIGHT_MAGENTA", "BRIGHT_CYAN", "BRIGHT_WHITE"]
    for i, cn in enumerate(color_names):
        sh_lines.append(sh_export(cn, "0xff", p[i]))
        if i == 7:
            sh_lines.append("")

    sh_lines += [
        "",
        sh_export("GREY", "0xff", p[15]),
        sh_export("GREY_TRANSP", "0x11", p[15]),
        sh_export("ACCENT", "0xff", p[5]),
        sh_export("ACCENT_TRANSPARENT", "0x44", p[5]),
        sh_export("BRACKET_BG", "0xff", bg),
        sh_export("BRACKET_BORDER", "0x22", fg),
        "",
        sh_export("TEXT_PRIMARY", "0xff", fg),
        sh_export("TEXT_MUTED", "0xff", p[15]),
        "",
        sh_export("SPACE_ACTIVE_COLOR", "0xff", fg),
        sh_export("SPACE_ACTIVE_BG_COLOR", "0x30", fg),
        sh_export("SPACE_HIGHLIGHT_COLOR", "0xff", fg),
        sh_export("SPACE_INACTIVE_COLOR", "0xff", p[15]),
        "",
        sh_export("SPACE_GROUP1_COLOR", "0xff", p[4]),
        sh_export("SPACE_GROUP1_BG", "0x30", p[4]),
        sh_export("SPACE_GROUP2_COLOR", "0xff", p[2]),
        sh_export("SPACE_GROUP2_BG", "0x30", p[2]),
        sh_export("SPACE_GROUP3_COLOR", "0xff", p[5]),
        sh_export("SPACE_GROUP3_BG", "0x30", p[5]),
        sh_export("SPACE_GROUP4_COLOR", "0xff", p[6]),
        sh_export("SPACE_GROUP4_BG", "0x30", p[6]),
        "",
        sh_export("FRONT_APP_LAYOUT_ICON_COLOR", "0xff", p[2]),
        sh_export("FRONT_APP_LAYOUT_BG_COLOR", "0x11", p[2]),
        "",
        sh_export("CLOCK_COLOR", "0xff", p[4]),
        sh_export("VOLUME_COLOR", "0xff", p[5]),
        "",
        sh_export("BATTERY_COLOR_NORMAL", "0xff", p[1]),
        sh_export("BATTERY_COLOR_WARNING", "0xff", p[3]),
        sh_export("BATTERY_COLOR_LOW", "0xff", p[11]),
        sh_export("BATTERY_COLOR_CRITICAL", "0xff", p[1]),
        sh_export("BATTERY_COLOR_CHARGING", "0xff", p[2]),
    ]

    out_sh.write_text("\n".join(sh_lines) + "\n")

    # Lua version for SbarLua
    def lua_line(k, v):
        return f"  {k} = {v},"

    lua_lines = [
        "-- Auto-generated from theme palette",
        "return {",
        lua_line("bar_color", "0x00000000"),
        lua_line("transparent", "0x00000000"),
        lua_line("icon_color", f"0xff{fg}"),
        lua_line("label_color", f"0xff{fg}"),
        "",
        lua_line("black", f"0xff{p[0]}"),
        lua_line("red", f"0xff{p[1]}"),
        lua_line("green", f"0xff{p[2]}"),
        lua_line("yellow", f"0xff{p[3]}"),
        lua_line("blue", f"0xff{p[4]}"),
        lua_line("magenta", f"0xff{p[5]}"),
        lua_line("cyan", f"0xff{p[6]}"),
        lua_line("white", f"0xff{p[7]}"),
        "",
        lua_line("grey", f"0xff{p[15]}"),
        lua_line("grey_transp", f"0x11{p[15]}"),
        lua_line("accent", f"0xff{p[5]}"),
        lua_line("accent_transp", f"0x44{p[5]}"),
        lua_line("bracket_bg", f"0xff{bg}"),
        lua_line("bracket_border", f"0x22{fg}"),
        "",
        lua_line("text_primary", f"0xff{fg}"),
        lua_line("text_muted", f"0xff{p[15]}"),
        "",
        lua_line("space_active", f"0xff{fg}"),
        lua_line("space_active_bg", f"0x30{fg}"),
        lua_line("space_inactive", f"0xff{p[15]}"),
        "",
        lua_line("space_group1", f"0xff{p[4]}"),
        lua_line("space_group1_bg", f"0x30{p[4]}"),
        lua_line("space_group2", f"0xff{p[2]}"),
        lua_line("space_group2_bg", f"0x30{p[2]}"),
        lua_line("space_group3", f"0xff{p[5]}"),
        lua_line("space_group3_bg", f"0x30{p[5]}"),
        lua_line("space_group4", f"0xff{p[6]}"),
        lua_line("space_group4_bg", f"0x30{p[6]}"),
        "",
        lua_line("front_app_layout", f"0xff{p[2]}"),
        lua_line("front_app_layout_bg", f"0x11{p[2]}"),
        "",
        lua_line("clock", f"0xff{p[4]}"),
        lua_line("volume", f"0xff{p[5]}"),
        "",
        lua_line("battery_normal", f"0xff{p[1]}"),
        lua_line("battery_warning", f"0xff{p[3]}"),
        lua_line("battery_low", f"0xff{p[11]}"),
        lua_line("battery_critical", f"0xff{p[1]}"),
        lua_line("battery_charging", f"0xff{p[2]}"),
        "}",
    ]

    out_lua.write_text("\n".join(lua_lines) + "\n")
    print(f"Generated {out_sh} + {out_lua}")

    # Restart sketchybar to pick up new colors.
    # SbarLua holds a long-running Lua process — `sketchybar --reload`
    # doesn't clear old items, so brew services restart is the only clean path.
    import shutil
    if shutil.which("brew"):
        try:
            subprocess.run(["brew", "services", "restart", "sketchybar"],
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False)
        except Exception:
            pass


# ---------------------------------------------------------------------------
# JankyBorders
# ---------------------------------------------------------------------------

def generate_borders(palette: dict, name: str, variant: str):
    """Write ~/.config/borders/bordersrc."""
    out = Path.home() / ".config/borders/bordersrc"
    out.parent.mkdir(parents=True, exist_ok=True)

    active = hex_strip(get(palette, "fg-alt", palette["fg-main"]))
    inactive = hex_strip(get(palette, "bg-active", get(palette, "bg-dim", palette["bg-main"])))

    lines = [
        "#!/bin/bash",
        "# Auto-generated from theme palette",
        f"borders active_color=0xff{active} inactive_color=0x44{inactive} width=5.0 style=round hidpi=on",
    ]
    out.write_text("\n".join(lines) + "\n")
    out.chmod(0o755)

    # Live-update running borders
    try:
        subprocess.Popen(
            ["borders", f"active_color=0xff{active}", f"inactive_color=0x44{inactive}",
             "width=5.0", "style=round", "hidpi=on"],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        )
    except FileNotFoundError:
        pass

    print(f"Generated {out}")


# ---------------------------------------------------------------------------
# Wallpaper
# ---------------------------------------------------------------------------

def generate_wallpaper(palette: dict, name: str, variant: str):
    """Generate solid-color wallpaper from bg-main and set it."""
    import shutil

    bg = palette["bg-main"]
    wp_dir = Path.home() / ".local/share/wallpapers"
    wp_dir.mkdir(parents=True, exist_ok=True)

    if not shutil.which("magick") or not shutil.which("m"):
        print("Warning: magick or m-cli not installed, skipping wallpaper")
        return

    # Get display resolutions
    try:
        status_out = subprocess.check_output(["m", "display", "--status"], text=True, stderr=subprocess.DEVNULL)
    except (subprocess.CalledProcessError, FileNotFoundError):
        print("Warning: could not detect displays, skipping wallpaper")
        return

    import re
    displays = re.findall(r"(\d+) x (\d+)", status_out)
    if not displays:
        print("Warning: no displays found, skipping wallpaper")
        return

    for idx, (w, h) in enumerate(displays):
        wp = wp_dir / f"wallpaper-{idx}.jpg"
        subprocess.run(
            ["magick", "-size", f"{w}x{h}", f"xc:{bg}", "-quality", "95", str(wp)],
            check=True,
        )
        print(f"Generated wallpaper: {w}x{h} {bg} -> {wp}")

    wp0 = wp_dir / "wallpaper-0.jpg"
    if wp0.exists():
        subprocess.run(["m", "wallpaper", "--set", str(wp0)], check=True)
        print(f"Wallpaper set to {bg}")


# ---------------------------------------------------------------------------
# Glamour (markdown renderer)
# ---------------------------------------------------------------------------

def generate_glamour(palette: dict, name: str, variant: str):
    """Write ~/.config/glamour/style.json."""
    out = Path.home() / ".config/glamour/style.json"
    out.parent.mkdir(parents=True, exist_ok=True)

    fg   = palette["fg-main"]
    dim  = get(palette, "fg-dim", fg)
    red     = get(palette, "red", fg)
    green   = get(palette, "green", fg)
    yellow  = get(palette, "yellow", fg)
    blue    = get(palette, "blue", fg)
    magenta = get(palette, "magenta", fg)
    cyan    = get(palette, "cyan", fg)

    blue_w    = get(palette, "blue-warmer", blue)
    cyan_w    = get(palette, "cyan-warmer", cyan)
    green_c   = get(palette, "green-cooler", green)
    magenta_c = get(palette, "magenta-cooler", magenta)
    yellow_w  = get(palette, "yellow-warmer", yellow)

    style = {
        "document": {"block_prefix": "\n", "block_suffix": "\n", "color": fg, "margin": 2},
        "block_quote": {"indent": 1, "indent_token": "\u2502 ", "color": dim},
        "paragraph": {},
        "list": {"color": fg, "level_indent": 2},
        "heading": {"block_suffix": "\n", "bold": True, "color": blue},
        "h1": {"prefix": "# ", "bold": True},
        "h2": {"prefix": "## "},
        "h3": {"prefix": "### ", "color": cyan},
        "h4": {"prefix": "#### "},
        "h5": {"prefix": "##### "},
        "h6": {"prefix": "###### ", "bold": False},
        "text": {},
        "strikethrough": {"crossed_out": True},
        "emph": {"italic": True},
        "strong": {"bold": True},
        "hr": {"color": dim, "format": "\n--------\n"},
        "item": {"block_prefix": "\u2022 "},
        "enumeration": {"block_prefix": ". ", "color": blue},
        "task": {"ticked": "[\u2713] ", "unticked": "[ ] "},
        "link": {"color": cyan, "underline": True},
        "link_text": {"color": cyan_w, "bold": True},
        "image": {"color": magenta, "underline": True},
        "image_text": {"color": dim, "format": "Image: {{.text}} \u2192"},
        "code": {"prefix": " ", "suffix": " ", "color": green_c},
        "code_block": {
            "color": fg, "margin": 2,
            "chroma": {
                "text": {"color": fg},
                "error": {"color": red},
                "comment": {"color": dim, "italic": True},
                "comment_preproc": {"color": cyan},
                "keyword": {"color": magenta, "bold": True},
                "keyword_reserved": {"color": magenta_c, "bold": True},
                "keyword_namespace": {"color": red},
                "keyword_type": {"color": cyan_w},
                "operator": {"color": red},
                "punctuation": {"color": dim},
                "name": {},
                "name_builtin": {"color": blue_w},
                "name_tag": {"color": magenta},
                "name_attribute": {"color": cyan},
                "name_class": {"color": blue, "underline": True, "bold": True},
                "name_constant": {"color": magenta_c},
                "name_decorator": {"color": yellow},
                "name_exception": {},
                "name_function": {"color": green},
                "name_other": {},
                "literal": {},
                "literal_number": {"color": cyan},
                "literal_date": {},
                "literal_string": {"color": yellow_w},
                "literal_string_escape": {"color": cyan},
                "generic_deleted": {"color": red},
                "generic_emph": {"italic": True},
                "generic_inserted": {"color": green},
                "generic_strong": {"bold": True},
                "generic_subheading": {"color": dim},
            },
        },
        "table": {},
        "definition_list": {},
        "definition_term": {},
        "definition_description": {"block_prefix": "\n\u2192 "},
        "html_block": {},
        "html_span": {},
    }

    out.write_text(json.dumps(style, indent=2) + "\n")
    print(f"Generated {out}")


# ---------------------------------------------------------------------------
# Helix
# ---------------------------------------------------------------------------

def generate_helix(palette: dict, name: str, variant: str):
    """Write ~/.config/helix/themes/prot-current.toml.

    Full coverage of Helix's syntax scopes and UI keys, mapped to
    Prot's Emacs face conventions.
    """
    out = Path.home() / ".config/helix/themes/prot-current.toml"
    out.parent.mkdir(parents=True, exist_ok=True)

    bg = palette["bg-main"]
    fg = palette["fg-main"]
    cursor = get(palette, "cursor", fg)

    # Core colors
    red     = get(palette, "red", fg)
    green   = get(palette, "green", fg)
    yellow  = get(palette, "yellow", fg)
    blue    = get(palette, "blue", fg)
    magenta = get(palette, "magenta", fg)
    cyan    = get(palette, "cyan", fg)

    # Warmer
    red_w     = get(palette, "red-warmer", red)
    green_w   = get(palette, "green-warmer", green)
    yellow_w  = get(palette, "yellow-warmer", yellow)
    blue_w    = get(palette, "blue-warmer", blue)
    magenta_w = get(palette, "magenta-warmer", magenta)
    cyan_w    = get(palette, "cyan-warmer", cyan)

    # Cooler
    red_c     = get(palette, "red-cooler", red)
    green_c   = get(palette, "green-cooler", green)
    magenta_c = get(palette, "magenta-cooler", magenta)
    cyan_c    = get(palette, "cyan-cooler", cyan)

    # Faint
    red_f     = get(palette, "red-faint", red)
    green_f   = get(palette, "green-faint", green)
    yellow_f  = get(palette, "yellow-faint", yellow)
    blue_f    = get(palette, "blue-faint", blue)
    magenta_f = get(palette, "magenta-faint", magenta)
    cyan_f    = get(palette, "cyan-faint", cyan)

    # Surfaces
    bg_dim    = get(palette, "bg-dim", bg)
    bg_active = get(palette, "bg-active", bg_dim)
    bg_popup  = get(palette, "bg-popup", bg_dim)
    bg_hl     = get(palette, "bg-hl-line", bg_dim)
    bg_region = get(palette, "bg-region", bg_active)
    bg_mode   = get(palette, "bg-mode-line-active", bg_active)
    border    = get(palette, "border", bg_active)

    # Foreground shades
    fg_dim = get(palette, "fg-dim", fg)
    fg_alt = get(palette, "fg-alt", fg)

    # Diff
    bg_added   = get(palette, "bg-added", bg)
    bg_removed = get(palette, "bg-removed", bg)
    bg_changed = get(palette, "bg-changed", bg)
    fg_added   = get(palette, "fg-added", green)
    fg_removed = get(palette, "fg-removed", red)
    fg_changed = get(palette, "fg-changed", yellow)

    # Added fringe (gutter indicators)
    bg_added_fringe   = get(palette, "bg-added-fringe", green)
    bg_removed_fringe = get(palette, "bg-removed-fringe", red)
    bg_changed_fringe = get(palette, "bg-changed-fringe", yellow)

    lines = [
        f"# Auto-generated from palette: {name}",
        "",
        "# --- Syntax ---",
        '"comment" = { fg = "fg_dim", modifiers = ["italic"] }',
        '"comment.line" = { fg = "fg_dim", modifiers = ["italic"] }',
        '"comment.line.documentation" = { fg = "green_f", modifiers = ["italic"] }',
        '"comment.block" = { fg = "fg_dim", modifiers = ["italic"] }',
        '"comment.block.documentation" = { fg = "green_f", modifiers = ["italic"] }',
        '"comment.unused" = { fg = "yellow_f", modifiers = ["italic"] }',
        "",
        '"constant" = "blue"',
        '"constant.builtin" = "blue"',
        '"constant.builtin.boolean" = "blue"',
        '"constant.character" = "blue_w"',
        '"constant.character.escape" = "blue_w"',
        '"constant.numeric" = "fg"',
        '"constant.numeric.integer" = "fg"',
        '"constant.numeric.float" = "fg"',
        "",
        '"string" = "blue_w"',
        '"string.regexp" = "magenta_c"',
        '"string.special" = "blue_w"',
        '"string.special.path" = "cyan_f"',
        '"string.special.url" = { fg = "blue_w", modifiers = ["underlined"] }',
        '"string.special.symbol" = "blue_w"',
        "",
        '"type" = "cyan"',
        '"type.builtin" = "cyan_w"',
        '"type.parameter" = "cyan_f"',
        '"type.enum" = "cyan"',
        '"type.enum.variant" = "cyan"',
        '"constructor" = "magenta"',
        "",
        '"function" = "magenta"',
        '"function.builtin" = "magenta_w"',
        '"function.method" = "magenta"',
        '"function.macro" = "magenta_c"',
        '"function.special" = "magenta_w"',
        "",
        '"keyword" = "magenta_c"',
        '"keyword.control" = "magenta_c"',
        '"keyword.control.conditional" = "magenta_c"',
        '"keyword.control.repeat" = "magenta_c"',
        '"keyword.control.import" = "magenta_c"',
        '"keyword.control.return" = "magenta_c"',
        '"keyword.control.exception" = "red_c"',
        '"keyword.operator" = "magenta"',
        '"keyword.directive" = "red_c"',
        '"keyword.function" = "magenta_c"',
        '"keyword.storage" = "magenta_c"',
        '"keyword.storage.type" = "cyan"',
        '"keyword.storage.modifier" = "magenta_c"',
        "",
        '"operator" = "magenta"',
        '"label" = "cyan"',
        '"namespace" = "cyan_w"',
        "",
        '"tag" = "blue"',
        '"tag.builtin" = "blue_w"',
        '"attribute" = "red"',
        "",
        '"variable" = "cyan_w"',
        '"variable.builtin" = "magenta_c"',
        '"variable.parameter" = "cyan_w"',
        '"variable.other.member" = "blue"',
        '"variable.other.member.private" = "blue_f"',
        "",
        '"punctuation" = "fg"',
        '"punctuation.delimiter" = "fg"',
        '"punctuation.bracket" = "fg_dim"',
        '"punctuation.special" = "red"',
        "",
        '"special" = "red"',
        "",
        "# --- Markup ---",
        '"markup.heading" = { fg = "fg", modifiers = ["bold"] }',
        '"markup.heading.marker" = "fg_dim"',
        '"markup.heading.1" = { fg = "blue", modifiers = ["bold"] }',
        '"markup.heading.2" = { fg = "cyan", modifiers = ["bold"] }',
        '"markup.heading.3" = { fg = "magenta_c", modifiers = ["bold"] }',
        '"markup.heading.4" = { fg = "yellow", modifiers = ["bold"] }',
        '"markup.heading.5" = { fg = "green", modifiers = ["bold"] }',
        '"markup.heading.6" = { fg = "red_f", modifiers = ["bold"] }',
        '"markup.list" = "fg"',
        '"markup.list.checked" = { fg = "green", modifiers = ["crossed_out"] }',
        '"markup.list.unchecked" = "red"',
        '"markup.bold" = { modifiers = ["bold"] }',
        '"markup.italic" = { modifiers = ["italic"] }',
        '"markup.strikethrough" = { modifiers = ["crossed_out"] }',
        '"markup.link.text" = { fg = "cyan_w", modifiers = ["italic"] }',
        '"markup.link.url" = { fg = "blue_w", modifiers = ["underlined"] }',
        '"markup.link.label" = "cyan"',
        '"markup.quote" = { fg = "fg_dim", modifiers = ["italic"] }',
        '"markup.raw" = "magenta"',
        '"markup.raw.inline" = "magenta"',
        '"markup.raw.block" = "fg"',
        "",
        "# --- Diagnostics ---",
        '"diagnostic" = { underline = { color = "yellow", style = "curl" } }',
        '"diagnostic.error" = { underline = { color = "red", style = "curl" } }',
        '"diagnostic.warning" = { underline = { color = "yellow_w", style = "curl" } }',
        '"diagnostic.info" = { underline = { color = "blue", style = "curl" } }',
        '"diagnostic.hint" = { underline = { color = "cyan", style = "curl" } }',
        '"diagnostic.unnecessary" = { modifiers = ["dim"] }',
        '"diagnostic.deprecated" = { modifiers = ["crossed_out"] }',
        '"error" = "red"',
        '"warning" = "yellow_w"',
        '"info" = "blue"',
        '"hint" = "cyan"',
        "",
        "# --- Diff ---",
        '"diff.plus" = "fg_added"',
        '"diff.plus.gutter" = "bg_added_fringe"',
        '"diff.minus" = "fg_removed"',
        '"diff.minus.gutter" = "bg_removed_fringe"',
        '"diff.delta" = "fg_changed"',
        '"diff.delta.gutter" = "bg_changed_fringe"',
        "",
        "# --- UI ---",
        '"ui.background" = { bg = "bg" }',
        '"ui.background.separator" = { fg = "border" }',
        "",
        '"ui.text" = "fg"',
        '"ui.text.focus" = { fg = "green", bg = "bg_dim" }',
        '"ui.text.inactive" = "fg_dim"',
        '"ui.text.info" = "blue"',
        '"ui.text.directory" = "blue"',
        "",
        '"ui.cursor" = { fg = "bg", bg = "fg_dim" }',
        '"ui.cursor.normal" = { fg = "bg", bg = "fg_dim" }',
        '"ui.cursor.insert" = { fg = "bg", bg = "green" }',
        '"ui.cursor.select" = { fg = "bg", bg = "yellow" }',
        '"ui.cursor.match" = { fg = "fg", bg = "bg_active" }',
        '"ui.cursor.primary" = { fg = "bg", bg = "cursor" }',
        '"ui.cursor.primary.normal" = { fg = "bg", bg = "cursor" }',
        '"ui.cursor.primary.insert" = { fg = "bg", bg = "green_w" }',
        '"ui.cursor.primary.select" = { fg = "bg", bg = "yellow_w" }',
        "",
        '"ui.cursorline.primary" = { bg = "bg_hl" }',
        '"ui.cursorline.secondary" = { bg = "bg_dim" }',
        '"ui.cursorcolumn.primary" = { bg = "bg_hl" }',
        '"ui.cursorcolumn.secondary" = { bg = "bg_dim" }',
        "",
        '"ui.gutter" = { bg = "bg" }',
        '"ui.gutter.selected" = { bg = "bg_hl" }',
        '"ui.linenr" = "fg_dim"',
        '"ui.linenr.selected" = { fg = "fg", modifiers = ["bold"] }',
        "",
        '"ui.selection" = { bg = "bg_region" }',
        '"ui.selection.primary" = { bg = "bg_active" }',
        '"ui.highlight" = { bg = "bg_hl" }',
        "",
        '"ui.statusline" = { fg = "fg", bg = "bg_mode" }',
        '"ui.statusline.inactive" = { fg = "fg_dim", bg = "bg_dim" }',
        '"ui.statusline.normal" = { fg = "bg", bg = "blue", modifiers = ["bold"] }',
        '"ui.statusline.insert" = { fg = "bg", bg = "green", modifiers = ["bold"] }',
        '"ui.statusline.select" = { fg = "bg", bg = "yellow", modifiers = ["bold"] }',
        '"ui.statusline.separator" = { fg = "border" }',
        "",
        '"ui.popup" = { bg = "bg_popup" }',
        '"ui.popup.info" = { fg = "fg", bg = "bg_popup" }',
        '"ui.window" = { fg = "border" }',
        '"ui.help" = { fg = "fg", bg = "bg_popup" }',
        '"ui.menu" = { fg = "fg", bg = "bg_popup" }',
        '"ui.menu.selected" = { fg = "green", bg = "bg_dim", modifiers = ["bold"] }',
        '"ui.menu.scroll" = { fg = "fg_dim", bg = "bg_popup" }',
        "",
        '"ui.bufferline" = { fg = "fg_dim", bg = "bg_dim" }',
        '"ui.bufferline.active" = { fg = "bg", bg = "blue" }',
        '"ui.bufferline.background" = { bg = "bg_dim" }',
        "",
        '"ui.virtual.ruler" = { bg = "bg_dim" }',
        '"ui.virtual.whitespace" = "bg_active"',
        '"ui.virtual.indent-guide" = "bg_active"',
        '"ui.virtual.wrap" = "bg_active"',
        '"ui.virtual.inlay-hint" = "fg_dim"',
        '"ui.virtual.inlay-hint.parameter" = "fg_dim"',
        '"ui.virtual.inlay-hint.type" = "cyan_f"',
        '"ui.virtual.jump-label" = { fg = "magenta_w", modifiers = ["bold"] }',
        "",
        '"ui.debug.breakpoint" = "red"',
        '"ui.debug.active" = "yellow"',
        "",
        "# --- Palette ---",
        "[palette]",
        f'bg = "{bg}"',
        f'fg = "{fg}"',
        f'cursor = "{cursor}"',
        f'border = "{border}"',
        f'fg_dim = "{fg_dim}"',
        f'fg_alt = "{fg_alt}"',
        f'bg_dim = "{bg_dim}"',
        f'bg_active = "{bg_active}"',
        f'bg_popup = "{bg_popup}"',
        f'bg_hl = "{bg_hl}"',
        f'bg_region = "{bg_region}"',
        f'bg_mode = "{bg_mode}"',
        f'red = "{red}"',
        f'green = "{green}"',
        f'yellow = "{yellow}"',
        f'blue = "{blue}"',
        f'magenta = "{magenta}"',
        f'cyan = "{cyan}"',
        f'red_w = "{red_w}"',
        f'green_w = "{green_w}"',
        f'yellow_w = "{yellow_w}"',
        f'blue_w = "{blue_w}"',
        f'magenta_w = "{magenta_w}"',
        f'cyan_w = "{cyan_w}"',
        f'red_c = "{red_c}"',
        f'green_c = "{green_c}"',
        f'magenta_c = "{magenta_c}"',
        f'cyan_c = "{cyan_c}"',
        f'red_f = "{red_f}"',
        f'green_f = "{green_f}"',
        f'yellow_f = "{yellow_f}"',
        f'blue_f = "{blue_f}"',
        f'magenta_f = "{magenta_f}"',
        f'cyan_f = "{cyan_f}"',
        f'fg_added = "{fg_added}"',
        f'fg_removed = "{fg_removed}"',
        f'fg_changed = "{fg_changed}"',
        f'bg_added = "{bg_added}"',
        f'bg_removed = "{bg_removed}"',
        f'bg_changed = "{bg_changed}"',
        f'bg_added_fringe = "{bg_added_fringe}"',
        f'bg_removed_fringe = "{bg_removed_fringe}"',
        f'bg_changed_fringe = "{bg_changed_fringe}"',
    ]

    out.write_text("\n".join(lines) + "\n")
    print(f"Generated helix theme: {out}")


# ---------------------------------------------------------------------------
# Xonsh (prompt + syntax highlighting)
# ---------------------------------------------------------------------------

def generate_xonsh(palette: dict, name: str, variant: str):
    """Write ~/.config/xonsh/theme.xsh — sourced by rc.xsh.

    Sets:
    - $PROMPT / $RIGHT_PROMPT with hex colors from the palette
    - A custom xonsh color style for syntax highlighting (input line)
    """
    out = Path.home() / ".config/xonsh/theme.xsh"
    out.parent.mkdir(parents=True, exist_ok=True)

    bg = palette["bg-main"]
    fg = palette["fg-main"]
    cursor = get(palette, "cursor", fg)
    fg_dim = get(palette, "fg-dim", fg)
    fg_alt = get(palette, "fg-alt", fg)

    blue    = get(palette, "blue", fg)
    cyan    = get(palette, "cyan", fg)
    green   = get(palette, "green", fg)
    magenta = get(palette, "magenta", fg)
    red     = get(palette, "red", fg)
    yellow  = get(palette, "yellow", fg)

    magenta_c = get(palette, "magenta-cooler", magenta)
    magenta_w = get(palette, "magenta-warmer", magenta)
    blue_w    = get(palette, "blue-warmer", blue)
    cyan_w    = get(palette, "cyan-warmer", cyan)
    green_c   = get(palette, "green-cooler", green)
    red_c     = get(palette, "red-cooler", red)
    yellow_w  = get(palette, "yellow-warmer", yellow)

    red_w     = get(palette, "red-warmer", red)
    green_w   = get(palette, "green-warmer", green)
    yellow_w  = get(palette, "yellow-warmer", yellow)
    blue_w2   = get(palette, "blue-warmer", blue)
    magenta_w2 = get(palette, "magenta-warmer", magenta)
    cyan_w2   = get(palette, "cyan-warmer", cyan)

    lines = [
        f"# Auto-generated from palette: {name} ({variant})",
        f"# Source this from rc.xsh — do not edit manually",
        "",
        "# --- Prompt ---",
        f"$PROMPT = '{{#{hex_strip(fg_dim)}}}{{cwd_base}}{{RESET}}"
        f"{{#{hex_strip(fg_alt)}}}{{curr_branch: [{{}}]}}{{RESET}} "
        f"{{#{hex_strip(magenta_c)}}}\u03bb{{RESET}} '",
        "",
        f"$RIGHT_PROMPT = '{{#{hex_strip(fg_dim)}}}{{localtime}}{{RESET}}'",
        "",
        "# --- Syntax highlighting ---",
        "from xonsh.tools import register_custom_style",
        "",
        "register_custom_style('prot-theme', {",
        f"    'Token':                       '{fg}',",
        f"    'Token.Text':                  '{fg}',",
        f"    'Token.Error':                 '{red}',",
        f"    'Token.Comment':               '{fg_dim}',",
        f"    'Token.Comment.Single':        '{fg_dim}',",
        f"    'Token.Keyword':               '{magenta_c}',",
        f"    'Token.Keyword.Constant':      '{blue}',",
        f"    'Token.Keyword.Declaration':   '{magenta_c}',",
        f"    'Token.Keyword.Namespace':     '{magenta_c}',",
        f"    'Token.Keyword.Type':          '{cyan}',",
        f"    'Token.Name':                  '{fg}',",
        f"    'Token.Name.Builtin':          '{magenta_w}',",
        f"    'Token.Name.Class':            '{blue}',",
        f"    'Token.Name.Decorator':        '{yellow}',",
        f"    'Token.Name.Function':         '{magenta}',",
        f"    'Token.Name.Variable':         '{cyan_w}',",
        f"    'Token.Literal.String':        '{blue_w}',",
        f"    'Token.Literal.String.Single': '{blue_w}',",
        f"    'Token.Literal.String.Double': '{blue_w}',",
        f"    'Token.Literal.String.Escape': '{blue_w}',",
        f"    'Token.Literal.String.Doc':    '{green_c}',",
        f"    'Token.Literal.Number':        '{fg}',",
        f"    'Token.Operator':              '{magenta}',",
        f"    'Token.Punctuation':           '{fg}',",
        f"    'Token.Generic.Deleted':       '{red}',",
        f"    'Token.Generic.Inserted':      '{green}',",
        f"    'Token.Generic.Heading':       '{fg_dim}',",
        f"    'Token.Generic.Error':         '{red}',",
        f"    'RED':            '{red}',",
        f"    'GREEN':          '{green}',",
        f"    'YELLOW':         '{yellow}',",
        f"    'BLUE':           '{blue}',",
        f"    'PURPLE':         '{magenta}',",
        f"    'CYAN':           '{cyan}',",
        f"    'WHITE':          '{fg}',",
        f"    'INTENSE_RED':    '{red_w}',",
        f"    'INTENSE_GREEN':  '{green_w}',",
        f"    'INTENSE_YELLOW': '{yellow_w}',",
        f"    'INTENSE_BLUE':   '{blue_w2}',",
        f"    'INTENSE_PURPLE': '{magenta_w2}',",
        f"    'INTENSE_CYAN':   '{cyan_w2}',",
        f"    'INTENSE_WHITE':  '{fg_alt}',",
        "})",
        "",
        "$XONSH_COLOR_STYLE = 'prot-theme'",
    ]

    out.write_text("\n".join(lines) + "\n")
    print(f"Generated xonsh theme: {out}")


# ---------------------------------------------------------------------------
# Zed
# ---------------------------------------------------------------------------

def generate_zed(palette: dict, name: str, variant: str):
    """Write ~/.config/zed/themes/prot-current.json."""
    out = Path.home() / ".config/zed/themes/prot-current.json"
    out.parent.mkdir(parents=True, exist_ok=True)

    bg = palette["bg-main"]
    fg = palette["fg-main"]
    cursor = get(palette, "cursor", fg)

    # Core colors
    red     = get(palette, "red", fg)
    green   = get(palette, "green", fg)
    yellow  = get(palette, "yellow", fg)
    blue    = get(palette, "blue", fg)
    magenta = get(palette, "magenta", fg)
    cyan    = get(palette, "cyan", fg)

    # Variants
    red_w     = get(palette, "red-warmer", red)
    green_w   = get(palette, "green-warmer", green)
    yellow_w  = get(palette, "yellow-warmer", yellow)
    blue_w    = get(palette, "blue-warmer", blue)
    magenta_w = get(palette, "magenta-warmer", magenta)
    cyan_w    = get(palette, "cyan-warmer", cyan)
    red_c     = get(palette, "red-cooler", red)
    magenta_c = get(palette, "magenta-cooler", magenta)
    cyan_c    = get(palette, "cyan-cooler", cyan)
    red_f     = get(palette, "red-faint", red)
    green_f   = get(palette, "green-faint", green)
    blue_f    = get(palette, "blue-faint", blue)
    cyan_f    = get(palette, "cyan-faint", cyan)
    magenta_f = get(palette, "magenta-faint", magenta)

    # Surfaces
    bg_dim    = get(palette, "bg-dim", bg)
    bg_active = get(palette, "bg-active", bg_dim)
    bg_alt    = get(palette, "bg-alt", bg_dim)
    bg_popup  = get(palette, "bg-popup", bg_dim)
    bg_hl     = get(palette, "bg-hl-line", bg_dim)
    bg_region = get(palette, "bg-region", bg_active)
    bg_hover  = get(palette, "bg-hover", bg_active)
    bg_mode   = get(palette, "bg-mode-line-active", bg_active)
    border_c  = get(palette, "border", bg_active)

    # Foreground shades
    fg_dim = get(palette, "fg-dim", fg)
    fg_alt = get(palette, "fg-alt", fg)

    # Diff
    bg_added   = get(palette, "bg-added", bg)
    bg_removed = get(palette, "bg-removed", bg)
    bg_changed = get(palette, "bg-changed", bg)

    # Subtle backgrounds
    bg_blue_subtle = get(palette, "bg-blue-subtle", bg_dim)
    bg_red_subtle  = get(palette, "bg-red-subtle", bg_dim)

    # Helpers for Zed's #rrggbbaa format
    def ff(c):
        return f"{c}ff"

    def alpha(c, a):
        return f"{c}{a}"

    theme = {
        "$schema": "https://zed.dev/schema/themes/v0.2.0.json",
        "name": "Prot Current",
        "author": "Auto-generated from Prot palette",
        "themes": [{
            "appearance": variant,
            "name": "Prot Current",
            "style": {
                # Accents
                "accents": [ff(red), ff(green), ff(yellow), ff(blue), ff(magenta), ff(cyan), ff(red_w)],

                # Borders
                "border": ff(border_c),
                "border.variant": ff(bg_active),
                "border.focused": ff(blue_f),
                "border.selected": ff(blue_f),
                "border.transparent": "#00000000",
                "border.disabled": ff(bg_active),

                # Surfaces
                "elevated_surface.background": ff(bg_dim),
                "surface.background": ff(bg_dim),
                "background": ff(bg_active),
                "element.background": ff(bg_dim),
                "element.hover": ff(bg_active),
                "element.active": ff(bg_hover),
                "element.selected": ff(bg_hover),
                "element.disabled": ff(bg_dim),
                "drop_target.background": alpha(blue_w, "80"),

                # Ghost elements
                "ghost_element.background": "#00000000",
                "ghost_element.hover": ff(bg_active),
                "ghost_element.active": ff(bg_hover),
                "ghost_element.selected": ff(bg_hover),
                "ghost_element.disabled": ff(bg_dim),

                # Text
                "text": ff(fg),
                "text.muted": ff(fg_alt),
                "text.placeholder": ff(fg_dim),
                "text.disabled": ff(fg_dim),
                "text.accent": ff(blue),

                # Icons
                "icon": ff(fg),
                "icon.muted": ff(fg_alt),
                "icon.disabled": ff(fg_dim),
                "icon.placeholder": ff(fg_alt),
                "icon.accent": ff(blue),

                # Status bar / title bar / toolbar / tabs
                "status_bar.background": ff(bg_active),
                "title_bar.background": ff(bg_active),
                "title_bar.inactive_background": ff(bg_dim),
                "toolbar.background": ff(bg),
                "tab_bar.background": ff(bg_dim),
                "tab.inactive_background": ff(bg_dim),
                "tab.active_background": ff(bg),

                # Search
                "search.match_background": alpha(blue, "66"),
                "search.active_match_background": alpha(yellow, "66"),

                # Panel
                "panel.background": ff(bg_dim),
                "panel.focused_border": ff(blue),
                "pane.focused_border": None,

                # Scrollbar
                "scrollbar.thumb.active_background": alpha(blue, "ac"),
                "scrollbar.thumb.hover_background": alpha(fg, "4c"),
                "scrollbar.thumb.background": alpha(fg_dim, "4c"),
                "scrollbar.thumb.border": ff(bg_active),
                "scrollbar.track.background": "#00000000",
                "scrollbar.track.border": ff(bg_dim),

                # Editor
                "editor.foreground": ff(fg),
                "editor.background": ff(bg),
                "editor.gutter.background": ff(bg),
                "editor.subheader.background": ff(bg_dim),
                "editor.active_line.background": alpha(bg_hl, "bf"),
                "editor.highlighted_line.background": ff(bg_hl),
                "editor.line_number": ff(fg_dim),
                "editor.active_line_number": ff(fg),
                "editor.hover_line_number": ff(fg_alt),
                "editor.invisible": ff(fg_dim),
                "editor.wrap_guide": alpha(fg, "0d"),
                "editor.active_wrap_guide": alpha(fg, "1a"),
                "editor.selection.background": ff(bg_region),
                "editor.document_highlight.read_background": alpha(blue, "1a"),
                "editor.document_highlight.write_background": alpha(fg_dim, "66"),
                "editor.diff.added_background": ff(bg_added),
                "editor.diff.deleted_background": ff(bg_removed),
                "editor.diff.modified_background": ff(bg_changed),

                # Picker
                "picker.input.background": ff(bg_dim),
                "picker.selection.background": ff(bg_region),

                # Terminal
                "terminal.background": ff(bg),
                "terminal.foreground": ff(fg),
                "terminal.bright_foreground": ff(fg),
                "terminal.dim_foreground": ff(fg_dim),
                "terminal.ansi.black": ff(bg),
                "terminal.ansi.bright_black": ff(bg_active),
                "terminal.ansi.dim_black": ff(fg),
                "terminal.ansi.red": ff(red),
                "terminal.ansi.bright_red": ff(red_w),
                "terminal.ansi.dim_red": ff(red_f),
                "terminal.ansi.green": ff(green),
                "terminal.ansi.bright_green": ff(green_w),
                "terminal.ansi.dim_green": ff(green_f),
                "terminal.ansi.yellow": ff(yellow),
                "terminal.ansi.bright_yellow": ff(yellow_w),
                "terminal.ansi.dim_yellow": ff(yellow),
                "terminal.ansi.blue": ff(blue),
                "terminal.ansi.bright_blue": ff(blue_w),
                "terminal.ansi.dim_blue": ff(blue_f),
                "terminal.ansi.magenta": ff(magenta),
                "terminal.ansi.bright_magenta": ff(magenta_w),
                "terminal.ansi.dim_magenta": ff(magenta_f),
                "terminal.ansi.cyan": ff(cyan),
                "terminal.ansi.bright_cyan": ff(cyan_c),
                "terminal.ansi.dim_cyan": ff(cyan_f),
                "terminal.ansi.white": ff(fg_dim),
                "terminal.ansi.bright_white": ff(fg),
                "terminal.ansi.dim_white": ff(fg_dim),

                # Links
                "link_text.hover": ff(blue),

                # Version control
                "version_control.added": ff(green_w),
                "version_control.modified": ff(yellow_w),
                "version_control.deleted": ff(red_w),

                # Status indicators
                "conflict": ff(yellow_w),
                "conflict.background": ff(bg_changed),
                "conflict.border": ff(yellow),
                "created": ff(green_w),
                "created.background": ff(bg_added),
                "created.border": ff(green),
                "deleted": ff(red_w),
                "deleted.background": ff(bg_removed),
                "deleted.border": ff(red),
                "error": ff(red_w),
                "error.background": ff(bg_red_subtle),
                "error.border": ff(red),
                "hidden": ff(fg_dim),
                "hidden.background": ff(bg_active),
                "hidden.border": ff(bg_active),
                "hint": ff(cyan_f),
                "hint.background": ff(bg_dim),
                "hint.border": ff(blue_f),
                "ignored": ff(fg_dim),
                "ignored.background": ff(bg_active),
                "ignored.border": ff(border_c),
                "info": ff(blue),
                "info.background": ff(bg_blue_subtle),
                "info.border": ff(blue_f),
                "modified": ff(yellow_w),
                "modified.background": ff(bg_changed),
                "modified.border": ff(yellow),
                "predictive": ff(fg_dim),
                "predictive.background": ff(bg_dim),
                "predictive.border": ff(bg_active),
                "renamed": ff(blue),
                "renamed.background": ff(bg_blue_subtle),
                "renamed.border": ff(blue_f),
                "success": ff(green_w),
                "success.background": ff(bg_added),
                "success.border": ff(green),
                "unreachable": ff(fg_alt),
                "unreachable.background": ff(bg_active),
                "unreachable.border": ff(border_c),
                "warning": ff(yellow_w),
                "warning.background": ff(bg_changed),
                "warning.border": ff(yellow),

                # Players
                "players": [
                    {"cursor": ff(blue), "background": ff(blue), "selection": alpha(blue, "3d")},
                    {"cursor": ff(fg_dim), "background": ff(fg_dim), "selection": alpha(fg_dim, "3d")},
                    {"cursor": ff(red_w), "background": ff(red_w), "selection": alpha(red_w, "3d")},
                    {"cursor": ff(magenta_w), "background": ff(magenta_w), "selection": alpha(magenta_w, "3d")},
                    {"cursor": ff(cyan_c), "background": ff(cyan_c), "selection": alpha(cyan_c, "3d")},
                    {"cursor": ff(red), "background": ff(red), "selection": alpha(red, "3d")},
                    {"cursor": ff(yellow_w), "background": ff(yellow_w), "selection": alpha(yellow_w, "3d")},
                    {"cursor": ff(green_w), "background": ff(green_w), "selection": alpha(green_w, "3d")},
                ],

                # Syntax — follows Prot's Emacs face conventions
                "syntax": {
                    "attribute":          {"color": ff(red),       "font_style": None, "font_weight": None},
                    "boolean":            {"color": ff(blue),      "font_style": None, "font_weight": None},
                    "comment":            {"color": ff(fg_dim),    "font_style": "italic", "font_weight": None},
                    "comment.doc":        {"color": ff(fg_alt),    "font_style": "italic", "font_weight": None},
                    "constant":           {"color": ff(blue),      "font_style": None, "font_weight": None},
                    "constructor":        {"color": ff(magenta),   "font_style": None, "font_weight": None},
                    "embedded":           {"color": ff(red),       "font_style": None, "font_weight": None},
                    "emphasis":           {"color": ff(blue),      "font_style": "italic", "font_weight": None},
                    "emphasis.strong":    {"color": ff(blue),      "font_style": None, "font_weight": 700},
                    "enum":              {"color": ff(cyan_w),     "font_style": None, "font_weight": None},
                    "function":           {"color": ff(magenta),   "font_style": None, "font_weight": None},
                    "function.builtin":   {"color": ff(magenta_w), "font_style": None, "font_weight": None},
                    "hint":               {"color": ff(cyan_f),    "font_style": None, "font_weight": None},
                    "keyword":            {"color": ff(magenta_c), "font_style": None, "font_weight": None},
                    "label":              {"color": ff(cyan),      "font_style": None, "font_weight": None},
                    "link_text":          {"color": ff(cyan_w),    "font_style": "italic", "font_weight": None},
                    "link_uri":           {"color": ff(blue_w),    "font_style": None, "font_weight": None},
                    "namespace":          {"color": ff(cyan_w),    "font_style": None, "font_weight": None},
                    "number":             {"color": ff(fg),        "font_style": None, "font_weight": None},
                    "operator":           {"color": ff(magenta),   "font_style": None, "font_weight": None},
                    "predictive":         {"color": ff(fg_dim),    "font_style": "italic", "font_weight": None},
                    "preproc":            {"color": ff(red_c),     "font_style": None, "font_weight": None},
                    "primary":            {"color": ff(fg),        "font_style": None, "font_weight": None},
                    "property":           {"color": ff(blue),      "font_style": None, "font_weight": None},
                    "punctuation":        {"color": ff(fg),        "font_style": None, "font_weight": None},
                    "punctuation.bracket":    {"color": ff(fg_dim), "font_style": None, "font_weight": None},
                    "punctuation.delimiter":  {"color": ff(fg),    "font_style": None, "font_weight": None},
                    "punctuation.list_marker": {"color": ff(fg),   "font_style": None, "font_weight": None},
                    "punctuation.markup":     {"color": ff(cyan),  "font_style": None, "font_weight": None},
                    "punctuation.special":    {"color": ff(red),   "font_style": None, "font_weight": None},
                    "selector":           {"color": ff(magenta_c), "font_style": None, "font_weight": None},
                    "selector.pseudo":    {"color": ff(cyan),      "font_style": None, "font_weight": None},
                    "string":             {"color": ff(blue_w),    "font_style": None, "font_weight": None},
                    "string.escape":      {"color": ff(blue_w),    "font_style": None, "font_weight": None},
                    "string.regex":       {"color": ff(magenta_c), "font_style": None, "font_weight": None},
                    "string.special":     {"color": ff(blue_w),    "font_style": None, "font_weight": None},
                    "string.special.symbol": {"color": ff(blue_w), "font_style": None, "font_weight": None},
                    "tag":                {"color": ff(blue),      "font_style": None, "font_weight": None},
                    "text.literal":       {"color": ff(magenta),   "font_style": None, "font_weight": None},
                    "title":              {"color": ff(fg_dim),    "font_style": None, "font_weight": None},
                    "type":               {"color": ff(cyan),      "font_style": None, "font_weight": None},
                    "variable":           {"color": ff(cyan_w),    "font_style": None, "font_weight": None},
                    "variable.special":   {"color": ff(magenta_c), "font_style": None, "font_weight": None},
                    "variant":            {"color": ff(cyan),      "font_style": None, "font_weight": None},
                },
            },
        }],
    }

    out.write_text(json.dumps(theme, indent=2) + "\n")
    print(f"Generated Zed theme: {out}")


# ---------------------------------------------------------------------------
# Dispatch: run all generators
# ---------------------------------------------------------------------------

ALL_GENERATORS = [
    generate_ghostty,
    generate_xonsh,
    generate_sketchybar,
    generate_borders,
    generate_wallpaper,
    generate_glamour,
    generate_helix,
    generate_zed,
]


def generate_all(palette: dict, name: str, variant: str):
    """Run all generators for a given theme."""
    for gen in ALL_GENERATORS:
        try:
            gen(palette, name, variant)
        except Exception as e:
            print(f"Warning: {gen.__name__} failed: {e}")
