#!/bin/bash
set -u
export LC_ALL=C

HYPRCTL_BIN="${HYPRCTL_BIN:-hyprctl}"
THEME_DIR="${THEME_DIR:-$HOME/.config/hypr/themes}"
THEME_CSS="${THEME_CSS:-$HOME/.config/waybar/generated/theme.css}"
WORKSPACE_ID="${1:-}"

case "$WORKSPACE_ID" in
    [1-9]|10) ;;
    *) printf '%s\n' 'workspace ID must be an integer from 1 to 10' >&2; exit 2 ;;
esac

WS_JSON="${WS_JSON:-$HOME/.config/hypr/workspaces.json}"

workspace_label() {
    if [ -r "$WS_JSON" ]; then
        local name
        name=$(jq -r --argjson id "$1" '.[] | select(.id == $id) | .name // empty' "$WS_JSON" 2>/dev/null)
        [ -n "$name" ] && { printf '%s' "$name"; return; }
    fi
    case "$1" in
        1) printf 'web' ;; 2) printf 'term' ;; 3) printf 'code' ;;
        4) printf 'files' ;; 5) printf 'media' ;; 6) printf 'chat' ;;
        7) printf 'doc' ;; 8) printf 'sys' ;; 9) printf 'extra' ;;
        10) printf 'vm' ;; *) printf 'ws%s' "$1" ;;
    esac
}

app_category() {
    case "${1,,}" in
        firefox|chromium|google-chrome|brave) printf 'blue:web' ;;
        kitty|alacritty|wezterm|xterm) printf 'green:term' ;;
        code|vscode|codium|jetbrains-*) printf 'cyan:code' ;;
        thunar|nautilus|dolphin|ranger|nemo|pcmanfm) printf 'yellow:files' ;;
        vlc|mpv|feh|imv|eog|gwenview|krita|gimp) printf 'magenta:media' ;;
        discord|slack|telegram|element|signal) printf 'magenta:chat' ;;
        zathura|okular|evince|libreoffice*) printf 'yellow:doc' ;;
        pavucontrol|blueman*|nm-*) printf 'red:sys' ;;
        steam|lutris|gamescope|heroic) printf 'yellow:extra' ;;
        virt-manager|virtualbox|qemu-system-*) printf 'cyan:vm' ;;
        *) printf 'white:default' ;;
    esac
}

icon_for() {
    case "$1" in
        web) printf '\357\202\254' ;; term) printf '\357\204\240' ;;
        code) printf '\357\204\241' ;; files) printf '\357\201\273' ;;
        media) printf '\357\200\275' ;; chat) printf '\357\202\206' ;;
        doc) printf '\357\200\255' ;; sys) printf '\357\200\223' ;;
        extra) printf '\357\200\205' ;; vm) printf '\357\204\210' ;;
        *) printf '\357\213\220' ;;
    esac
}

theme_role() {
    local role="$1"
    local css_name="$role"
    [ -r "$THEME_CSS" ] || return 0
    awk -v name="$css_name" '$1 == "@define-color" && $2 == name { gsub(";", "", $3); print $3; exit }' "$THEME_CSS"
}

theme_file() {
    local accent bg candidate
    accent=$(theme_role accent); bg=$(theme_role bg)
    [ -n "$accent" ] && [ -n "$bg" ] || return 0
    for candidate in "$THEME_DIR"/*.json; do
        [ -r "$candidate" ] || continue
        if jq -e --arg accent "$accent" --arg bg "$bg" '.roles.accent == $accent and .roles.bg == $bg' "$candidate" >/dev/null 2>&1; then
            printf '%s' "$candidate"
            return 0
        fi
    done
}

color_for() {
    local role="$1" file="$2" fallback
    fallback=$(theme_role "ansi_$role")
    if [ -n "$file" ]; then
        jq -r --arg role "ansi_$role" --arg fallback "${fallback:-#d3c6aa}" '.roles[$role] // $fallback' "$file" 2>/dev/null
    else
        printf '%s' "${fallback:-#d3c6aa}"
    fi
}

render() {
    local clients active theme accent muted windows count dominant category role kind color icon label text tooltip state
    clients=$($HYPRCTL_BIN clients -j 2>/dev/null) || clients='[]'
    active=$($HYPRCTL_BIN activeworkspace -j 2>/dev/null | jq -r '.id // 1' 2>/dev/null) || active=1
    theme=$(theme_file)
    accent=$(theme_role accent); accent=${accent:-#7fbbb3}
    muted=$(theme_role text_dim); muted=${muted:-#a8a9a3}

    windows=$(jq -c --argjson id "$WORKSPACE_ID" '[.[] | select(.workspace.id == $id)]' <<<"$clients")
    count=$(jq 'length' <<<"$windows")
    label=$(workspace_label "$WORKSPACE_ID")
    state="workspace"

    if [ "$count" -eq 0 ]; then
        icon=$(icon_for "$label")
        color="$muted"
        state="$state empty role-$label"
        tooltip="Workspace $WORKSPACE_ID ($label): empty"
    else
        dominant=$(jq -r 'group_by(.class) | sort_by(length) | last | .[0].class // empty' <<<"$windows")
        category=$(app_category "$dominant")
        role=${category%%:*}; kind=${category#*:}
        icon=$(icon_for "$kind")
        color=$(color_for "$role" "$theme")
        state="$state occupied color-$role"
        tooltip="Workspace $WORKSPACE_ID ($label): $count window(s), $dominant"
    fi

    if [ "$WORKSPACE_ID" = "$active" ]; then
        text="<span foreground=\"$accent\"><b>$icon  $label</b></span>"
        state="$state active"
    else
        text="<span foreground=\"$color\">$icon</span>"
        state="$state inactive"
    fi

    jq -cn --arg text "$text" --arg tooltip "$tooltip" --arg class "$state" '{text: $text, tooltip: $tooltip, class: ($class | split(" "))}'
}

render
