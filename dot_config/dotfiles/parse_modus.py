#!/usr/bin/env python3
"""Parse modus-themes.el into a resolved palette database.

Reads the single modus-themes.el file and extracts all 8 theme palettes
plus the common mappings. Resolves symbolic references so every entry
maps to either a hex color or 'unspecified'.

Usage:
    python parse_modus.py <path/to/modus-themes.el>
    python parse_modus.py  # defaults to ~/.local/share/dotfiles/theme-sources/modus-themes/modus-themes.el

Output: JSON to stdout
    {
      "modus-operandi": {
        "variant": "light",
        "colors": { "bg-main": "#ffffff", ... },
        "semantic": { "cursor": "#000000", "keyword": "#531ab6", ... }
      },
      ...
    }

"colors" contains only the named hex values (the raw palette).
"semantic" contains resolved mappings — every symbolic reference chased
to its final hex value. Entries that resolve to 'unspecified' are omitted.
"""

import json
import re
import sys
from pathlib import Path

# Where to find the palette defconst for each theme.
# Pattern: (defconst modus-themes-SHORTNAME-palette
# where SHORTNAME strips the leading "modus-" from the theme name.
THEMES = {
    "modus-operandi":                {"short": "operandi",                "variant": "light"},
    "modus-operandi-tinted":         {"short": "operandi-tinted",         "variant": "light"},
    "modus-operandi-deuteranopia":   {"short": "operandi-deuteranopia",   "variant": "light"},
    "modus-operandi-tritanopia":     {"short": "operandi-tritanopia",     "variant": "light"},
    "modus-vivendi":                 {"short": "vivendi",                 "variant": "dark"},
    "modus-vivendi-tinted":          {"short": "vivendi-tinted",          "variant": "dark"},
    "modus-vivendi-deuteranopia":    {"short": "vivendi-deuteranopia",    "variant": "dark"},
    "modus-vivendi-tritanopia":      {"short": "vivendi-tritanopia",      "variant": "dark"},
}

# Matches (name "#hex") or (name symbol) or (name unspecified) in an elisp alist.
ENTRY_RE = re.compile(
    r'\(\s*'
    r'([\w-]+)'
    r'\s+'
    r'("?#[0-9a-fA-F]{6}"?'
    r'|[\w-]+)'
    r'\s*\)'
)


def parse_entries(text: str) -> list[tuple[str, str]]:
    """Extract (name, value) pairs from an elisp alist region."""
    entries = []
    for m in ENTRY_RE.finditer(text):
        name = m.group(1)
        value = m.group(2).strip('"')
        entries.append((name, value))
    return entries


def extract_block(source: str, defname: str) -> str:
    """Extract the sexp body of a defconst/defvar by name."""
    pattern = re.compile(rf'\((?:defconst|defvar)\s+{re.escape(defname)}\b')
    m = pattern.search(source)
    if not m:
        raise ValueError(f"Could not find {defname} in source")

    start = m.start()
    depth = 0
    for i in range(start, len(source)):
        if source[i] == '(':
            depth += 1
        elif source[i] == ')':
            depth -= 1
            if depth == 0:
                return source[start:i + 1]

    raise ValueError(f"Unbalanced parens for {defname}")


def resolve(name: str, entries: dict[str, str], seen: set | None = None) -> str | None:
    """Chase symbolic references until we hit a hex value or 'unspecified'."""
    if seen is None:
        seen = set()

    if name in seen:
        return None
    seen.add(name)

    value = entries.get(name)
    if value is None:
        return None
    if value == "unspecified":
        return None
    if value.startswith("#"):
        return value
    return resolve(value, entries, seen)


def parse_modus(source: str) -> dict:
    """Parse modus-themes.el and return the full theme database."""

    common_block = extract_block(source, "modus-themes-common-palette-mappings")
    common_entries = parse_entries(common_block)

    db = {}

    for theme_name, info in THEMES.items():
        short = info["short"]
        variant = info["variant"]
        defname = f"modus-themes-{short}-palette"

        palette_block = extract_block(source, defname)
        palette_entries = parse_entries(palette_block)

        # Merge: palette entries override common mappings
        merged = dict(common_entries)
        merged.update(dict(palette_entries))

        # Separate hex colors from semantic references
        colors = {}
        semantic_raw = {}

        for name, value in merged.items():
            if value.startswith("#"):
                colors[name] = value
            elif value == "unspecified":
                continue
            else:
                semantic_raw[name] = value

        # Resolve all semantic references to final hex values
        semantic = {}
        for name in semantic_raw:
            resolved = resolve(name, merged)
            if resolved is not None:
                semantic[name] = resolved

        db[theme_name] = {
            "variant": variant,
            "colors": colors,
            "semantic": semantic,
        }

    return db


def main():
    if len(sys.argv) > 1:
        path = Path(sys.argv[1])
    else:
        path = Path.home() / ".local/share/dotfiles/theme-sources/modus-themes/modus-themes.el"

    if not path.exists():
        print(f"Error: {path} not found", file=sys.stderr)
        sys.exit(1)

    source = path.read_text()
    db = parse_modus(source)
    json.dump(db, sys.stdout, indent=2)
    print()


if __name__ == "__main__":
    main()
