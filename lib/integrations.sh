#!/usr/bin/env bash
set -euo pipefail

ensure_starship() {
    if has starship; then ok "Starship already installed (pacman or local)"; return; fi
    info "Starship not found; it should be installed via pacman (in essentials package list)."
    warn "If pacman starship is unavailable, install manually: curl -sS https://starship.rs/install.sh | sh -s -- -b ~/.local/bin -y"
}

ensure_chezmoi() {
    if has chezmoi; then ok "Chezmoi already installed"; return; fi
    info "Installing Chezmoi into ~/.local/bin"
    mkdir -p "$HOME/.local/bin"
    if [ "${DRY_RUN:-0}" -eq 1 ]; then
        echo "[dry-run] sh -c \"\$(curl -fsLS https://get.chezmoi.io)\" -- -b ~/.local/bin"
    else
        sh -c "$(curl -fsLS https://get.chezmoi.io)" -- -b "$HOME/.local/bin"
    fi
}

ensure_oh_my_zsh() {
    if [ -d /usr/share/oh-my-zsh ]; then
        ok "Oh My Zsh installed via pacman (oh-my-zsh-git)"
        return
    fi
    [ -d "$HOME/.oh-my-zsh" ] && { ok "Oh My Zsh already installed"; return; }
    info "Installing Oh My Zsh without changing files interactively"
    if [ "${DRY_RUN:-0}" -eq 1 ]; then
        echo "[dry-run] official Oh My Zsh unattended installer"
    else
        RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \
          "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
          "" --unattended
    fi
}

ensure_zsh_plugins() {
    if [ -d /usr/share/zsh/plugins/zsh-autosuggestions ]; then
        ok "Zsh plugins installed via pacman"
        return
    fi
    local custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    mkdir -p "$custom/plugins"
    clone_plugin() {
        local url="$1" dest="$2"
        [ -d "$dest/.git" ] && { ok "$(basename "$dest") already present"; return; }
        run git clone --depth=1 "$url" "$dest"
    }
    clone_plugin https://github.com/zsh-users/zsh-autosuggestions "$custom/plugins/zsh-autosuggestions"
    clone_plugin https://github.com/zsh-users/zsh-syntax-highlighting "$custom/plugins/zsh-syntax-highlighting"
    clone_plugin https://github.com/zsh-users/zsh-completions "$custom/plugins/zsh-completions"
    clone_plugin https://github.com/zsh-users/zsh-history-substring-search "$custom/plugins/zsh-history-substring-search"
}

setup_terminal_stack() {
    ensure_starship
    ensure_oh_my_zsh
    ensure_zsh_plugins
}

apply_dotfiles_repo() {
    [ "${APPLY_DOTFILES:-1}" -eq 1 ] || { warn "Dotfiles disabled."; return 0; }
    ensure_chezmoi
    export PATH="$HOME/.local/bin:$PATH"

    if [ -d "$HOME/.local/share/chezmoi/.git" ]; then
        info "Updating and applying existing Chezmoi source"
        run chezmoi update
        return
    fi

    info "Initializing Chezmoi from $DOTFILES_REPO"
    if ! run chezmoi init --apply "$DOTFILES_REPO"; then
        warn "Chezmoi could not clone the private dotfiles repository."
        warn "Authenticate GitHub, then run: chezmoi init --apply '$DOTFILES_REPO'"
    fi
}

clone_or_update_repo() {
    local url="$1" dir="$2"
    if [ -d "$dir/.git" ]; then
        info "Updating $(basename "$dir")"
        run git -C "$dir" pull --ff-only
    elif [ -e "$dir" ]; then
        warn "$dir exists but is not a Git repository; leaving it untouched."
        return 1
    else
        info "Cloning $url"
        run git clone "$url" "$dir"
    fi
}

install_theme_engine() {
    [ "${INSTALL_THEMES:-1}" -eq 1 ] || { warn "Themes disabled."; return 0; }
    clone_or_update_repo "$THEMES_REPO" "$THEMES_DIR" || return 0
    run bash "$THEMES_DIR/install.sh"
    export PATH="$HOME/.local/bin:$PATH"
    if has theme; then
        info "Applying initial theme: $DEFAULT_THEME"
        run theme "$DEFAULT_THEME" || warn "Theme '$DEFAULT_THEME' was not applied; run 'theme --list'."
    else
        warn "Theme command is not on PATH yet. Open a new shell or add ~/.local/bin."
    fi
}

configure_containers() {
    has docker || { warn "Docker command unavailable after installation."; return 0; }
    run sudo systemctl enable --now docker
    if ! id -nG "$USER" | tr ' ' '\n' | grep -qx docker; then
        run sudo usermod -aG docker "$USER"
        warn "Docker group added. Log out and back in before using Docker without sudo."
    fi
}

enable_services_for_group() {
    local target_group="$1"
    local services_conf="$ROOT/config/services.conf"
    [ -f "$services_conf" ] || return 0
    local scope unit group
    while IFS=' ' read -r scope unit group; do
        [[ "$scope" =~ ^#.*$ || -z "$scope" ]] && continue
        [ "$group" = "$target_group" ] || continue
        case "$scope" in
            system)
                if systemctl list-unit-files 2>/dev/null | grep -q "^$unit"; then
                    run sudo systemctl enable "$unit"
                fi
                ;;
            user)
                if systemctl --user list-unit-files 2>/dev/null | grep -q "^$unit"; then
                    run systemctl --user enable "$unit"
                fi
                ;;
        esac
    done < "$services_conf"
}

configure_virtualization() {
    if systemctl list-unit-files 2>/dev/null | grep -q '^libvirtd.service'; then
        run sudo systemctl enable --now libvirtd
    fi
    if getent group libvirt >/dev/null 2>&1 && ! id -nG "$USER" | tr ' ' '\n' | grep -qx libvirt; then
        run sudo usermod -aG libvirt "$USER"
        warn "libvirt group added. Log out and back in before using it."
    fi
}
