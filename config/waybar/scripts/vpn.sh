#!/bin/sh
# VPN/IP indicator for waybar. Shows icon normally, IP in tooltip on hover.
# Classes: mullvad, tailscale, exposed

mullvad_connected() {
    command -v mullvad >/dev/null 2>&1 && mullvad status 2>/dev/null | grep -qi "connected"
}

tailscale_connected() {
    ip -o -4 addr show tailscale0 2>/dev/null | grep -q .
}

get_public_ip() {
    ip -o -4 addr show 2>/dev/null | awk '!/ lo /{print $4}' | cut -d/ -f1 | head -1
}

if mullvad_connected; then
    ip=$(mullvad status 2>/dev/null | grep -oP '\d+\.\d+\.\d+\.\d+' | head -1)
    [ -z "$ip" ] && ip=$(get_public_ip)
    printf '{"text":"󰦝","class":"mullvad","tooltip":"Mullvad: %s"}\n' "$ip"
elif tailscale_connected; then
    ip=$(ip -o -4 addr show tailscale0 | awk '{print $4}' | cut -d/ -f1)
    printf '{"text":"󰛳","class":"tailscale","tooltip":"Tailscale: %s"}\n' "$ip"
else
    ip=$(get_public_ip)
    printf '{"text":"󰀦","class":"exposed","tooltip":"Exposed: %s"}\n' "$ip"
fi
