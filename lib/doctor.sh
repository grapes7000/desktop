#!/usr/bin/env bash
set -euo pipefail

doctor_check() {
    local label="$1" cmd="$2"
    if has "$cmd"; then ok "$label"; else warn "$label missing"; fi
}

run_doctor() {
    detect_platform
    detect_desktop
    detect_machine_kind
    section "System"
    echo "Distribution : $DISTRO_NAME"
    echo "Family       : $DISTRO_FAMILY"
    echo "Desktop      : $DESKTOP_KIND"
    echo "Machine      : $MACHINE_KIND"
    echo "State        : $STATE_DIR"

    section "Core"
    doctor_check "Git" git
    doctor_check "curl" curl
    doctor_check "Zsh" zsh
    doctor_check "Kitty" kitty
    doctor_check "Starship" starship
    doctor_check "Chezmoi" chezmoi
    doctor_check "Restic" restic

    section "Desktop integrations"
    doctor_check "Flatpak" flatpak
    doctor_check "Theme command" theme
    doctor_check "VSCodium" codium

    section "Repositories"
    [ -d "$HOME/.local/share/chezmoi/.git" ] && ok "Chezmoi source present" || warn "Chezmoi source not initialized"
    [ -d "$THEMES_DIR/.git" ] && ok "Themes repository present" || warn "Themes repository not cloned"

    section "Installed group markers"
    if compgen -G "$STATE_DIR/groups/*" >/dev/null; then
        for f in "$STATE_DIR"/groups/*; do printf '%-18s %s\n' "$(basename "$f")" "$(cat "$f")"; done
    else
        echo "No groups marked yet."
    fi
}
