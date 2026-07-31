#!/usr/bin/env bash
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
component="$repo/waybar/generated/component.css"
config="$repo/waybar/config.jsonc"

# The fallback is shipped as the first-run component CSS and must be valid GTK CSS.
if rg -n -i '(^|[;{[:space:]])spacing[[:space:]]*:' "$component"; then
    echo "invalid GTK CSS declaration found in $component" >&2
    exit 1
fi

# Inter-module spacing belongs to Waybar's JSON configuration, not CSS.
rg -n '"spacing"[[:space:]]*:[[:space:]]*[0-9]+' "$config" >/dev/null

panel_config="$repo/eww/waybar-panels/eww.yuck"
if rg -F '$EWW_CONFIG_DIR' "$panel_config" >/dev/null; then
    echo "Eww panel commands must not depend on EWW_CONFIG_DIR" >&2
    exit 1
fi
rg -F '$HOME/.config/eww-waybar-panels' "$panel_config" >/dev/null
rg -F '$HOME/.config/bin/waybar-panel' "$panel_config" >/dev/null
rg -F '(defwidget app-icon [icon glyph]' "$panel_config" >/dev/null

echo "Waybar CSS/config spacing checks passed"
