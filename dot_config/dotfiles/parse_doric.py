#!/usr/bin/env python3
"""Parse doric-themes into a palette database.

Doric themes are the simplest family: flat defvar with ~24 hex colors,
no semantic mapping layer. Different naming convention from modus/ef/standard
(fg-red instead of red, bg-shadow-subtle instead of bg-dim, etc.).

Usage:
    python parse_doric.py [path/to/doric-themes/]

Output: JSON to stdout, same shape as other parsers but with empty semantic dict.
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


def detect_variant(source: str) -> str:
    """Extract variant from doric-themes-define-theme call."""
    m = re.search(r'doric-themes-define-theme\s+\S+\s+(dark|light)', source)
    return m.group(1) if m else "dark"


def parse_doric_themes(repo_dir: Path) -> dict:
    db = {}

    for theme_file in sorted(repo_dir.glob("doric-*-theme.el")):
        source = theme_file.read_text()
        theme_name = theme_file.stem.removesuffix("-theme")
        variant = detect_variant(source)

        palette_block = extract_block(source, f"{theme_name}-palette")
        entries = parse_entries(palette_block)

        # All doric entries are hex colors — no semantic references
        colors = {name: value for name, value in entries if value.startswith("#")}

        db[theme_name] = {
            "variant": variant,
            "colors": colors,
            "semantic": {},
        }

    return db


def main():
    if len(sys.argv) > 1:
        repo_dir = Path(sys.argv[1])
    else:
        repo_dir = Path.home() / ".local/share/dotfiles/theme-sources/doric-themes"

    if not repo_dir.is_dir():
        print(f"Error: {repo_dir} not found", file=sys.stderr)
        sys.exit(1)

    db = parse_doric_themes(repo_dir)
    json.dump(db, sys.stdout, indent=2)
    print()


if __name__ == "__main__":
    main()
