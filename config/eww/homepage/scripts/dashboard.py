#!/usr/bin/env python3
import json, shutil, subprocess, sys
from pathlib import Path
ROOT = Path.home() / ".config" / "eww" / "dashboard"
def out(data): print(json.dumps(data))
def run(*cmd):
    try: return subprocess.run(cmd, capture_output=True, text=True, timeout=2).stdout.strip()
    except (OSError, subprocess.TimeoutExpired): return ""
def agenda():
    try: items = json.loads((ROOT / "agenda.json").read_text())
    except (OSError, ValueError, json.JSONDecodeError): items = []
    item = (items.get("events", []) if isinstance(items, dict) else items)
    item = item[0] if isinstance(item, list) and item else {}
    out({"title": str(item.get("title", "Nothing scheduled")), "detail": str(item.get("time", "Add ~/.config/eww/dashboard/agenda.json"))})
def network():
    wifi = run("nmcli", "-t", "-f", "ACTIVE,SSID", "dev", "wifi") if shutil.which("nmcli") else ""
    active = next((x for x in wifi.splitlines() if x.startswith("yes:")), "Offline")
    privacy = "Mullvad connected" if "Connected" in run("mullvad", "status") else "Mullvad disconnected"
    out({"connection": active.replace("yes:", "Wi-Fi ") or "Offline", "privacy": privacy})
def project():
    try: data = json.loads((ROOT / "config.json").read_text())
    except (OSError, ValueError, json.JSONDecodeError): data = {}
    path = Path(str(data.get("project_dir", ""))).expanduser()
    branch = run("git", "-C", str(path), "branch", "--show-current") if path.is_dir() else ""
    out({"name": str(data.get("project_name") or path.name or "Set a project"), "detail": branch or "Add project_dir to dashboard/config.json"})
{"agenda": agenda, "network": network, "project": project}.get(sys.argv[1] if len(sys.argv) == 2 else "", lambda: sys.exit(2))()
