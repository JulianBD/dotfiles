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

def generate_ghostty(palette: dict, name: str, variant: str, roles: dict | None = None):
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

def generate_sketchybar(palette: dict, name: str, variant: str, roles: dict | None = None):
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

def generate_borders(palette: dict, name: str, variant: str, roles: dict | None = None):
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

def generate_wallpaper(palette: dict, name: str, variant: str, roles: dict | None = None):
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

def generate_glamour(palette: dict, name: str, variant: str, roles: dict | None = None):
    """Write ~/.config/glamour/style.json."""
    out = Path.home() / ".config/glamour/style.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    r = roles or {}

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

    # Syntax roles
    c_keyword   = r.get("keyword", get(palette, "magenta-cooler", magenta))
    c_function  = r.get("function", magenta)
    c_string    = r.get("string", get(palette, "yellow-warmer", yellow))
    c_type      = r.get("type", cyan_w)
    c_constant  = r.get("constant", get(palette, "magenta-cooler", magenta))
    c_comment   = r.get("comment", dim)
    c_operator  = r.get("operator", red)
    c_builtin   = r.get("builtin", blue_w)
    c_preproc   = r.get("preprocessor", cyan)
    c_tag       = r.get("tag", magenta)
    c_attribute = r.get("attribute", cyan)
    c_number    = r.get("number", cyan)
    c_docstring = r.get("docstring", get(palette, "green-cooler", green))
    c_namespace = r.get("namespace", red)
    c_property  = r.get("property", blue)

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
        "code": {"prefix": " ", "suffix": " ", "color": c_docstring},
        "code_block": {
            "color": fg, "margin": 2,
            "chroma": {
                "text": {"color": fg},
                "error": {"color": red},
                "comment": {"color": c_comment, "italic": True},
                "comment_preproc": {"color": c_preproc},
                "keyword": {"color": c_keyword, "bold": True},
                "keyword_reserved": {"color": c_keyword, "bold": True},
                "keyword_namespace": {"color": c_namespace},
                "keyword_type": {"color": c_type},
                "operator": {"color": c_operator},
                "punctuation": {"color": dim},
                "name": {},
                "name_builtin": {"color": c_builtin},
                "name_tag": {"color": c_tag},
                "name_attribute": {"color": c_attribute},
                "name_class": {"color": c_type, "underline": True, "bold": True},
                "name_constant": {"color": c_constant},
                "name_decorator": {"color": yellow},
                "name_exception": {},
                "name_function": {"color": c_function},
                "name_other": {},
                "literal": {},
                "literal_number": {"color": c_number},
                "literal_date": {},
                "literal_string": {"color": c_string},
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

def generate_helix(palette: dict, name: str, variant: str, roles: dict | None = None):
    """Write ~/.config/helix/themes/prot-current.toml.

    Full coverage of Helix's syntax scopes and UI keys. Syntax colors
    come from the roles dict (family philosophy); UI colors from palette.
    """
    out = Path.home() / ".config/helix/themes/prot-current.toml"
    out.parent.mkdir(parents=True, exist_ok=True)
    r = roles or {}

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

    # Resolve syntax roles (fall back to Prot's convention if no roles)
    c_kw      = r.get("keyword", magenta_c)
    c_fn      = r.get("function", magenta)
    c_str     = r.get("string", blue_w)
    c_type    = r.get("type", cyan)
    c_var     = r.get("variable", cyan_w)
    c_const   = r.get("constant", blue)
    c_comment = r.get("comment", fg_dim)
    c_op      = r.get("operator", magenta)
    c_tag     = r.get("tag", blue)
    c_attr    = r.get("attribute", red)
    c_ns      = r.get("namespace", cyan_w)
    c_ctor    = r.get("constructor", magenta)
    c_builtin = r.get("builtin", magenta_w)
    c_preproc = r.get("preprocessor", red_c)
    c_doc     = r.get("docstring", green_f)
    c_num     = r.get("number", fg)
    c_prop    = r.get("property", blue)

    lines = [
        f"# Auto-generated from palette: {name}",
        "",
        "# --- Syntax ---",
        '"comment" = { fg = "c_comment", modifiers = ["italic"] }',
        '"comment.line" = { fg = "c_comment", modifiers = ["italic"] }',
        '"comment.line.documentation" = { fg = "c_doc", modifiers = ["italic"] }',
        '"comment.block" = { fg = "c_comment", modifiers = ["italic"] }',
        '"comment.block.documentation" = { fg = "c_doc", modifiers = ["italic"] }',
        '"comment.unused" = { fg = "yellow_f", modifiers = ["italic"] }',
        "",
        '"constant" = "c_const"',
        '"constant.builtin" = "c_const"',
        '"constant.builtin.boolean" = "c_const"',
        '"constant.character" = "c_str"',
        '"constant.character.escape" = "c_str"',
        '"constant.numeric" = "c_num"',
        '"constant.numeric.integer" = "c_num"',
        '"constant.numeric.float" = "c_num"',
        "",
        '"string" = "c_str"',
        '"string.regexp" = "c_kw"',
        '"string.special" = "c_str"',
        '"string.special.path" = "cyan_f"',
        '"string.special.url" = { fg = "c_str", modifiers = ["underlined"] }',
        '"string.special.symbol" = "c_str"',
        "",
        '"type" = "c_type"',
        '"type.builtin" = "c_type"',
        '"type.parameter" = "cyan_f"',
        '"type.enum" = "c_type"',
        '"type.enum.variant" = "c_type"',
        '"constructor" = "c_ctor"',
        "",
        '"function" = "c_fn"',
        '"function.builtin" = "c_builtin"',
        '"function.method" = "c_fn"',
        '"function.macro" = "c_preproc"',
        '"function.special" = "c_builtin"',
        "",
        '"keyword" = "c_kw"',
        '"keyword.control" = "c_kw"',
        '"keyword.control.conditional" = "c_kw"',
        '"keyword.control.repeat" = "c_kw"',
        '"keyword.control.import" = "c_kw"',
        '"keyword.control.return" = "c_kw"',
        '"keyword.control.exception" = "c_preproc"',
        '"keyword.operator" = "c_op"',
        '"keyword.directive" = "c_preproc"',
        '"keyword.function" = "c_kw"',
        '"keyword.storage" = "c_kw"',
        '"keyword.storage.type" = "c_type"',
        '"keyword.storage.modifier" = "c_kw"',
        "",
        '"operator" = "c_op"',
        '"label" = "c_type"',
        '"namespace" = "c_ns"',
        "",
        '"tag" = "c_tag"',
        '"tag.builtin" = "c_tag"',
        '"attribute" = "c_attr"',
        "",
        '"variable" = "c_var"',
        '"variable.builtin" = "c_builtin"',
        '"variable.parameter" = "c_var"',
        '"variable.other.member" = "c_prop"',
        '"variable.other.member.private" = "c_prop"',
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
        '"markup.heading.3" = { fg = "c_kw", modifiers = ["bold"] }',
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
        '"markup.raw" = "c_fn"',
        '"markup.raw.inline" = "c_fn"',
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
        # Syntax roles
        f'c_kw = "{c_kw}"',
        f'c_fn = "{c_fn}"',
        f'c_str = "{c_str}"',
        f'c_type = "{c_type}"',
        f'c_var = "{c_var}"',
        f'c_const = "{c_const}"',
        f'c_comment = "{c_comment}"',
        f'c_op = "{c_op}"',
        f'c_tag = "{c_tag}"',
        f'c_attr = "{c_attr}"',
        f'c_ns = "{c_ns}"',
        f'c_ctor = "{c_ctor}"',
        f'c_builtin = "{c_builtin}"',
        f'c_preproc = "{c_preproc}"',
        f'c_doc = "{c_doc}"',
        f'c_num = "{c_num}"',
        f'c_prop = "{c_prop}"',
    ]

    out.write_text("\n".join(lines) + "\n")
    print(f"Generated helix theme: {out}")


# ---------------------------------------------------------------------------
# Zed
# ---------------------------------------------------------------------------

def generate_zed(palette: dict, name: str, variant: str, roles: dict | None = None):
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

    # Syntax roles
    r = roles or {}
    c_kw      = r.get("keyword", magenta_c)
    c_fn      = r.get("function", magenta)
    c_str     = r.get("string", blue_w)
    c_type    = r.get("type", cyan)
    c_var     = r.get("variable", cyan_w)
    c_const   = r.get("constant", blue)
    c_comment = r.get("comment", fg_dim)
    c_op      = r.get("operator", magenta)
    c_tag     = r.get("tag", blue)
    c_attr    = r.get("attribute", red)
    c_ns      = r.get("namespace", cyan_w)
    c_ctor    = r.get("constructor", magenta)
    c_builtin = r.get("builtin", magenta_w)
    c_preproc = r.get("preprocessor", red_c)
    c_num     = r.get("number", fg)
    c_prop    = r.get("property", blue)

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

                # Syntax — roles drive color assignment per family philosophy
                "syntax": {
                    "attribute":          {"color": ff(c_attr),    "font_style": None, "font_weight": None},
                    "boolean":            {"color": ff(c_const),   "font_style": None, "font_weight": None},
                    "comment":            {"color": ff(c_comment), "font_style": "italic", "font_weight": None},
                    "comment.doc":        {"color": ff(fg_alt),    "font_style": "italic", "font_weight": None},
                    "constant":           {"color": ff(c_const),   "font_style": None, "font_weight": None},
                    "constructor":        {"color": ff(c_ctor),    "font_style": None, "font_weight": None},
                    "embedded":           {"color": ff(red),       "font_style": None, "font_weight": None},
                    "emphasis":           {"color": ff(blue),      "font_style": "italic", "font_weight": None},
                    "emphasis.strong":    {"color": ff(blue),      "font_style": None, "font_weight": 700},
                    "enum":              {"color": ff(c_type),     "font_style": None, "font_weight": None},
                    "function":           {"color": ff(c_fn),      "font_style": None, "font_weight": None},
                    "function.builtin":   {"color": ff(c_builtin), "font_style": None, "font_weight": None},
                    "hint":               {"color": ff(cyan_f),    "font_style": None, "font_weight": None},
                    "keyword":            {"color": ff(c_kw),      "font_style": None, "font_weight": None},
                    "label":              {"color": ff(c_type),    "font_style": None, "font_weight": None},
                    "link_text":          {"color": ff(cyan_w),    "font_style": "italic", "font_weight": None},
                    "link_uri":           {"color": ff(blue_w),    "font_style": None, "font_weight": None},
                    "namespace":          {"color": ff(c_ns),      "font_style": None, "font_weight": None},
                    "number":             {"color": ff(c_num),     "font_style": None, "font_weight": None},
                    "operator":           {"color": ff(c_op),      "font_style": None, "font_weight": None},
                    "predictive":         {"color": ff(fg_dim),    "font_style": "italic", "font_weight": None},
                    "preproc":            {"color": ff(c_preproc), "font_style": None, "font_weight": None},
                    "primary":            {"color": ff(fg),        "font_style": None, "font_weight": None},
                    "property":           {"color": ff(c_prop),    "font_style": None, "font_weight": None},
                    "punctuation":        {"color": ff(fg),        "font_style": None, "font_weight": None},
                    "punctuation.bracket":    {"color": ff(fg_dim), "font_style": None, "font_weight": None},
                    "punctuation.delimiter":  {"color": ff(fg),    "font_style": None, "font_weight": None},
                    "punctuation.list_marker": {"color": ff(fg),   "font_style": None, "font_weight": None},
                    "punctuation.markup":     {"color": ff(cyan),  "font_style": None, "font_weight": None},
                    "punctuation.special":    {"color": ff(red),   "font_style": None, "font_weight": None},
                    "selector":           {"color": ff(c_kw),      "font_style": None, "font_weight": None},
                    "selector.pseudo":    {"color": ff(c_type),    "font_style": None, "font_weight": None},
                    "string":             {"color": ff(c_str),     "font_style": None, "font_weight": None},
                    "string.escape":      {"color": ff(c_str),     "font_style": None, "font_weight": None},
                    "string.regex":       {"color": ff(c_kw),      "font_style": None, "font_weight": None},
                    "string.special":     {"color": ff(c_str),     "font_style": None, "font_weight": None},
                    "string.special.symbol": {"color": ff(c_str),  "font_style": None, "font_weight": None},
                    "tag":                {"color": ff(c_tag),     "font_style": None, "font_weight": None},
                    "text.literal":       {"color": ff(c_fn),      "font_style": None, "font_weight": None},
                    "title":              {"color": ff(fg_dim),    "font_style": None, "font_weight": None},
                    "type":               {"color": ff(c_type),    "font_style": None, "font_weight": None},
                    "variable":           {"color": ff(c_var),     "font_style": None, "font_weight": None},
                    "variable.special":   {"color": ff(c_builtin), "font_style": None, "font_weight": None},
                    "variant":            {"color": ff(c_type),    "font_style": None, "font_weight": None},
                },
            },
        }],
    }

    out.write_text(json.dumps(theme, indent=2) + "\n")
    print(f"Generated Zed theme: {out}")


# ---------------------------------------------------------------------------
# Obsidian
# ---------------------------------------------------------------------------

def generate_obsidian(palette: dict, name: str, variant: str, roles: dict | None = None):
    """Write prot-schemes.css to the Obsidian vault snippets directory.

    Targets the Minimal theme (kepano). Sets Minimal's CSS variables with
    !important to win against Minimal's equal-specificity defaults. Covers
    the full variable surface: base/accent HSL, backgrounds, borders, text,
    highlights, extended colors, headings, links, tags, code syntax, graphs,
    blockquotes, icons, tabs, titles, frame, embeds, and indent guides.

    The ACTIVE block (top of file) is rewritten on every apply. Any named-class
    section below the sentinel comment is preserved for compile-obsidian-schemes.

    Doric themes lack bg-dim/bg-active/bg-hl-line — explicit fallback chains
    handle them.
    """
    import colorsys

    vault = Path.home() / "Documents/pkm"
    snippets_dir = vault / ".obsidian/snippets"
    out = snippets_dir / "prot-schemes.css"

    if not (vault / ".obsidian").exists():
        print(f"Warning: Obsidian vault not found at {vault}, skipping")
        return

    snippets_dir.mkdir(parents=True, exist_ok=True)

    bg = palette["bg-main"]
    fg = palette["fg-main"]
    cursor = get(palette, "cursor", fg)

    # Surfaces — doric fallbacks (bg-dim→bg-shadow-subtle, bg-active→bg-neutral, etc.)
    bg_dim    = get(palette, "bg-dim",              get(palette, "bg-shadow-subtle", bg))
    bg_hl     = get(palette, "bg-hl-line",          get(palette, "bg-neutral",       bg_dim))
    bg_active = get(palette, "bg-active",           get(palette, "bg-neutral",       bg_dim))
    bg_mode   = get(palette, "bg-mode-line-active", get(palette, "fg-shadow-subtle", bg_active))

    # Text shades — doric fallbacks
    fg_dim = get(palette, "fg-dim", get(palette, "fg-neutral",       fg))
    fg_alt = get(palette, "fg-alt", get(palette, "fg-shadow-subtle", fg))

    # Accent — doric fallbacks
    accent = get(palette, "blue", get(palette, "fg-blue", get(palette, "fg-accent", fg)))

    # Named colors
    red       = get(palette, "red",             fg)
    orange    = get(palette, "orange",          red)
    yellow    = get(palette, "yellow",          fg)
    green     = get(palette, "green",           fg)
    cyan      = get(palette, "cyan",            accent)
    magenta   = get(palette, "magenta",         fg)
    magenta_w = get(palette, "magenta-warmer",  magenta)

    # Temperature variants for syntax/headings/links
    blue_w    = get(palette, "blue-warmer",     accent)
    magenta_c = get(palette, "magenta-cooler",  magenta)
    red_c     = get(palette, "red-cooler",      red)
    red_f     = get(palette, "red-faint",       red)
    cyan_w    = get(palette, "cyan-warmer",     cyan)

    # Syntax roles for code block CSS vars
    ro = roles or {}
    c_kw      = ro.get("keyword", magenta_c)
    c_fn      = ro.get("function", magenta)
    c_str     = ro.get("string", blue_w)
    c_op      = ro.get("operator", magenta)
    c_preproc = ro.get("preprocessor", red_c)
    c_prop    = ro.get("property", cyan)
    c_tag     = ro.get("tag", accent)
    c_const   = ro.get("constant", accent)
    c_comment = ro.get("comment", fg_dim)

    def hex_to_rgb(h: str) -> str:
        h = h.lstrip("#")
        return f"{int(h[0:2],16)},{int(h[2:4],16)},{int(h[4:6],16)}"

    def hex_to_hsl(h: str) -> tuple[int, int, int]:
        h = h.lstrip("#")
        r, g, b = int(h[0:2],16)/255, int(h[2:4],16)/255, int(h[4:6],16)/255
        hue, light, sat = colorsys.rgb_to_hls(r, g, b)  # note: HLS order
        return round(hue * 360), round(sat * 100), round(light * 100)

    base_h, base_s, base_l   = hex_to_hsl(bg)
    acc_h,  acc_s,  acc_l    = hex_to_hsl(accent)

    theme_class = f".theme-{variant}"

    # !important is needed — Minimal's own defaults have equal specificity
    # and load before snippets in some Obsidian builds
    i = " !important"

    active_block = "\n".join([
        "/* prot-schemes — auto-generated, do not edit manually */",
        f"/* ACTIVE: {name} ({variant}) */",
        f"{theme_class} {{",
        "",
        "  /* --- Base & Accent (HSL for Minimal's internal derivation) --- */",
        f"  --base-h: {base_h}{i};",
        f"  --base-s: {base_s}%{i};",
        f"  --base-l: {base_l}%{i};",
        f"  --accent-h: {acc_h}{i};",
        f"  --accent-s: {acc_s}%{i};",
        f"  --accent-l: {acc_l}%{i};",
        "",
        "  /* --- Accent colors (explicit overrides) --- */",
        f"  --ax1: {accent}{i};",
        f"  --ax2: {blue_w}{i};",
        f"  --ax3: {blue_w}{i};",
        f"  --sp1: {bg}{i};",
        "",
        "  /* --- Backgrounds --- */",
        f"  --bg1: {bg}{i};",
        f"  --bg2: {bg_dim}{i};",
        f"  --bg3: {bg_hl}{i};",
        "",
        "  /* --- UI (borders, dividers) --- */",
        f"  --ui1: {bg_active}{i};",
        f"  --ui2: {bg_mode}{i};",
        f"  --ui3: {fg_dim}{i};",
        "",
        "  /* --- Text --- */",
        f"  --tx1: {fg}{i};",
        f"  --tx2: {fg_dim}{i};",
        f"  --tx3: {fg_alt}{i};",
        "",
        "  /* --- Highlights --- */",
        f"  --hl1: rgba({hex_to_rgb(accent)}, 0.3){i};",
        f"  --hl2: rgba({hex_to_rgb(yellow)}, 0.3){i};",
        "",
        "  /* --- Extended colors --- */",
        f"  --color-red:    {red}{i};",
        f"  --color-orange: {orange}{i};",
        f"  --color-yellow: {yellow}{i};",
        f"  --color-green:  {green}{i};",
        f"  --color-cyan:   {cyan}{i};",
        f"  --color-blue:   {accent}{i};",
        f"  --color-purple: {magenta}{i};",
        f"  --color-pink:   {magenta_w}{i};",
        "",
        f"  --color-red-rgb:    {hex_to_rgb(red)}{i};",
        f"  --color-orange-rgb: {hex_to_rgb(orange)}{i};",
        f"  --color-yellow-rgb: {hex_to_rgb(yellow)}{i};",
        f"  --color-green-rgb:  {hex_to_rgb(green)}{i};",
        f"  --color-cyan-rgb:   {hex_to_rgb(cyan)}{i};",
        f"  --color-blue-rgb:   {hex_to_rgb(accent)}{i};",
        f"  --color-purple-rgb: {hex_to_rgb(magenta)}{i};",
        f"  --color-pink-rgb:   {hex_to_rgb(magenta_w)}{i};",
        "",
        "  /* --- Headings --- */",
        f"  --h1-color: {accent}{i};",
        f"  --h2-color: {cyan}{i};",
        f"  --h3-color: {magenta_c}{i};",
        f"  --h4-color: {yellow}{i};",
        f"  --h5-color: {green}{i};",
        f"  --h6-color: {red_f}{i};",
        "",
        "  /* --- Links --- */",
        f"  --link-color:                {cyan_w}{i};",
        f"  --link-color-hover:          {cyan}{i};",
        f"  --link-external-color:       {blue_w}{i};",
        f"  --link-external-color-hover: {accent}{i};",
        f"  --link-unresolved-color:     {fg_dim}{i};",
        f"  --link-unresolved-decoration-color: {fg_dim}{i};",
        "",
        "  /* --- Tags --- */",
        f"  --tag-color: {accent}{i};",
        f"  --tag-bg:    rgba({hex_to_rgb(accent)}, 0.1){i};",
        "",
        "  /* --- Code blocks & syntax highlighting --- */",
        f"  --code-background:  {bg_dim}{i};",
        f"  --code-normal:      {fg}{i};",
        f"  --code-comment:     {c_comment}{i};",
        f"  --code-function:    {c_fn}{i};",
        f"  --code-keyword:     {c_kw}{i};",
        f"  --code-important:   {c_preproc}{i};",
        f"  --code-operator:    {c_op}{i};",
        f"  --code-property:    {c_prop}{i};",
        f"  --code-punctuation: {fg_dim}{i};",
        f"  --code-string:      {c_str}{i};",
        f"  --code-tag:         {c_tag}{i};",
        f"  --code-value:       {c_const}{i};",
        "",
        "  /* --- Blockquotes --- */",
        f"  --blockquote-color:        {fg_dim}{i};",
        f"  --blockquote-border-color: {fg_dim}{i};",
        "",
        "  /* --- Active line (tinted from cursor) --- */",
        f"  --active-line-bg: rgba({hex_to_rgb(cursor)}, 0.15){i};",
        "",
        "  /* --- Indentation guides --- */",
        f"  --indentation-guide-color:        {bg_active}{i};",
        f"  --indentation-guide-color-active: {fg_dim}{i};",
        "",
        "  /* --- Icons --- */",
        f"  --icon-color:        {fg_dim}{i};",
        f"  --icon-color-hover:  {fg_alt}{i};",
        f"  --icon-color-active: {accent}{i};",
        "",
        "  /* --- Graph --- */",
        f"  --graph-node:            {accent}{i};",
        f"  --graph-node-focused:    {cyan}{i};",
        f"  --graph-node-tag:        {magenta}{i};",
        f"  --graph-node-attachment: {green}{i};",
        f"  --graph-node-unresolved: {fg_dim}{i};",
        "",
        "  /* --- Checkbox --- */",
        f"  --checkbox-color: {green}{i};",
        "",
        "  /* --- Tabs --- */",
        f"  --minimal-tab-text-color:        {fg_dim}{i};",
        f"  --minimal-tab-text-color-active: {fg}{i};",
        "",
        "  /* --- Titles --- */",
        f"  --title-color:          {fg}{i};",
        f"  --title-color-inactive: {fg_dim}{i};",
        f"  --inline-title-color:   {fg}{i};",
        "",
        "  /* --- Window frame --- */",
        f"  --frame-background: {bg_mode}{i};",
        f"  --frame-icon-color: {fg_dim}{i};",
        "",
        "  /* --- Embeds --- */",
        f"  --embed-background: {bg_dim}{i};",
        "",
        "  /* --- Cursor --- */",
        f"  --cursor: {cursor}{i};",
        "}",
        "",
        "/* --- Active line (bypass Style Settings toggle) --- */",
        f".workspace-leaf-content[data-type=markdown] .cm-line.cm-active,",
        f".workspace-leaf-content[data-type=markdown] .markdown-source-view.mod-cm6.is-live-preview .HyperMD-quote.cm-active {{",
        f"  background-color: var(--active-line-bg){i};",
        f"  box-shadow: -25vw 0px var(--active-line-bg), 25vw 0 var(--active-line-bg);",
        f"}}",
        "",
    ])

    # Preserve named-class section (compile-obsidian-schemes output)
    sentinel = "/* ---- All prot schemes as named classes ---- */"
    existing = out.read_text() if out.exists() else ""
    named_section = existing[existing.index(sentinel):] if sentinel in existing else ""

    out.write_text(active_block + (named_section if named_section else ""))
    print(f"Generated Obsidian snippet: {out}")


# ---------------------------------------------------------------------------
# Dispatch: run all generators
# ---------------------------------------------------------------------------

ALL_GENERATORS = [
    generate_ghostty,
    generate_sketchybar,
    generate_borders,
    generate_wallpaper,
    generate_glamour,
    generate_helix,
    generate_zed,
    generate_obsidian,
]


def generate_all(palette: dict, name: str, variant: str,
                 roles: dict | None = None, skip: set | None = None):
    """Run all generators for a given theme, optionally skipping some."""
    for gen in ALL_GENERATORS:
        if skip and gen.__name__ in skip:
            continue
        try:
            gen(palette, name, variant, roles=roles)
        except Exception as e:
            print(f"Warning: {gen.__name__} failed: {e}")
