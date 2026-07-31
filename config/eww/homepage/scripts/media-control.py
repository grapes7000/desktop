#!/usr/bin/env python3
import shutil, subprocess, sys

actions = {"previous", "play-pause", "next"}
action = sys.argv[1] if len(sys.argv) == 2 else ""
if action not in actions or not shutil.which("playerctl"):
    raise SystemExit(2)
try:
    result = subprocess.run(["playerctl", action], check=False, timeout=3)
except (OSError, subprocess.TimeoutExpired):
    raise SystemExit(1)
raise SystemExit(result.returncode)
