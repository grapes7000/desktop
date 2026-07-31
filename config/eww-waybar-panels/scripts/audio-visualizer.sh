#!/bin/sh
# Pipes cava output as JSON arrays for eww deflisten.
# Falls back to flat zeros if cava is not installed.
CONF="$(dirname "$0")/cava.conf"
BARS=14

if ! command -v cava >/dev/null 2>&1; then
    while true; do
        printf '[%s]\n' "$(printf '0,%.0s' $(seq 1 $BARS) | sed 's/,$//')"
        sleep 1
    done
    exit
fi

cava -p "$CONF" 2>/dev/null | while IFS=';' read -r line; do
    vals=$(printf '%s' "$line" | tr ';' ',' | sed 's/,$//')
    printf '[%s]\n' "$vals"
done
