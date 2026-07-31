#!/bin/bash
# Window tracker with Nerd Font icons based on app class.
# Prints "<icon> <title>" for the active window; used by waybar custom module.

get_icon() {
    case "$1" in
        firefox)                         echo "" ;;
        chromium|google-chrome|brave)    echo "" ;;
        kitty|alacritty|wezterm|xterm)   echo "" ;;
        code|vscode|codium|jetbrains-*)  echo "" ;;
        nvim|vim|nano|gedit|mousepad)    echo "" ;;
        thunar|nautilus|dolphin|ranger|nemo|pcmanfm) echo "" ;;
        vlc|mpv)                         echo "" ;;
        feh|imv|eog|gwenview|krita|gimp) echo "" ;;
        discord|slack|telegram|element|signal) echo "" ;;
        zathura|okular|evince|libreoffice*) echo "" ;;
        spotify|deadbeef|ncmpcpp|rhythmbox) echo "" ;;
        pavucontrol|blueman*|nm-*)       echo "" ;;
        steam|lutris|gamescope|heroic)   echo "" ;;
        htop|btop|bpytop|bashtop)        echo "" ;;
        *)                               echo "" ;;
    esac
}

while true; do
    window_info=$(hyprctl activewindow -j 2>/dev/null)

    if [ -z "$window_info" ] || [ "$window_info" = "null" ]; then
        echo ""
        sleep 0.5
        continue
    fi

    class=$(echo "$window_info" | jq -r '.class // empty' 2>/dev/null)

    if [ -z "$class" ]; then
        echo ""
        sleep 0.5
        continue
    fi

    icon=$(get_icon "$class")

    if [ -n "$class" ]; then
        echo "$icon $class"
    else
        echo "$icon"
    fi

    sleep 0.5
done
