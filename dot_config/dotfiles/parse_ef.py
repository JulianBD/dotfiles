#!/usr/bin/env python3
"""Parse ef-themes into a resolved palette database.

Reads all ef-*-theme.el files plus ef-themes.el (common mappings).
Resolves symbolic references so every semantic entry maps to a final hex color.

Usage:
    python parse_ef.py [path/to/ef-themes/]

Output: JSON to stdout, same format as parse_modus.py
"""

import json
import re
import sys
from pathlib import Path

ENTRY_RE = re.compile(
    r'\(\s*([\w-]+)\s+("?#[0-9a-fA-F]{6}"?|[\w-]+)\s*\)'
)


def parse_entries(text: str) -> list[tuple[str, str]]:
    """Extract (name, value) pairs from an elisp alist region."""
    entries = []
    for m in ENTRY_RE.finditer(text):
        entries.append((m.group(1), m.group(2).strip('"')))
    return entries


def extract_block(source: str, defname: str) -> str:
    """Extract the sexp body of a defconst/defvar by name."""
    pattern = re.compile(rf'\((?:defconst|defvar)\s+{re.escape(defname)}\b')
    m = pattern.search(source)
    if not m:
        raise ValueError(f"Could not find {defname}")

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


def detect_variant(source: str) -> str:
    """Extract variant from the modus-themes-theme call."""
    m = re.search(r"'(dark|light)", source)
    return m.group(1) if m else "dark"


def parse_ef_themes(repo_dir: Path) -> dict:
    """Parse all ef-themes and return the full database."""

    # Load common mappings from ef-themes.el
    ef_themes_el = repo_dir / "ef-themes.el"
    if not ef_themes_el.exists():
        raise FileNotFoundError(f"Missing {ef_themes_el}")
    ef_source = ef_themes_el.read_text()
    common_block = extract_block(ef_source, "ef-themes-palette-common")
    common_entries = parse_entries(common_block)

    db = {}

    for theme_file in sorted(repo_dir.glob("ef-*-theme.el")):
        source = theme_file.read_text()
        theme_name = theme_file.stem.removesuffix("-theme")  # ef-autumn-theme -> ef-autumn
        variant = detect_variant(source)

        # Extract the two per-theme blocks
        colors_block = extract_block(source, f"{theme_name}-palette-partial")
        color_entries = parse_entries(colors_block)

        mappings_block = extract_block(source, f"{theme_name}-palette-mappings-partial")
        mapping_entries = parse_entries(mappings_block)

        # Merge order: common → per-theme mappings → per-theme colors
        # Later entries override earlier ones
        merged = dict(common_entries)
        merged.update(dict(mapping_entries))
        merged.update(dict(color_entries))

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

        # Resolve all semantic references
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
        repo_dir = Path(sys.argv[1])
    else:
        repo_dir = Path.home() / ".local/share/dotfiles/theme-sources/ef-themes"

    if not repo_dir.is_dir():
        print(f"Error: {repo_dir} not found", file=sys.stderr)
        sys.exit(1)

    db = parse_ef_themes(repo_dir)
    json.dump(db, sys.stdout, indent=2)
    print()


if __name__ == "__main__":
    main()
