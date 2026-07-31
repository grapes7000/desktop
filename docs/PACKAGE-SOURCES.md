---
title: Package Source Policy
tags: [linux, packages, flatpak, apt, pacman]
---

# Package Sources

## Default rule

> [!summary]
> Native packages for the operating-system foundation; Flatpak for ordinary standalone GUI applications.

## Native packages

Use `apt` or `pacman` for:

- shells, terminals, prompts, Git, SSH, and backup tools
- drivers and tablet/input support
- audio, networking, virtualization, and container engines
- desktop environment components
- compilers and system libraries

These packages need normal access to the host and should follow the distribution's update model.

## Flatpak

Use Flatpak for GUI applications that benefit from the same application ID across distributions:

- Obsidian
- Signal
- LocalSend
- Krita
- Blender
- GIMP
- LibreOffice and VLC
- VSCodium in this starter version

> [!warning] VSCodium choice
> The starter uses Flatpak for portability. Some terminal, extension, or coding-agent workflows may work better in a native VSCodium package. Keep only one source installed. If the Flatpak becomes restrictive, remove it from `packages/flatpak/development.txt` and add a documented native installer later.

## Avoid duplicates

Before adding an app, answer:

1. Does the distro already install it?
2. Is it already in another package list?
3. Does the Flatpak need theme or host integration it cannot access?
4. Is an AUR/vendor package genuinely better?

Do not install Firefox, Krita, or VSCodium from two sources merely because both are available.

## AUR policy

The v1 framework does not automatically install an AUR helper or AUR packages. Add AUR support later as a separate, visibly reviewed module. Never hide arbitrary `PKGBUILD` execution inside a normal profile.
