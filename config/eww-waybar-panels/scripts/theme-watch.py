#!/usr/bin/env python3
from __future__ import annotations

import subprocess
import sys
import time
from pathlib import Path


def modified_at(path: Path) -> int:
    try:
        return path.stat().st_mtime_ns
    except OSError:
        return 0


def main() -> int:
    if len(sys.argv) != 3:
        return 2
    config_dir, theme_css = Path(sys.argv[1]), Path(sys.argv[2])
    generator = config_dir / "scripts" / "generate-theme.py"
    generated = config_dir / "generated" / "theme.scss"
    previous = modified_at(theme_css)
    while True:
        time.sleep(2)
        current = modified_at(theme_css)
        if current == previous:
            continue
        previous = current
        result = subprocess.run([sys.executable, str(generator), str(theme_css), str(generated)], check=False)
        if result.returncode == 0:
            subprocess.run(["eww", "reload", "--config", str(config_dir)], check=False)


if __name__ == "__main__":
    raise SystemExit(main())
