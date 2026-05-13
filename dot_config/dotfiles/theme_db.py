#!/usr/bin/env python3
"""Build the unified theme database from all four Prot theme families.

Runs all four parsers, merges colors+semantic into a single flat lookup
per theme, and normalizes doric naming into the modus/ef/standard vocabulary.

Usage:
    python theme_db.py [--write]       # print to stdout, or write to themes.json
    python theme_db.py --write PATH    # write to specific file

Output per theme:
    {
      "ef-autumn": {
        "family": "ef",
        "variant": "dark",
        "palette": { "bg-main": "#0f0e06", "cursor": "#ffaa33", "red": "#ef656a", ... }
      },
      ...
    }

The "palette" dict is a flat merge of colors + resolved semantic. Every value
is a hex color string. Generators look up keys directly — no fallback chains.
Keys that a theme doesn't define are simply absent.

Doric themes have their names normalized into the modus vocabulary where
there's a clear 1:1 correspondence. Keys without a natural mapping keep
their doric names (prefixed with fg-/bg-) so generators can still use them.
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


def build_db() -> dict:
    """Build the complete theme database from all four families."""
    db = {}

    # --- Modus ---
    modus_el = SOURCES / "modus-themes/modus-themes.el"
    if modus_el.exists():
        modus = parse_modus(modus_el.read_text())
        for name, theme in modus.items():
            db[name] = {
                "family": "modus",
                "variant": theme["variant"],
                "palette": merge_theme(theme["colors"], theme["semantic"]),
            }

    # --- Ef ---
    ef_dir = SOURCES / "ef-themes"
    if ef_dir.is_dir():
        ef = parse_ef_themes(ef_dir)
        for name, theme in ef.items():
            db[name] = {
                "family": "ef",
                "variant": theme["variant"],
                "palette": merge_theme(theme["colors"], theme["semantic"]),
            }

    # --- Standard ---
    std_dir = SOURCES / "standard-themes"
    if std_dir.is_dir():
        std = parse_standard_themes(std_dir)
        for name, theme in std.items():
            db[name] = {
                "family": "standard",
                "variant": theme["variant"],
                "palette": merge_theme(theme["colors"], theme["semantic"]),
            }

    # --- Doric ---
    doric_dir = SOURCES / "doric-themes"
    if doric_dir.is_dir():
        doric = parse_doric_themes(doric_dir)
        for name, theme in doric.items():
            palette = merge_theme(theme["colors"], theme["semantic"])
            db[name] = {
                "family": "doric",
                "variant": theme["variant"],
                "palette": normalize_doric(palette),
            }

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
