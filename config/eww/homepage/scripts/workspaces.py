#!/usr/bin/env python3
import json, shutil, subprocess
fallback = {"active": 1, "workspaces": [1, 2, 3, 4, 5]}
if not shutil.which("hyprctl"):
    print(json.dumps(fallback)); raise SystemExit
try:
    workspaces = json.loads(subprocess.run(["hyprctl", "workspaces", "-j"], check=True, capture_output=True, text=True, timeout=2).stdout)
    active = json.loads(subprocess.run(["hyprctl", "activeworkspace", "-j"], check=True, capture_output=True, text=True, timeout=2).stdout)
    ids = sorted({item["id"] for item in workspaces if isinstance(item.get("id"), int) and item["id"] > 0})
    print(json.dumps({"active": active.get("id", ids[0] if ids else 1), "workspaces": ids or fallback["workspaces"]}))
except (OSError, subprocess.SubprocessError, json.JSONDecodeError, KeyError, TypeError):
    print(json.dumps(fallback))
