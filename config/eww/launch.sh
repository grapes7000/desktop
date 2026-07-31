#!/usr/bin/env bash
set -u

CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/eww"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hyprland-setup"
LOG="$STATE_DIR/homepage.log"
mkdir -p "$STATE_DIR"
export PATH="$HOME/.local/bin:$PATH"
EWW_BIN="$(command -v eww 2>/dev/null || true)"

if [ -z "$EWW_BIN" ]; then
    printf '%s homepage: eww command not found\n' "$(date -Is)" >> "$LOG"
    exit 127
fi
if [ ! -s "$CONFIG/eww.yuck" ] || [ ! -s "$CONFIG/eww.scss" ]; then
    printf '%s homepage: config is incomplete in %s\n' "$(date -Is)" "$CONFIG" >> "$LOG"
    exit 1
fi

printf '%s homepage: starting\n' "$(date -Is)" >> "$LOG"
"$EWW_BIN" daemon --force-wayland --config "$CONFIG" >> "$LOG" 2>&1 || true
for _ in $(seq 1 30); do
    if "$EWW_BIN" ping --config "$CONFIG" >/dev/null 2>&1; then
        exec "$EWW_BIN" open homepage --force-wayland --config "$CONFIG" >> "$LOG" 2>&1
    fi
    sleep 0.1
done
printf '%s homepage: daemon did not become ready\n' "$(date -Is)" >> "$LOG"
exit 1
