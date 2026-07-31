#!/usr/bin/env python3
from __future__ import annotations

import re
import sys
from pathlib import Path

DEFAULTS = {
    "bg": "#1e1e2e", "bg_alt": "#181825", "text": "#d8dee9", "text_dim": "#a0a8b8",
    "accent": "#89b4fa", "accent2": "#cba6f7", "urgent": "#f38ba8", "warning": "#f9e2af",
    "success": "#a6e3a1", "surface_0": "#313244", "surface_1": "#45475a",
    "border_subtle": "#45475a", "border_strong": "#6c7086", "hover": "#313244", "selected": "#45475a",
}
COLOR = re.compile(r"@define-color\s+([A-Za-z0-9_-]+)\s+([^;\n]+);?")


def generate_scss(theme_css: Path) -> str:
    colors = dict(DEFAULTS)
    try:
        source = theme_css.read_text(encoding="utf-8")
    except OSError:
        source = ""
    for name, value in COLOR.findall(source):
        normalized = name.replace("-", "_")
        if normalized in colors:
            colors[normalized] = value.strip()
    return "// Generated from Waybar semantic theme.css; do not edit.\n" + "".join(
        f"${name.replace('_', '-')}: {value};\n" for name, value in colors.items()
    )


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: generate-theme.py THEME_CSS OUTPUT_SCSS", file=sys.stderr)
        return 2
    output = Path(sys.argv[2])
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(generate_scss(Path(sys.argv[1])), encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
