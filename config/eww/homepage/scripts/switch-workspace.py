#!/usr/bin/env python3
import re, shutil, subprocess, sys
value = sys.argv[1] if len(sys.argv) == 2 else ""
if not re.fullmatch(r"[1-9][0-9]*", value) or not shutil.which("hyprctl"):
    raise SystemExit(2)
raise SystemExit(subprocess.run(["hyprctl", "dispatch", "workspace", value], check=False).returncode)
