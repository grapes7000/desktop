#!/usr/bin/env bash
set -u

action="${1:-}"
config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
bin_dir="$config_home/bin"
eww_bin="$(command -v eww 2>/dev/null || true)"

available() {
    case "$1" in
        launcher) command -v wofi >/dev/null 2>&1 || command -v rofi >/dev/null 2>&1 ;;
        terminal) command -v kitty >/dev/null 2>&1 ;;
        files) command -v thunar >/dev/null 2>&1 || command -v nautilus >/dev/null 2>&1 || command -v dolphin >/dev/null 2>&1 || command -v nemo >/dev/null 2>&1 || command -v pcmanfm >/dev/null 2>&1 ;;
        monitor) command -v eww >/dev/null 2>&1 && [ -x "$bin_dir/waybar-panel" ] ;;
        power) [ -x "$bin_dir/power-menu" ] || [ -x "$HOME/.local/bin/power-menu" ] ;;
        *) return 1 ;;
    esac
}

feedback() {
    [ -n "$eww_bin" ] || return 0
    "$eww_bin" update "dock-feedback=$1" --config "$config_home/eww" >/dev/null 2>&1 || true
}

if [ "$action" = "status" ]; then
    printf '{"launcher":%s,"terminal":%s,"files":%s,"monitor":%s,"power":%s}\n' \
        "$(available launcher && printf true || printf false)" \
        "$(available terminal && printf true || printf false)" \
        "$(available files && printf true || printf false)" \
        "$(available monitor && printf true || printf false)" \
        "$(available power && printf true || printf false)"
    exit 0
fi

if ! available "$action"; then feedback "${action^} unavailable"; exit 0; fi

case "$action" in
    launcher)
        feedback "Opening applications"
        if command -v wofi >/dev/null 2>&1; then
            if [ -x "$HOME/.local/bin/wofi-singleton" ]; then "$HOME/.local/bin/wofi-singleton" --show drun --style "$config_home/wofi/style.css" >/dev/null 2>&1 &
            else wofi --show drun >/dev/null 2>&1 & fi
        else rofi -show drun >/dev/null 2>&1 & fi
        ;;
    terminal) feedback "Opening Kitty"; kitty >/dev/null 2>&1 & ;;
    files) feedback "Opening files"; for manager in thunar nautilus dolphin nemo pcmanfm; do if command -v "$manager" >/dev/null 2>&1; then "$manager" >/dev/null 2>&1 & break; fi; done ;;
    monitor) feedback "Toggling system monitor"; "$bin_dir/waybar-panel" system toggle >/dev/null 2>&1 & ;;
    power) feedback "Opening power menu"; if [ -x "$bin_dir/power-menu" ]; then "$bin_dir/power-menu" >/dev/null 2>&1 & else "$HOME/.local/bin/power-menu" >/dev/null 2>&1 & fi ;;
esac

(sleep 1; feedback "Ready") &
