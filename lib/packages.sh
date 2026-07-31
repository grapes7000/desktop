#!/usr/bin/env bash
set -euo pipefail

APT_UPDATED=0

prepare_package_manager() {
    case "$PACKAGE_MANAGER" in
        apt)
            if [ "$APT_UPDATED" -eq 0 ]; then
                run sudo apt-get update
                APT_UPDATED=1
            fi
            ;;
        pacman)
            :
            ;;
    esac
}

install_package_array() {
    local -a packages=("$@")
    [ "${#packages[@]}" -eq 0 ] && return 0
    prepare_package_manager

    if [ "${DRY_RUN:-0}" -eq 1 ]; then
        case "$PACKAGE_MANAGER" in
            apt) run sudo apt-get install -y "${packages[@]}" ;;
            pacman) run sudo pacman -S --needed --noconfirm "${packages[@]}" ;;
        esac
        return 0
    fi

    info "Installing ${#packages[@]} native package(s) via $PACKAGE_MANAGER"
    case "$PACKAGE_MANAGER" in
        apt)
            if sudo apt-get install -y "${packages[@]}"; then return 0; fi
            ;;
        pacman)
            if sudo pacman -S --needed --noconfirm "${packages[@]}"; then return 0; fi
            ;;
    esac

    warn "Batch install had unavailable packages; retrying individually."
    local pkg
    for pkg in "${packages[@]}"; do
        case "$PACKAGE_MANAGER" in
            apt) sudo apt-get install -y "$pkg" || warn "Unavailable or failed: $pkg" ;;
            pacman) sudo pacman -S --needed --noconfirm "$pkg" || warn "Unavailable or failed: $pkg" ;;
        esac
    done
}

install_native_group() {
    local group="$1"
    local family="$DISTRO_FAMILY"
    [ "$family" = "cachyos" ] && family="pacman"
    local file="$ROOT/packages/$family/$group.txt"
    local -a packages=()
    mapfile -t packages < <(read_list "$file")
    install_package_array "${packages[@]}"

    if [ "$DISTRO_FAMILY" = "cachyos" ]; then
        local additions="$ROOT/packages/cachyos/$group.txt"
        local -a extra=()
        mapfile -t extra < <(read_list "$additions")
        install_package_array "${extra[@]}"
    fi

    install_aur_group "$group"
}

install_aur_group() {
    local group="$1"
    local file="$ROOT/packages/aur/$group.txt"
    [ -f "$file" ] || return 0
    local -a packages=()
    mapfile -t packages < <(read_list "$file")
    [ "${#packages[@]}" -eq 0 ] && return 0

    if ! has yay && ! has paru; then
        warn "No AUR helper (yay/paru) found; skipping AUR packages for $group."
        return 0
    fi
    local aur_helper
    aur_helper="$(has yay && echo yay || echo paru)"

    info "Installing ${#packages[@]} AUR package(s) via $aur_helper"
    if [ "${DRY_RUN:-0}" -eq 1 ]; then
        run "$aur_helper" -S --needed --noconfirm "${packages[@]}"
        return 0
    fi

    local pkg
    for pkg in "${packages[@]}"; do
        "$aur_helper" -S --needed --noconfirm "$pkg" || warn "AUR: failed to install $pkg"
    done

ensure_flathub() {
    has flatpak || { warn "Flatpak is not installed; skipping Flatpak applications."; return 1; }
    if ! flatpak remotes --columns=name 2>/dev/null | grep -qx flathub; then
        run flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    fi
}

install_flatpak_group() {
    local group="$1"
    [ "${INSTALL_FLATPAKS:-1}" -eq 1 ] || { warn "Flatpaks disabled."; return 0; }
    local file="$ROOT/packages/flatpak/$group.txt"
    [ -f "$file" ] || return 0
    ensure_flathub || return 0
    local app
    while IFS= read -r app; do
        [ -n "$app" ] || continue
        run flatpak install -y --noninteractive flathub "$app"
    done < <(read_list "$file")
}
