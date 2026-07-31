#!/usr/bin/env bash
set -euo pipefail

detect_platform() {
    local os_release="${OS_RELEASE_FILE:-/etc/os-release}"
    [ -r "$os_release" ] || { err "Cannot read $os_release"; return 1; }
    # shellcheck disable=SC1090
    . "$os_release"
    DISTRO_ID="${ID:-unknown}"
    DISTRO_NAME="${PRETTY_NAME:-$DISTRO_ID}"
    DISTRO_LIKE="${ID_LIKE:-}"

    case "$DISTRO_ID" in
        cachyos)
            DISTRO_FAMILY="cachyos"; PACKAGE_MANAGER="pacman" ;;
        arch)
            DISTRO_FAMILY="pacman"; PACKAGE_MANAGER="pacman" ;;
        ubuntu|linuxmint|pop|elementary|zorin|kubuntu|xubuntu|lubuntu)
            DISTRO_FAMILY="apt"; PACKAGE_MANAGER="apt" ;;
        *)
            if [[ " $DISTRO_LIKE " == *" arch "* ]]; then
                DISTRO_FAMILY="pacman"; PACKAGE_MANAGER="pacman"
            elif [[ " $DISTRO_LIKE " == *" ubuntu "* || " $DISTRO_LIKE " == *" debian "* ]]; then
                DISTRO_FAMILY="apt"; PACKAGE_MANAGER="apt"
            else
                err "Unsupported distribution: $DISTRO_NAME"
                err "Supported families: Ubuntu variants, Arch, CachyOS"
                return 1
            fi
            ;;
    esac
}

detect_desktop() {
    if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ] || has hyprctl; then
        DESKTOP_KIND="hyprland"
    elif [ -n "${KDE_FULL_SESSION:-}" ] || [[ "${XDG_CURRENT_DESKTOP:-}" == *KDE* ]] || has plasmashell; then
        DESKTOP_KIND="kde"
    elif [[ "${XDG_CURRENT_DESKTOP:-}" == *XFCE* ]] || has xfce4-session; then
        DESKTOP_KIND="xfce"
    elif [[ "${XDG_CURRENT_DESKTOP:-}" == *GNOME* ]] || [[ "${XDG_CURRENT_DESKTOP:-}" == *Cinnamon* ]] || has gnome-shell; then
        DESKTOP_KIND="gtk-desktop"
    else
        DESKTOP_KIND="unknown"
    fi
}

detect_machine_kind() {
    if compgen -G '/sys/class/power_supply/BAT*' >/dev/null; then
        MACHINE_KIND="laptop"
    elif systemd-detect-virt --quiet 2>/dev/null; then
        MACHINE_KIND="vm"
    else
        MACHINE_KIND="desktop-or-server"
    fi
}
