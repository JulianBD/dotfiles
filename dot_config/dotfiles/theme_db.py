#!/usr/bin/env python3
"""Build the unified theme database from all theme families.

Runs all parsers, merges colors+semantic into a single flat lookup per theme,
normalizes doric naming, and resolves syntax roles per family philosophy.

Each theme entry has:
    palette  — flat dict of palette key → hex color
    roles    — dict of abstract syntax role → hex color (resolved from
               Emacs semantic keys or the family's role map)
    family, variant — metadata

The "roles" dict decouples syntax philosophy from palette. Prot's families
use his Emacs face conventions (keyword→purple, function→magenta). Flexoki
uses Steph Ango's conventions (keyword→green, function→orange). Generators
read roles to produce correct output for any family.
"""

import json
import sys
from pathlib import Path

# Import the per-family parsers
SCRIPT_DIR = Path(__file__).parent
sys.path.insert(0, str(SCRIPT_DIR))

from parse_modus import parse_modus
from parse_ef import parse_ef_themes
from parse_standard import parse_standard_themes
from parse_doric import parse_doric_themes
from parse_flexoki import parse_flexoki

# Default source locations
SOURCES = Path.home() / ".local/share/dotfiles/theme-sources"


# --- Doric name normalization ---
# Maps doric-specific names to the modus/ef/standard canonical name.
# Only maps where there's a clear semantic equivalence based on how
# Prot uses the keys in doric-themes.el face definitions.

DORIC_NAME_MAP = {
    # Foreground accent colors → bare color names
    "fg-red":     "red",
    "fg-green":   "green",
    "fg-yellow":  "yellow",
    "fg-blue":    "blue",
    "fg-magenta": "magenta",
    "fg-cyan":    "cyan",

    # Background accent colors → bg-COLOR-subtle (closest match:
    # doric bg-red is used like modus bg-red-subtle, not bg-red-intense)
    "bg-red":     "bg-red-subtle",
    "bg-green":   "bg-green-subtle",
    "bg-yellow":  "bg-yellow-subtle",
    "bg-blue":    "bg-blue-subtle",
    "bg-magenta": "bg-magenta-subtle",
    "bg-cyan":    "bg-cyan-subtle",

    # Surface colors
    "bg-shadow-subtle":  "bg-dim",
    "fg-shadow-subtle":  "fg-dim",
    "bg-neutral":        "bg-active",
    "fg-neutral":        "fg-alt",
    "bg-shadow-intense": "bg-inactive",
    "fg-shadow-intense": "fg-alt",  # doric uses this for bold/accent contexts

    # Accent pair → closest modus equivalents
    "bg-accent": "bg-hover",
    "fg-accent": "accent-0",  # doric uses fg-accent as the primary accent
}


def merge_theme(colors: dict, semantic: dict) -> dict:
    """Merge colors and resolved semantic into one flat palette.

    Colors take precedence over semantic when both define the same key,
    since a direct hex value is more specific than a resolved reference.
    """
    merged = {}
    merged.update(semantic)
    merged.update(colors)
    return merged


def normalize_doric(palette: dict) -> dict:
    """Remap doric-specific key names into canonical modus vocabulary.

    Keeps both the original doric name and the canonical name so
    generators can use either. The original is preserved because some
    generators might want the doric-specific semantics.
    """
    normalized = {}
    for key, value in palette.items():
        # Always keep the original key
        normalized[key] = value
        # Add canonical alias if one exists
        if key in DORIC_NAME_MAP:
            canonical = DORIC_NAME_MAP[key]
            # Don't overwrite if the canonical name already exists
            # (shouldn't happen with doric, but defensive)
            if canonical not in normalized:
                normalized[canonical] = value
    return normalized


# --- Syntax role resolution ---
# Maps Emacs semantic palette keys to abstract role names.
# Modus, ef, and standard palettes already carry these as resolved hex.
EMACS_TO_ROLE = {
    "keyword": "keyword",
    "fnname": "function",
    "string": "string",
    "type": "type",
    "variable": "variable",
    "constant": "constant",
    "comment": "comment",
    "operator": "operator",
    "builtin": "builtin",
    "preprocessor": "preprocessor",
    "docstring": "docstring",
    "number": "number",
    "property": "property",
}

# Prot's convention for roles not in the Emacs semantic layer.
# Used by all Prot families; also the full fallback for doric
# (which lacks the Emacs semantic keys entirely).
PROT_ROLE_MAP = {
    "keyword":      "magenta-cooler",
    "function":     "magenta",
    "string":       "blue-warmer",
    "type":         "cyan",
    "variable":     "cyan-warmer",
    "constant":     "blue",
    "comment":      "fg-dim",
    "operator":     "magenta",
    "builtin":      "magenta-warmer",
    "preprocessor": "red-cooler",
    "docstring":    "green-cooler",
    "number":       "fg-main",
    "property":     "blue",
    "tag":          "blue",
    "attribute":    "red",
    "namespace":    "cyan-warmer",
    "constructor":  "magenta",
}


def resolve_roles(palette: dict, role_map: dict | None = None) -> dict:
    """Build resolved roles dict: abstract role name → hex color.

    First pulls from Emacs semantic keys already in the palette (modus/ef/standard).
    Then fills gaps from the role_map (needed for doric, flexoki, etc.).
    """
    roles = {}
    # 1. Pull from Emacs semantic keys already in palette
    for emacs_key, role in EMACS_TO_ROLE.items():
        if emacs_key in palette:
            roles[role] = palette[emacs_key]
    # 2. Fill from role_map for anything missing
    if role_map:
        for role, palette_key in role_map.items():
            if role not in roles and palette_key in palette:
                roles[role] = palette[palette_key]
    return roles


def build_db() -> dict:
    """Build the complete theme database from all families."""
    db = {}

    # --- Modus ---
    modus_el = SOURCES / "modus-themes/modus-themes.el"
    if modus_el.exists():
        modus = parse_modus(modus_el.read_text())
        for name, theme in modus.items():
            palette = merge_theme(theme["colors"], theme["semantic"])
            db[name] = {
                "family": "modus",
                "variant": theme["variant"],
                "palette": palette,
                "roles": resolve_roles(palette, PROT_ROLE_MAP),
            }

    # --- Ef ---
    ef_dir = SOURCES / "ef-themes"
    if ef_dir.is_dir():
        ef = parse_ef_themes(ef_dir)
        for name, theme in ef.items():
            palette = merge_theme(theme["colors"], theme["semantic"])
            db[name] = {
                "family": "ef",
                "variant": theme["variant"],
                "palette": palette,
                "roles": resolve_roles(palette, PROT_ROLE_MAP),
            }

    # --- Standard ---
    std_dir = SOURCES / "standard-themes"
    if std_dir.is_dir():
        std = parse_standard_themes(std_dir)
        for name, theme in std.items():
            palette = merge_theme(theme["colors"], theme["semantic"])
            db[name] = {
                "family": "standard",
                "variant": theme["variant"],
                "palette": palette,
                "roles": resolve_roles(palette, PROT_ROLE_MAP),
            }

    # --- Doric ---
    doric_dir = SOURCES / "doric-themes"
    if doric_dir.is_dir():
        doric = parse_doric_themes(doric_dir)
        for name, theme in doric.items():
            palette = normalize_doric(merge_theme(theme["colors"], theme["semantic"]))
            db[name] = {
                "family": "doric",
                "variant": theme["variant"],
                "palette": palette,
                "roles": resolve_roles(palette, PROT_ROLE_MAP),
            }

    # --- Flexoki ---
    from parse_flexoki import FLEXOKI_ROLES
    flexoki = parse_flexoki()
    for name, theme in flexoki.items():
        palette = merge_theme(theme["colors"], theme["semantic"])
        entry = {
            "family": "flexoki",
            "variant": theme["variant"],
            "palette": palette,
            "roles": resolve_roles(palette, FLEXOKI_ROLES),
        }
        if "ghostty_theme" in theme:
            entry["ghostty_theme"] = theme["ghostty_theme"]
        db[name] = entry

    return db


def main():
    db = build_db()

    write_path = None
    if "--write" in sys.argv:
        idx = sys.argv.index("--write")
        if idx + 1 < len(sys.argv):
            write_path = Path(sys.argv[idx + 1])
        else:
            write_path = Path.home() / ".config/dotfiles/themes.json"

    if write_path:
        write_path.parent.mkdir(parents=True, exist_ok=True)
        with open(write_path, "w") as f:
            json.dump(db, f, indent=2)
            f.write("\n")
        print(f"Wrote {len(db)} themes to {write_path}")
    else:
        json.dump(db, sys.stdout, indent=2)
        print()


if __name__ == "__main__":
    main()
