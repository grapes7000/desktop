#!/bin/bash
# Switch workspace on click, then broadcast an immediate refresh to all
# workspace tabs (instead of waiting up to 1s for the next poll).
# Caps in-flight refresh broadcasts at 5 so spam-clicking can't pile up
# hyprctl/jq calls across all 10 modules.
set -u
WORKSPACE_ID="${1:?workspace id required}"
SEM_DIR="/tmp/waybar-ws-refresh.sem"
mkdir -p "$SEM_DIR"

hyprctl dispatch workspace "$WORKSPACE_ID" >/dev/null 2>&1

lock="$SEM_DIR/lock"
exec 9>"$lock"
flock 9
in_flight=$(find "$SEM_DIR" -maxdepth 1 -name 'tok-*' 2>/dev/null | wc -l)
if [ "$in_flight" -ge 5 ]; then
    flock -u 9
    exit 0
fi
tok="$SEM_DIR/tok-$$-$RANDOM"
: > "$tok"
flock -u 9

pkill -RTMIN+8 waybar 2>/dev/null

(sleep 1; rm -f "$tok") &disown
