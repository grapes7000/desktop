#!/usr/bin/env bash
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
root="$(mktemp -d)"
home="$root/home"
mock="$root/mock"
cleanup() { rm -rf "$root"; }
trap cleanup EXIT

setup_home() {
    rm -rf "$home" "$mock"
    mkdir -p "$home/.config/kitty" "$home/.config/hypr" "$home/.config/waybar" "$home/.config/nvim" "$home/.config/fish" "$home/.local/bin" "$mock"
    printf 'old zsh\n' > "$home/.zshrc"
    printf 'old kitty\n' > "$home/.config/kitty/kitty.conf"
    printf 'old bash\n' > "$home/.bashrc"
    printf 'old fish\n' > "$home/.config/fish/config.fish"
    printf 'old p10k\n' > "$home/.p10k.zsh"
    printf 'hypr sentinel\n' > "$home/.config/hypr/sentinel"
    printf 'waybar sentinel\n' > "$home/.config/waybar/sentinel"
    printf 'nvim sentinel\n' > "$home/.config/nvim/sentinel"
    ln -sf "$home/not-starship" "$home/.config/starship.toml"

    printf '%s\n' '#!/usr/bin/env bash' 'exec "$@"' > "$mock/sudo"
    printf '%s\n' '#!/usr/bin/env bash' 'printf "%s\\n" "$*" >> "$INSTALL_TEST_LOG"' > "$mock/chsh"
    # Mock curl/fc-cache/starship so manual installs don't hit the network
    printf '%s\n' '#!/usr/bin/env bash' 'exit 0' > "$mock/curl"
    printf '%s\n' '#!/usr/bin/env bash' 'exit 0' > "$mock/fc-cache"
    printf '%s\n' '#!/usr/bin/env bash' 'exit 0' > "$mock/starship"
    printf '%s\n' '#!/usr/bin/env bash' 'exit 0' > "$mock/eww"
    printf '%s\n' '#!/usr/bin/env bash' 'exit 0' > "$mock/waybar"
    chmod +x "$mock/sudo" "$mock/chsh" "$mock/curl" "$mock/fc-cache" "$mock/starship" "$mock/eww" "$mock/waybar"
    # Pre-create dirs so manual install functions detect "already installed"
    mkdir -p "$home/.oh-my-zsh" "$home/.local/share/fonts/JetBrainsMonoNerd"
    touch "$home/.local/share/fonts/JetBrainsMonoNerd/JetBrainsMono.ttf"
    rm -f "$root/log"
}

setup_mock_pacman() {
    printf '%s\n' '#!/usr/bin/env bash' 'if [ "$1" = "-Q" ]; then exit 0; fi' 'printf "%s\\n" "$*" >> "$INSTALL_TEST_LOG"' > "$mock/pacman"
    chmod +x "$mock/pacman"
}

setup_mock_dnf() {
    printf '%s\n' '#!/usr/bin/env bash' 'printf "%s\\n" "$*" >> "$INSTALL_TEST_LOG"' > "$mock/dnf"
    chmod +x "$mock/dnf"
}

setup_mock_apt() {
    printf '%s\n' '#!/usr/bin/env bash' 'printf "%s\\n" "$*" >> "$INSTALL_TEST_LOG"' > "$mock/apt"
    printf '%s\n' '#!/usr/bin/env bash' 'exit 1' > "$mock/dpkg"
    chmod +x "$mock/apt" "$mock/dpkg"
}

write_os_release() {
    local distro_id="$1"
    mkdir -p "$root/etc"
    printf 'ID=%s\n' "$distro_id" > "$root/etc/os-release"
}

run_installer() {
    env HOME="$home" USER=tester SHELL="${TEST_SHELL:-/bin/bash}" \
        XDG_STATE_HOME="$home/.state" \
        INSTALL_OS_RELEASE="$root/etc/os-release" \
        PATH="$mock:$PATH" \
        INSTALL_TEST_LOG="$root/log" \
        "$repo/install.sh" "$@"
}

# ── Test 1: Arch dry-run ──────────────────────────────────────────────────

printf '=== Test 1: Arch dry-run ===\n'
setup_home
setup_mock_pacman
write_os_release arch

if ! run_installer --dry-run > "$root/dry-run" 2>&1; then
    sed -n '1,160p' "$root/dry-run" >&2
    printf 'FAIL: dry-run exited non-zero\n' >&2
    exit 1
fi
cmp <(printf 'old zsh\n') "$home/.zshrc"
cmp <(printf 'old kitty\n') "$home/.config/kitty/kitty.conf"
[ ! -e "$root/log" ]
rg -F 'untouched' "$root/dry-run" >/dev/null
rg -F 'arch' "$root/dry-run" >/dev/null
printf '  PASS\n'

# ── Test 2: Arch apply ───────────────────────────────────────────────────

printf '=== Test 2: Arch apply ===\n'
setup_home
setup_mock_pacman
write_os_release arch

if ! run_installer --yes > "$root/apply" 2>&1; then
    sed -n '1,160p' "$root/apply" >&2
    printf 'FAIL: apply exited non-zero\n' >&2
    exit 1
fi
[ -L "$home/.zshrc" ]
cmp "$repo/kitty/kitty.conf" "$home/.config/kitty/kitty.conf"
cmp "$repo/starship/starship.toml" "$home/.config/starship.toml"
cmp <(printf 'old bash\n') "$home/.bashrc"
cmp <(printf 'hypr sentinel\n') "$home/.config/hypr/sentinel"
cmp <(printf 'waybar sentinel\n') "$home/.config/waybar/sentinel"
cmp <(printf 'nvim sentinel\n') "$home/.config/nvim/sentinel"
state_dir="$(find "$home/.state/hyprland-setup" -mindepth 1 -maxdepth 1 -type d)"
[ -f "$state_dir/manifest.tsv" ]
rg -F "$home/.config/starship.toml" "$state_dir/manifest.tsv" >/dev/null
rg -F "$home/.config/fish" "$state_dir/manifest.tsv" >/dev/null
rg -F -- '-Rns cachyos-fish-config fish cachyos-zsh-config zsh-theme-powerlevel10k' "$root/log" >/dev/null
rg -F -- '-s ' "$root/log" >/dev/null
printf '  PASS\n'

# ── Test 3: Arch desktop apply ───────────────────────────────────────────

printf '=== Test 3: Arch desktop apply ===\n'
setup_home
setup_mock_pacman
write_os_release arch

if ! TEST_SHELL=/usr/bin/zsh run_installer --yes --desktop > "$root/desktop-apply" 2>&1; then
    sed -n '1,160p' "$root/desktop-apply" >&2
    printf 'FAIL: desktop apply exited non-zero\n' >&2
    exit 1
fi
cmp "$repo/bin/workspace-switcher" "$home/.config/bin/workspace-switcher"
cmp "$repo/bin/power-menu" "$home/.config/bin/power-menu"
[ "$(readlink -f "$home/.config/waybar")" = "$(readlink -f "$repo/waybar")" ]
[ "$(readlink -f "$home/.config/eww")" = "$(readlink -f "$repo/homepage")" ]
[ "$(readlink -f "$home/.config/eww-waybar-panels")" = "$(readlink -f "$repo/eww/waybar-panels")" ]
[ ! -e "$repo/homepage/waybar-panels" ]
rg -F 'bash ~/.config/waybar/launch.sh' "$home/.config/hypr/conf/autostart.conf" >/dev/null
rg -F 'bash ~/.config/eww/launch.sh' "$home/.config/hypr/conf/autostart.conf" >/dev/null
printf '  PASS\n'

# ── Test 4: Fedora dry-run uses dnf ──────────────────────────────────────

printf '=== Test 4: Fedora dry-run ===\n'
setup_home
setup_mock_dnf
write_os_release fedora

if ! run_installer --dry-run > "$root/fedora-dry" 2>&1; then
    sed -n '1,160p' "$root/fedora-dry" >&2
    printf 'FAIL: fedora dry-run exited non-zero\n' >&2
    exit 1
fi
rg -F 'fedora' "$root/fedora-dry" >/dev/null
rg -F 'fd-find' "$root/fedora-dry" >/dev/null
[ ! -e "$root/log" ]
printf '  PASS\n'

# ── Test 5: Debian dry-run uses apt ──────────────────────────────────────

printf '=== Test 5: Debian dry-run ===\n'
setup_home
setup_mock_apt
write_os_release debian

if ! run_installer --dry-run > "$root/debian-dry" 2>&1; then
    sed -n '1,160p' "$root/debian-dry" >&2
    printf 'FAIL: debian dry-run exited non-zero\n' >&2
    exit 1
fi
rg -F 'debian' "$root/debian-dry" >/dev/null
rg -F 'fd-find' "$root/debian-dry" >/dev/null
[ ! -e "$root/log" ]
printf '  PASS\n'

# ── Test 6: Arch legacy removal skipped on Fedora ────────────────────────

printf '=== Test 6: No legacy removal on Fedora ===\n'
setup_home
setup_mock_dnf
write_os_release fedora

if ! run_installer --yes > "$root/fedora-apply" 2>&1; then
    sed -n '1,160p' "$root/fedora-apply" >&2
    printf 'FAIL: fedora apply exited non-zero\n' >&2
    exit 1
fi
if [ -e "$root/log" ] && rg -qF 'cachyos' "$root/log" 2>/dev/null; then
    printf 'FAIL: legacy packages should not be removed on Fedora\n' >&2
    exit 1
fi
printf '  PASS\n'

# ── Test 7: Unknown distro fails ─────────────────────────────────────────

printf '=== Test 7: Unknown distro fails ===\n'
setup_home
write_os_release opensuse

if run_installer --dry-run > "$root/unknown-dry" 2>&1; then
    printf 'FAIL: unknown distro should have exited non-zero\n' >&2
    exit 1
fi
rg -F 'unsupported' "$root/unknown-dry" >/dev/null
printf '  PASS\n'

# ── Test 8: Desktop launchers log and recover ─────────────────────────────

printf '=== Test 8: Desktop launchers ===\n'
setup_home
mkdir -p "$home/.config/waybar/generated" "$home/.config/eww"
cp "$repo/waybar/config.jsonc" "$home/.config/waybar/config.jsonc"
cp "$repo/waybar/style.css" "$home/.config/waybar/style.css"
cp "$repo/homepage/eww.yuck" "$home/.config/eww/eww.yuck"
cp "$repo/homepage/eww.scss" "$home/.config/eww/eww.scss"
printf '{}\n' > "$home/.config/waybar/generated/config.jsonc"
printf '%s\n' '#!/usr/bin/env bash' \
    'printf "%s\n" "$*" >> "$INSTALL_TEST_LOG"' \
    '[[ "$*" == *generated/config.jsonc* ]] && exit 1' \
    'exit 0' > "$mock/waybar"
printf '%s\n' '#!/usr/bin/env bash' \
    'printf "%s\n" "$*" >> "$INSTALL_TEST_LOG"' \
    'exit 0' > "$mock/eww"
chmod +x "$mock/waybar" "$mock/eww"
export INSTALL_TEST_LOG="$root/log"
PATH="$mock:$PATH" HOME="$home" XDG_CONFIG_HOME="$home/.config" \
    XDG_STATE_HOME="$home/.state" "$repo/waybar/launch.sh"
rg -F "$home/.config/waybar/config.jsonc" "$root/log" >/dev/null
if rg -F 'generated/config.jsonc' "$root/log" >/dev/null; then
    printf 'FAIL: launcher should prefer the shipped Waybar config\n' >&2
    exit 1
fi
rm -f "$root/log"
PATH="$mock:$PATH" HOME="$home" XDG_CONFIG_HOME="$home/.config" \
    XDG_STATE_HOME="$home/.state" "$repo/homepage/launch.sh"
rg -F 'daemon --force-wayland' "$root/log" >/dev/null
rg -F 'open homepage --force-wayland' "$root/log" >/dev/null
printf '  PASS\n'

printf '\nAll installer tests passed.\n'
