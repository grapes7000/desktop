---
title: Linux Setup Roadmap
tags: [roadmap, linux, setup]
---

# Roadmap

## v1 — included here

- Ubuntu-family, Arch, and CachyOS detection
- profile and package-group framework
- Chezmoi bootstrap
- Starship and Oh My Zsh terminal stack
- existing themes repo integration
- Flatpak/native hybrid
- explicit homelab boundary
- dry-run and diagnostics

## v1.1 — after VM testing

- verify package names on one current Ubuntu release and one Arch/CachyOS VM
- add automatic Ubuntu `fd`/`bat` compatibility shims
- refine VSCodium native-versus-Flatpak decision
- add tests with ShellCheck and a disposable container/VM matrix
- add safer hardware profile detection

## v1.2 — after workstation testing

- selected XFCE/KDE/Hyprland desktop modules
- extension lists for VSCodium
- Tailscale installation as an explicit networking group
- optional gaming group
- explicit NVIDIA/AMD modules

## Later and separate

- reviewed Restic backup automation
- independent homelab repository
- hardware-specific MacBook, ThinkPad, Wacom, and NVIDIA fixes
