#!/usr/bin/env python3
"""Parse standard-themes into a resolved palette database.

Reads all standard-*-theme.el files plus standard-themes.el (common mappings).
Each theme has a single defconst with hex colors and semantic mappings inline
inside a modus-themes-generate-palette call.

Usage:
    python parse_standard.py [path/to/standard-themes/]

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
    entries = []
    for m in ENTRY_RE.finditer(text):
        entries.append((m.group(1), m.group(2).strip('"')))
    return entries


def extract_block(source: str, defname: str) -> str:
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
    m = re.search(r"'(dark|light)", source)
    return m.group(1) if m else "dark"


def parse_standard_themes(repo_dir: Path) -> dict:
    # Load common mappings
    themes_el = repo_dir / "standard-themes.el"
    if not themes_el.exists():
        raise FileNotFoundError(f"Missing {themes_el}")
    common_block = extract_block(themes_el.read_text(), "standard-themes-common-palette-mappings")
    common_entries = parse_entries(common_block)

    db = {}

    for theme_file in sorted(repo_dir.glob("standard-*-theme.el")):
        source = theme_file.read_text()
        theme_name = theme_file.stem.removesuffix("-theme")
        variant = detect_variant(source)

        # Single defconst contains both hex colors and semantic mappings
        palette_block = extract_block(source, f"{theme_name}-palette")
        palette_entries = parse_entries(palette_block)

        # Merge: common → palette (palette wins)
        merged = dict(common_entries)
        merged.update(dict(palette_entries))

        colors = {}
        semantic_raw = {}

        for name, value in merged.items():
            if value.startswith("#"):
                colors[name] = value
            elif value == "unspecified":
                continue
            else:
                semantic_raw[name] = value

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
        repo_dir = Path.home() / ".local/share/dotfiles/theme-sources/standard-themes"

    if not repo_dir.is_dir():
        print(f"Error: {repo_dir} not found", file=sys.stderr)
        sys.exit(1)

    db = parse_standard_themes(repo_dir)
    json.dump(db, sys.stdout, indent=2)
    print()


if __name__ == "__main__":
    main()
