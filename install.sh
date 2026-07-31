#!/usr/bin/env bash
set -euo pipefail

# ── Bootstrap: if piped from curl, clone to a permanent location ───────
_src="${BASH_SOURCE[0]-}"
if [ -z "$_src" ] || [ ! -f "$_src" ]; then
    _dest="${DESKTOP_SETUP_DIR:-$HOME/Projects/setup/desktop}"
    if [ -d "$_dest/.git" ]; then
        printf 'Updating existing clone at %s...\n' "$_dest"
        git -C "$_dest" pull --ff-only
    else
        printf 'Cloning desktop setup to %s...\n' "$_dest"
        mkdir -p "$(dirname "$_dest")"
        git clone https://github.com/grapes7000/desktop.git "$_dest"
    fi
    bash "$_dest/install.sh" "$@"
    exit $?
fi

REPO="$(cd "$(dirname "$_src")" && pwd)"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
STATE_ROOT="${XDG_STATE_HOME:-$HOME/.local/state}/desktop-setup"

# ── Defaults ───────────────────────────────────────────────────────────
DRY_RUN=false
ASSUME_YES=false
SKIP_PACKAGES=false
SKIP_FLATPAKS=false
SKIP_THEMES=false
DEFAULT_THEME="catppuccin_mocha"

# ── Colors ─────────────────────────────────────────────────────────────
c_reset=$'\e[0m'; c_blue=$'\e[1;34m'; c_green=$'\e[1;32m'
c_yellow=$'\e[1;33m'; c_red=$'\e[1;31m'; c_dim=$'\e[2m'
info()    { printf '%s==>%s %s\n' "$c_blue" "$c_reset" "$*"; }
ok()      { printf '%s  ✓%s %s\n' "$c_green" "$c_reset" "$*"; }
warn()    { printf '%s  !%s %s\n' "$c_yellow" "$c_reset" "$*"; }
err()     { printf '%s  ✗%s %s\n' "$c_red" "$c_reset" "$*" >&2; }
die()     { err "$@"; exit 1; }
has()     { command -v "$1" >/dev/null 2>&1; }

run() {
    if "$DRY_RUN"; then
        printf '%s[dry-run]%s ' "$c_dim" "$c_reset"
        printf '%q ' "$@"; printf '\n'
        return 0
    fi
    "$@"
}

# ── State tracking ─────────────────────────────────────────────────────
STATE_DIR=""
ensure_state_dir() {
    [ -n "$STATE_DIR" ] && return
    STATE_DIR="$STATE_ROOT/install-$(date +%Y%m%d-%H%M%S)-$$"
    if "$DRY_RUN"; then
        printf '  would create state dir %s\n' "$STATE_DIR"
    else
        mkdir -p "$STATE_DIR/backups"
        printf '# action\ttarget\tdetail\n' > "$STATE_DIR/manifest.tsv"
    fi
}
record() {
    "$DRY_RUN" && return 0
    printf '%s\t%s\t%s\n' "$1" "$2" "$3" >> "$STATE_DIR/manifest.tsv"
}

# ── File operations ────────────────────────────────────────────────────
target_exists() { [ -e "$1" ] || [ -L "$1" ]; }

same_link() {
    [ -L "$2" ] && [ "$(readlink -f "$2")" = "$(readlink -f "$1")" ]
}

archive() {
    local target="$1" backup
    target_exists "$target" || return 0
    ensure_state_dir
    backup="$STATE_DIR/backups/${target#"$HOME"/}"
    if "$DRY_RUN"; then
        printf '  would archive %s -> %s\n' "$target" "$backup"
        return
    fi
    mkdir -p "$(dirname "$backup")"
    mv "$target" "$backup"
    record archive "$target" "$backup"
    printf '  archived %s\n' "$target"
}

link() {
    local source="$1" destination="$2"
    if same_link "$source" "$destination"; then
        printf '  unchanged %s\n' "$destination"
        return
    fi
    archive "$destination"
    if "$DRY_RUN"; then
        printf '  would link %s -> %s\n' "$destination" "$source"
    else
        mkdir -p "$(dirname "$destination")"
        ln -s "$source" "$destination"
        record link "$destination" "$source"
        printf '  linked %s\n' "$destination"
    fi
}

link_file() {
    local source="$1" destination="$2"
    if same_link "$source" "$destination"; then
        printf '  unchanged %s\n' "$destination"
        return
    fi
    archive "$destination"
    if "$DRY_RUN"; then
        printf '  would link %s -> %s\n' "$destination" "$source"
    else
        mkdir -p "$(dirname "$destination")"
        ln -sf "$source" "$destination"
        record link "$destination" "$source"
        printf '  linked %s\n' "$destination"
    fi
}

seed_file() {
    local source="$1" destination="$2"
    if target_exists "$destination"; then
        printf '  existing %s\n' "$destination"
        return
    fi
    ensure_state_dir
    if "$DRY_RUN"; then
        printf '  would seed %s\n' "$destination"
    else
        mkdir -p "$(dirname "$destination")"
        install -m 0644 "$source" "$destination"
        record seed "$destination" "$source"
        printf '  seeded %s\n' "$destination"
    fi
}

# ── Distro detection ──────────────────────────────────────────────────
DISTRO="" DISTRO_FAMILY="" PKG_MGR=""

detect_distro() {
    local id id_like
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        id="${ID:-}"; id_like="${ID_LIKE:-}"
    else
        die "cannot detect distribution (/etc/os-release not found)"
    fi
    case "$id" in
        cachyos)
            DISTRO="$id"; DISTRO_FAMILY=cachyos; PKG_MGR=pacman ;;
        arch|endeavouros|manjaro|garuda|artix)
            DISTRO="$id"; DISTRO_FAMILY=pacman; PKG_MGR=pacman ;;
        fedora|nobara)
            DISTRO="$id"; DISTRO_FAMILY=dnf; PKG_MGR=dnf ;;
        debian|ubuntu|linuxmint|pop|zorin|elementary|kubuntu|xubuntu|lubuntu|kali)
            DISTRO="$id"; DISTRO_FAMILY=apt; PKG_MGR=apt ;;
        *)
            case "$id_like" in
                *arch*)   DISTRO="$id"; DISTRO_FAMILY=pacman; PKG_MGR=pacman ;;
                *fedora*) DISTRO="$id"; DISTRO_FAMILY=dnf;    PKG_MGR=dnf ;;
                *debian*|*ubuntu*) DISTRO="$id"; DISTRO_FAMILY=apt; PKG_MGR=apt ;;
                *) die "unsupported distro: $id (ID_LIKE=$id_like)" ;;
            esac ;;
    esac
}

# ── Desktop detection ─────────────────────────────────────────────────
DESKTOP=""

detect_desktop() {
    if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ] || has hyprctl || has Hyprland; then
        DESKTOP=hyprland
    elif [ -n "${KDE_FULL_SESSION:-}" ] || [[ "${XDG_CURRENT_DESKTOP:-}" == *KDE* ]] || has plasmashell; then
        DESKTOP=kde
    elif [[ "${XDG_CURRENT_DESKTOP:-}" == *XFCE* ]] || has xfce4-session; then
        DESKTOP=xfce
    elif [[ "${XDG_CURRENT_DESKTOP:-}" == *GNOME* ]] || [[ "${XDG_CURRENT_DESKTOP:-}" == *Cinnamon* ]]; then
        DESKTOP=gtk-desktop
    else
        DESKTOP=unknown
    fi
}

detect_machine() {
    if compgen -G '/sys/class/power_supply/BAT*' >/dev/null; then
        MACHINE=laptop
    elif systemd-detect-virt --quiet 2>/dev/null; then
        MACHINE=vm
    else
        MACHINE=desktop
    fi
}

# ── Package installation ──────────────────────────────────────────────
APT_UPDATED=0

read_list() {
    local file="$1"
    [ -f "$file" ] || return 0
    sed -e 's/[[:space:]]*#.*$//' -e '/^[[:space:]]*$/d' "$file"
}

pkg_install() {
    local -a packages=("$@")
    [ "${#packages[@]}" -eq 0 ] && return 0
    case "$PKG_MGR" in
        pacman) run sudo pacman -S --needed --noconfirm "${packages[@]}" ;;
        apt)
            if [ "$APT_UPDATED" -eq 0 ]; then
                run sudo apt-get update
                APT_UPDATED=1
            fi
            run sudo apt-get install -y "${packages[@]}" ;;
        dnf) run sudo dnf install -y "${packages[@]}" ;;
    esac
}

install_native_group() {
    local group="$1"
    local family="$DISTRO_FAMILY"
    [ "$family" = "cachyos" ] && family="pacman"
    local file="$REPO/packages/$family/$group.txt"
    local -a packages=()
    mapfile -t packages < <(read_list "$file")
    [ "${#packages[@]}" -eq 0 ] && return 0
    info "Installing $group packages via $PKG_MGR"
    pkg_install "${packages[@]}" || {
        warn "Batch install had failures; retrying individually"
        local pkg
        for pkg in "${packages[@]}"; do
            pkg_install "$pkg" || warn "failed: $pkg"
        done
    }

    if [ "$DISTRO_FAMILY" = "cachyos" ]; then
        local extra_file="$REPO/packages/cachyos/$group.txt"
        local -a extras=()
        mapfile -t extras < <(read_list "$extra_file")
        [ "${#extras[@]}" -gt 0 ] && pkg_install "${extras[@]}" || true
    fi

    local aur_file="$REPO/packages/aur/$group.txt"
    if [ -f "$aur_file" ]; then
        local -a aur_pkgs=()
        mapfile -t aur_pkgs < <(read_list "$aur_file")
        if [ "${#aur_pkgs[@]}" -gt 0 ]; then
            if has yay || has paru; then
                local aur_helper
                aur_helper="$(has yay && echo yay || echo paru)"
                info "Installing ${#aur_pkgs[@]} AUR package(s) via $aur_helper"
                local pkg
                for pkg in "${aur_pkgs[@]}"; do
                    run "$aur_helper" -S --needed --noconfirm "$pkg" || warn "AUR: failed $pkg"
                done
            else
                warn "No AUR helper found; skipping: ${aur_pkgs[*]}"
            fi
        fi
    fi
}

install_flatpak_group() {
    "$SKIP_FLATPAKS" && return 0
    local group="$1"
    local file="$REPO/packages/flatpak/$group.txt"
    [ -f "$file" ] || return 0
    has flatpak || { warn "flatpak not installed; skipping"; return 0; }
    if ! flatpak remotes --columns=name 2>/dev/null | grep -qx flathub; then
        run flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    fi
    local app
    while IFS= read -r app; do
        [ -n "$app" ] || continue
        run flatpak install -y --noninteractive flathub "$app" || true
    done < <(read_list "$file")
}

install_packages_for_groups() {
    "$SKIP_PACKAGES" && { warn "Package installation skipped"; return 0; }
    local -a groups=("$@")
    for group in "${groups[@]}"; do
        install_native_group "$group"
        install_flatpak_group "$group"
    done
}

# ── Manual tool installs ──────────────────────────────────────────────

install_oh_my_zsh() {
    [ -d /usr/share/oh-my-zsh ] && { ok "Oh My Zsh (pacman)"; return; }
    [ -d "$HOME/.oh-my-zsh" ] && { ok "Oh My Zsh already installed"; return; }
    info "Installing Oh My Zsh"
    if "$DRY_RUN"; then
        printf '  would install Oh My Zsh\n'; return
    fi
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \
        "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
        "" --unattended || warn "Oh My Zsh install failed"
}

install_zsh_plugins() {
    if [ -d /usr/share/zsh/plugins/zsh-autosuggestions ]; then
        ok "Zsh plugins (pacman)"; return
    fi
    local custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    mkdir -p "$custom/plugins"
    _clone_zsh_plugin() {
        local url="$1" dest="$2"
        [ -d "$dest/.git" ] && { ok "$(basename "$dest")"; return; }
        run git clone --depth=1 "$url" "$dest"
    }
    _clone_zsh_plugin https://github.com/zsh-users/zsh-autosuggestions "$custom/plugins/zsh-autosuggestions"
    _clone_zsh_plugin https://github.com/zsh-users/zsh-syntax-highlighting "$custom/plugins/zsh-syntax-highlighting"
    _clone_zsh_plugin https://github.com/zsh-users/zsh-completions "$custom/plugins/zsh-completions"
    _clone_zsh_plugin https://github.com/zsh-users/zsh-history-substring-search "$custom/plugins/zsh-history-substring-search"
}

install_nerd_font() {
    local font_dir="$HOME/.local/share/fonts/JetBrainsMonoNerd"
    if [ -d "$font_dir" ] && ls "$font_dir"/*.ttf >/dev/null 2>&1; then
        ok "JetBrains Mono Nerd Font"; return
    fi
    info "Installing JetBrains Mono Nerd Font"
    if "$DRY_RUN"; then printf '  would install font\n'; return; fi
    local tmpdir; tmpdir="$(mktemp -d)"
    curl -fsSL -o "$tmpdir/JetBrainsMono.tar.xz" \
        "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz"
    mkdir -p "$font_dir"
    tar -xf "$tmpdir/JetBrainsMono.tar.xz" -C "$font_dir" --wildcards '*.ttf' 2>/dev/null || \
        tar -xf "$tmpdir/JetBrainsMono.tar.xz" -C "$font_dir"
    rm -rf "$tmpdir"
    run fc-cache -f
}

install_starship() {
    has starship && { ok "starship"; return; }
    info "Installing starship"
    if "$DRY_RUN"; then printf '  would install starship\n'; return; fi
    sh -c 'curl -sS https://starship.rs/install.sh | sh -s -- -y'
}

install_eww() {
    { has eww || [ -x "$HOME/.local/bin/eww" ]; } && { ok "eww"; return; }
    has cargo || { warn "cargo not found; skipping eww build"; return; }
    info "Building Eww v0.6.0 for Wayland (this takes a few minutes)..."
    if "$DRY_RUN"; then printf '  would build eww\n'; return; fi
    local tmpdir; tmpdir="$(mktemp -d)"
    git clone --quiet --depth 1 --branch v0.6.0 https://github.com/elkowar/eww.git "$tmpdir/eww" &&
        cargo build --quiet --release --no-default-features --features=wayland \
            --manifest-path "$tmpdir/eww/Cargo.toml" || { rm -rf "$tmpdir"; die "Eww build failed"; }
    mkdir -p "$HOME/.local/bin"
    install -m755 "$tmpdir/eww/target/release/eww" "$HOME/.local/bin/eww"
    rm -rf "$tmpdir"
    ok "installed eww to ~/.local/bin/eww"
}

# ── .gitconfig ─────────────────────────────────────────────────────────

setup_gitconfig() {
    local gc="$HOME/.gitconfig"
    if [ -f "$gc" ]; then
        ok "~/.gitconfig already exists"
        return
    fi
    info "Setting up ~/.gitconfig"
    if "$DRY_RUN"; then printf '  would create ~/.gitconfig from template\n'; return; fi
    local name email
    if [ -t 0 ]; then
        printf '  Git display name: '; read -r name
        printf '  Git email: '; read -r email
    else
        name="$(git config --global user.name 2>/dev/null || echo "")"
        email="$(git config --global user.email 2>/dev/null || echo "")"
        [ -z "$name" ] && { warn "non-interactive and no git name set; skipping .gitconfig"; return; }
    fi
    sed -e "s/__GIT_NAME__/$name/" -e "s/__GIT_EMAIL__/$email/" \
        "$REPO/home/.gitconfig.example" > "$gc"
    ok "created ~/.gitconfig"
}

# ── Terminal config ───────────────────────────────────────────────────

setup_terminal() {
    info "Configuring terminal (zsh, kitty, starship)"

    install_oh_my_zsh
    install_zsh_plugins
    install_nerd_font
    if [ "$DISTRO_FAMILY" = "apt" ] || [ "$DISTRO_FAMILY" = "dnf" ]; then
        install_starship
    fi

    link_file "$REPO/home/.zshrc" "$HOME/.zshrc"
    link "$REPO/config/kitty" "$CFG/kitty"
    link_file "$REPO/config/starship.toml" "$CFG/starship.toml"
    link_file "$REPO/config/bin/shortcuts" "$HOME/.local/bin/shortcuts"

    setup_gitconfig

    local zsh_bin
    zsh_bin="$(command -v zsh || printf /usr/bin/zsh)"
    if [ "${SHELL:-}" != "$zsh_bin" ]; then
        info "Setting login shell to zsh"
        run chsh -s "$zsh_bin"
    else
        ok "login shell is zsh"
    fi
}

# ── Desktop config (Hyprland) ────────────────────────────────────────

setup_desktop_hyprland() {
    info "Configuring Hyprland desktop"

    install_eww

    link "$REPO/config/hypr" "$CFG/hypr"
    link "$REPO/config/waybar" "$CFG/waybar"
    link "$REPO/config/eww" "$CFG/eww"
    link "$REPO/config/eww-waybar-panels" "$CFG/eww-waybar-panels"
    link "$REPO/config/nvim" "$CFG/nvim"

    if "$DRY_RUN"; then
        printf '  would generate hyprpaper.conf\n'
    else
        sed "s|__HOME__|$HOME|g" "$REPO/config/hypr/hyprpaper.conf.tpl" > "$REPO/config/hypr/hyprpaper.conf"
        ok "generated hyprpaper.conf"
    fi

    mkdir -p "$CFG/bin"
    for script in "$REPO"/config/bin/*; do
        [ -f "$script" ] || continue
        local name; name="$(basename "$script")"
        [ "$name" = "README.md" ] && continue
        link_file "$script" "$CFG/bin/$name"
    done

    link_file "$REPO/config/bin/wofi-singleton" "$HOME/.local/bin/wofi-singleton"

    seed_file "$REPO/fallback/hypr-theme.conf" "$CFG/hypr/generated/theme.conf"
    seed_file "$REPO/fallback/waybar-theme.css" "$CFG/waybar/generated/theme.css"
    seed_file "$REPO/fallback/waybar-component.css" "$CFG/waybar/generated/component.css"
    seed_file "$REPO/fallback/eww-panels-theme.scss" "$CFG/eww-waybar-panels/generated/theme.scss"
}

# ── Desktop config (KDE) ─────────────────────────────────────────────

setup_desktop_kde() {
    info "Configuring KDE desktop"
    link "$REPO/config/nvim" "$CFG/nvim"
}

# ── Desktop config (XFCE) ────────────────────────────────────────────

setup_desktop_xfce() {
    info "Configuring XFCE desktop"
    link "$REPO/config/nvim" "$CFG/nvim"
}

# ── Theme engine ──────────────────────────────────────────────────────

setup_themes() {
    "$SKIP_THEMES" && { warn "Theme engine skipped"; return 0; }
    info "Installing theme engine"

    mkdir -p "$CFG/hypr/themes" "$CFG/hypr/wallpapers" "$CFG/hypr/generated" "$HOME/.local/bin"

    if [ -d "$REPO/themes/themes" ]; then
        for f in "$REPO"/themes/themes/*.json; do
            [ -f "$f" ] && link_file "$f" "$CFG/hypr/themes/$(basename "$f")"
        done
    fi

    if [ -d "$REPO/themes/wallpapers" ]; then
        for f in "$REPO"/themes/wallpapers/*.png; do
            [ -f "$f" ] && link_file "$f" "$CFG/hypr/wallpapers/$(basename "$f")"
        done
    fi

    if [ -d "$REPO/themes/dist" ] && [ -f "$REPO/themes/tools/unpack-theme-studio.sh" ]; then
        local studio_tmp; studio_tmp="$(mktemp -d)"
        trap 'rm -rf "$studio_tmp"' RETURN
        bash "$REPO/themes/tools/unpack-theme-studio.sh" "$studio_tmp" >/dev/null 2>&1 || true

        for bin in theme-legacy theme-studio theme-new theme-menu wallgen starship-config \
                   theme-pywalfox theme-stylus theme-from-image theme-uninstall; do
            [ -f "$REPO/themes/bin/$bin" ] && link_file "$REPO/themes/bin/$bin" "$HOME/.local/bin/$bin"
        done
        [ -f "$REPO/themes/bin/theme-studio" ] && link_file "$REPO/themes/bin/theme-studio" "$HOME/.local/bin/theme"

        for mod in theme_starship.py theme_effects.py theme_homepage.py theme_editor.py theme_runtime.py; do
            [ -f "$REPO/themes/bin/$mod" ] && link_file "$REPO/themes/bin/$mod" "$HOME/.local/bin/$mod"
        done
        for mod in theme_schema.py theme_preview.py theme_waybar.py theme_components.py theme_tui_widgets.py theme_tui.py; do
            [ -f "$studio_tmp/$mod" ] && install -m644 "$studio_tmp/$mod" "$HOME/.local/bin/$mod"
        done
    fi

    write_targets_conf
    setup_editor_theming
}

# ── Auto-theming for editors/apps ─────────────────────────────────────

setup_editor_theming() {
    info "Configuring auto-theming for editors"

    local vscodium_settings="$CFG/VSCodium/User/settings.json"
    if [ -d "$CFG/VSCodium" ] || has codium; then
        ensure_vscode_theme_target "$vscodium_settings" "VSCodium"
    fi

    local vscode_settings="$CFG/Code/User/settings.json"
    if [ -d "$CFG/Code" ] || has code; then
        ensure_vscode_theme_target "$vscode_settings" "VS Code"
    fi

    local claude_settings="$CFG/claude-code/settings.json"
    if [ -d "$CFG/claude-code" ] || has claude; then
        ok "Claude Code detected — uses terminal theme automatically"
    fi
}

ensure_vscode_theme_target() {
    local settings_file="$1" editor_name="$2"
    if [ ! -f "$settings_file" ]; then
        ok "$editor_name not configured yet (no settings.json)"
        return
    fi
    ok "$editor_name detected — add 'vscodium' or 'vscode' to targets.conf to auto-theme"
}

# ── targets.conf generation ───────────────────────────────────────────

write_targets_conf() {
    local out="$CFG/theme-engine/targets.conf"
    if [ -f "$out" ]; then
        ok "targets.conf already exists"
        return
    fi
    mkdir -p "$CFG/theme-engine"
    {
        printf '# Theme targets — one per line. Comment out to disable.\n'
        printf '# Auto-detected desktop: %s\n\n' "$DESKTOP"
        case "$DESKTOP" in
            hyprland)
                echo hypr
                has waybar && echo waybar || echo "# waybar"
                has kitty && echo kitty || echo "# kitty"
                has starship && echo starship || echo "# starship"
                has nvim && echo nvim || echo "# nvim"
                echo wallpaper
                has wofi && echo wofi || echo "# wofi"
                has dunst && echo dunst || echo "# dunst"
                has hyprlock && echo hyprlock || echo "# hyprlock"
                has eww && echo homepage || echo "# homepage"
                echo "# kde"
                echo "# gtk"
                echo "# xfce"
                ;;
            kde)
                has kitty && echo kitty || echo "# kitty"
                has starship && echo starship || echo "# starship"
                has nvim && echo nvim || echo "# nvim"
                has plasma-apply-colorscheme && echo kde || echo "# kde"
                echo "# hypr"
                echo "# waybar"
                ;;
            xfce)
                has kitty && echo kitty || echo "# kitty"
                has starship && echo starship || echo "# starship"
                has nvim && echo nvim || echo "# nvim"
                echo xfce
                echo "# hypr"
                echo "# waybar"
                echo "# kde"
                ;;
            *)
                has kitty && echo kitty || echo "# kitty"
                has starship && echo starship || echo "# starship"
                has nvim && echo nvim || echo "# nvim"
                echo "# hypr"
                echo "# waybar"
                echo "# kde"
                echo "# xfce"
                ;;
        esac
        echo ""
        has codium && echo vscodium || echo "# vscodium"
        has code && echo "# vscode" || true
        echo "# obsidian=~/Documents/Obsidian Vault"
        echo "# firefox"
    } > "$out"
    ok "wrote $out"
}

# ── Services ──────────────────────────────────────────────────────────

enable_services() {
    local services_conf="$REPO/services.conf"
    [ -f "$services_conf" ] || return 0
    local scope unit group
    while IFS=' ' read -r scope unit group; do
        [[ "$scope" =~ ^#.*$ || -z "$scope" ]] && continue
        case "$scope" in
            system)
                systemctl list-unit-files 2>/dev/null | grep -q "^$unit" && run sudo systemctl enable "$unit" || true ;;
            user)
                systemctl --user list-unit-files 2>/dev/null | grep -q "^$unit" && run systemctl --user enable "$unit" || true ;;
        esac
    done < "$services_conf"
}

# ── Debian/Fedora fixups ─────────────────────────────────────────────

post_install_fixups() {
    if [ "$DISTRO_FAMILY" = "apt" ]; then
        local bin_dir="$HOME/.local/bin"
        mkdir -p "$bin_dir"
        if has batcat && ! has bat; then
            ln -sf "$(command -v batcat)" "$bin_dir/bat"
            ok "symlinked bat -> batcat"
        fi
        if has fdfind && ! has fd; then
            ln -sf "$(command -v fdfind)" "$bin_dir/fd"
            ok "symlinked fd -> fdfind"
        fi
    fi
}

# ── Profile expansion ─────────────────────────────────────────────────

expand_profile() {
    local profile="$1"
    local file="$REPO/profiles/$profile.groups"
    if [ -f "$file" ]; then
        read_list "$file"
    else
        printf '%s\n' "$profile"
    fi
}

# ── Usage / UI ────────────────────────────────────────────────────────

usage() {
    cat <<'EOF'
Usage: ./install.sh [options]

One-command setup for a portable Linux desktop.
Auto-detects your distro and desktop environment.

Options:
  --dry-run       preview changes without applying
  --yes           skip confirmation prompts
  --no-pkgs       skip package installation
  --no-flatpak    skip flatpak apps
  --no-themes     skip theme engine
  -h, --help      show this help

The installer detects your desktop (Hyprland, KDE, XFCE, etc.)
and only installs relevant packages and configs.
EOF
}

show_welcome() {
    printf '\n'
    printf '  ┌──────────────────────────────────────────────────────────┐\n'
    printf '  │                    desktop setup                        │\n'
    printf '  │                                                         │\n'
    printf '  │  Distro:   %-43s│\n' "$DISTRO ($PKG_MGR)"
    printf '  │  Desktop:  %-43s│\n' "$DESKTOP"
    printf '  │  Machine:  %-43s│\n' "$MACHINE"
    printf '  │                                                         │\n'
    printf '  │  Everything is symlinked back to this repo.             │\n'
    printf '  │  Edit in either place — changes stay in sync.           │\n'
    printf '  │                                                         │\n'
    printf '  │  Run with --dry-run to preview without changes.         │\n'
    printf '  └──────────────────────────────────────────────────────────┘\n'
    printf '\n'
}

confirm() {
    "$ASSUME_YES" && return
    "$DRY_RUN" && return
    [ -t 0 ] || die 'refusing non-interactive apply without --yes'
    printf 'Apply? [y/N] '
    local answer; read -r answer
    [[ "$answer" =~ ^[Yy]([Ee][Ss])?$ ]] || die 'cancelled'
}

# ── Determine which groups to install ─────────────────────────────────

resolve_install_groups() {
    local -a groups=(minimal essentials terminal)

    case "$DESKTOP" in
        hyprland) groups+=(desktop themes) ;;
        kde)      groups+=(desktop themes) ;;
        xfce)     groups+=(desktop themes) ;;
        *)        groups+=(themes) ;;
    esac

    case "$MACHINE" in
        laptop) groups+=(laptop) ;;
        vm)     groups+=(vm) ;;
    esac

    printf '%s\n' "${groups[@]}"
}

# ── Print plan ────────────────────────────────────────────────────────

print_plan() {
    local -a groups=()
    mapfile -t groups < <(resolve_install_groups)

    printf '── Plan ──────────────────────────────────────────────────────\n'
    printf '  package groups:  %s\n' "${groups[*]}"
    printf '  terminal:        zsh, kitty, starship, font, oh-my-zsh\n'
    printf '  login shell:     zsh\n'
    case "$DESKTOP" in
        hyprland)
            printf '  desktop:         hyprland, waybar, eww panels, nvim\n'
            printf '  helpers:         waybar-panel, workspace-switcher, power-menu, etc.\n'
            ;;
        kde)
            printf '  desktop:         nvim (KDE manages its own config)\n'
            ;;
        xfce)
            printf '  desktop:         nvim (XFCE manages its own config)\n'
            ;;
        *)
            printf '  desktop:         (none detected — terminal only)\n'
            ;;
    esac
    printf '  themes:          theme engine + auto-theming for editors\n'
    printf '  method:          symlinks (edit anywhere, changes stay in sync)\n'
    printf '  state dir:       %s/install-<timestamp>\n' "$STATE_ROOT"
    printf '──────────────────────────────────────────────────────────────\n\n'
}

# ── Main ──────────────────────────────────────────────────────────────

while (($#)); do
    case "$1" in
        --dry-run)    DRY_RUN=true ;;
        --yes|-y)     ASSUME_YES=true ;;
        --no-pkgs)    SKIP_PACKAGES=true ;;
        --no-flatpak) SKIP_FLATPAKS=true ;;
        --no-themes)  SKIP_THEMES=true ;;
        -h|--help)    usage; exit 0 ;;
        *)            usage >&2; die "unknown option: $1" ;;
    esac
    shift
done

detect_distro
detect_desktop
detect_machine
show_welcome
print_plan
confirm
ensure_state_dir

info "[1/5] Installing packages"
_install_groups=()
mapfile -t _install_groups < <(resolve_install_groups)
install_packages_for_groups "${_install_groups[@]}"

info "[2/5] Setting up terminal"
setup_terminal

info "[3/5] Setting up desktop"
case "$DESKTOP" in
    hyprland) setup_desktop_hyprland ;;
    kde)      setup_desktop_kde ;;
    xfce)     setup_desktop_xfce ;;
    *)        ok "no desktop-specific config needed" ;;
esac

info "[4/5] Installing themes"
setup_themes

info "[5/5] Finishing up"
enable_services
post_install_fixups

printf '\n'
if "$DRY_RUN"; then
    printf 'Dry run complete. No changes were made.\n'
else
    ok "Done! Backups: $STATE_DIR"
    printf '\n── Next steps ────────────────────────────────────────────────\n'
    printf '  1. Open a new terminal or run: exec zsh\n'
    case "$DESKTOP" in
        hyprland)
            printf '  2. Log out and select Hyprland at your display manager\n'
            printf '  3. Super+Shift+? for keybind cheat sheet\n'
            ;;
        *)
            printf '  2. Theme engine: theme <name>  (try: theme catppuccin_mocha)\n'
            ;;
    esac
    printf '  Theming: run "theme" to open Theme Studio\n'
    printf '  Update:  git -C %s pull\n' "$REPO"
    printf '──────────────────────────────────────────────────────────────\n'
fi
