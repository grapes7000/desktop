# Manual Steps

Things the automated installers cannot reproduce. Run these after
`setup install workstation` (or laptop) and `hyprland-setup/install.sh --desktop`.

## System-level config

These are set during OS installation and are not managed by any repo.

```sh
# Locale
sudo localectl set-locale LANG=en_US.UTF-8
# Keyboard
sudo localectl set-keymap us
sudo localectl set-x11-keymap us pc105
# Timezone
sudo timedatectl set-timezone America/Los_Angeles
# Hostname
sudo hostnamectl set-hostname cachyos
```

**Bootloader:** This machine uses Limine (not GRUB). Limine config is at
`/etc/limine.conf` and is managed by `limine-mkinitcpio-hook`. The kernel
cmdline includes `quiet nowatchdog splash rw rootflags=subvol=/@`.

**Display manager:** `plasma-login-manager` (plasmalogin.service). Enabled
by the CachyOS installer. On a fresh install:
```sh
sudo systemctl enable plasma-login-manager.service
```

**User groups:** This machine's user is in: `wheel audio video sys network lp
storage rfkill nopasswdlogin libvirt`. Most are set by the OS installer;
`libvirt` is added by `setup install virtualization`.

## KDE Plasma settings

KDE Plasma is a secondary session alongside Hyprland. Key config files:
- `~/.config/kdeglobals` — LookAndFeel is `CachyOS-Nord`
- `~/.config/kwinrc`, `~/.config/kwinrulesrc`
- `~/.config/plasma-org.kde.plasma.desktop-appletsrc`
- `~/.config/powermanagementprofilesrc`

These are not managed by any repo. To back them up manually:
```sh
tar czf ~/kde-plasma-backup.tar.gz \
  ~/.config/kdeglobals ~/.config/kwinrc ~/.config/kwinrulesrc \
  ~/.config/kscreenlockerrc ~/.config/powermanagementprofilesrc \
  ~/.config/plasma-org.kde.plasma.desktop-appletsrc
```

## External tool installations

These are installed via non-pacman sources and not scripted:

```sh
# uv (Python tool manager)
curl -LsSf https://astral.sh/uv/install.sh | sh

# bun (JS runtime)
curl -fsSL https://bun.sh/install | bash

# pywalfox (browser theme sync with pywal)
pipx install pywalfox

# aider (AI coding assistant)
uv tool install aider-chat

# nvm node versions (nvm is installed via pacman, but versions aren't)
nvm install 22
nvm install 24
```

**npm globals** (installed after nvm sets up node):
```sh
npm install -g pnpm electron node-gyp
```

## Browser extensions

**Floorp** (primary browser):
- Stylus extension — install from the extension store, then import the
  generated userstyle from `~/.config/theme-engine/stylus/`
- Pywalfox extension — install from the extension store, then run
  `pywalfox install` once

## Missing theme wallpapers

8 themes lack pre-generated wallpaper PNGs in the themes repo. After
installing the themes repo, generate them:
```sh
wallgen ayu-dark
wallgen ayu-mirage
wallgen gruvbox-material
wallgen kanagawa-dragon
wallgen oxocarbon
wallgen rose-pine
wallgen rose-pine-dawn
wallgen rose-pine-moon
```

Or generate all at once: `wallgen` (no arguments).

## Snapper / Btrfs

This machine uses Btrfs with snapper for snapshots. The subvolume layout and
snapper configs are created during OS installation by CachyOS. Key packages:
`snapper`, `btrfs-assistant`, `cachyos-snapper-support`, `limine-snapper-sync`.

## Mullvad VPN

Installed via AUR (`mullvad-vpn-beta-bin`, `mullvad-vpn-daemon-beta-bin`,
`mullvad-tui-bin`). After installation, log in:
```sh
mullvad account login <account-number>
```
The account number is stored in Bitwarden, not in any repo.
