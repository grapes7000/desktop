#!/bin/bash
# Show icons of currently running applications (deduped), max 8 then an ellipsis.

get_app_icon() {
    case "$1" in
        firefox)                       echo "" ;;
        chromium|google-chrome|brave)  echo "" ;;
        kitty|alacritty|wezterm)       echo "" ;;
        code|vscode|codium)            echo "" ;;
        thunar|nautilus|dolphin|nemo)  echo "" ;;
        vlc|mpv|feh|imv)               echo "" ;;
        discord|slack|telegram)        echo "" ;;
        spotify|deadbeef)              echo "" ;;
        steam|lutris|heroic)           echo "" ;;
        *)                             echo "" ;;
    esac
}

apps=$(hyprctl clients -j 2>/dev/null | jq -r '.[].class' | sort -u)

if [ -z "$apps" ]; then
    echo ""
    exit 0
fi

icons=""
count=0
for app in $apps; do
    case "$app" in
        waybar|Hyprland|xdg-desktop*) continue ;;
    esac
    icon=$(get_app_icon "$app")
    icons="$icons $icon"
    count=$((count + 1))
    if [ "$count" -ge 8 ]; then
        icons="$icons …"
        break
    fi
done

echo "${icons# }"
