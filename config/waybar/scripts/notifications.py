#!/usr/bin/env python3
"""Waybar notification indicator using dunstctl.

Outputs JSON: {"text": "icon count", "tooltip": "...", "class": ["state"]}
"""
import json
import subprocess
import sys


def dunstctl(*args):
    try:
        return subprocess.check_output(
            ["dunstctl"] + list(args), text=True, timeout=2
        ).strip()
    except (OSError, subprocess.CalledProcessError, subprocess.TimeoutExpired):
        return None


def main():
    paused = dunstctl("is-paused")
    if paused is None:
        json.dump({"text": "", "tooltip": "dunst not available", "class": ["clear"]},
                  sys.stdout)
        sys.stdout.write("\n")
        return

    is_paused = paused == "true"
    count_str = dunstctl("count", "history")
    waiting_str = dunstctl("count", "waiting")

    try:
        history_count = int(count_str) if count_str else 0
    except ValueError:
        history_count = 0
    try:
        waiting_count = int(waiting_str) if waiting_str else 0
    except ValueError:
        waiting_count = 0

    if is_paused:
        icon = ""
        state = "paused"
        tip = "Notifications paused"
    elif waiting_count > 0 or history_count > 0:
        icon = ""
        state = "waiting"
        total = waiting_count + history_count
        tip = f"{total} notification{'s' if total != 1 else ''} in history"
    else:
        icon = ""
        state = "clear"
        tip = "No notifications"

    text = icon
    if (waiting_count + history_count) > 0 and not is_paused:
        text = f"{icon} {waiting_count + history_count}"

    output = {"text": text, "tooltip": tip, "class": [state]}
    json.dump(output, sys.stdout)
    sys.stdout.write("\n")


if __name__ == "__main__":
    main()
