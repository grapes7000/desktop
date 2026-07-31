---
title: Linux Setup Architecture
tags: [linux, architecture, automation, obsidian]
---

# Architecture

## Four independent layers

```text
Layer 1 — linux-setup
Installs packages and joins the system together.

Layer 2 — dotfiles
Chezmoi generates the correct home-directory configuration for each machine.

Layer 3 — themes
The existing JSON theme engine generates app and desktop colors/styles.

Layer 4 — Restic
Restores personal data and application state that should never live in Git.
```

A future fifth repository, `homelab`, manages Docker Compose services. It is intentionally not called from normal daily-driver or VM profiles.

## Why profiles contain groups

Profiles are small text files. A profile does not duplicate package lists; it simply names groups in order.

```text
profiles/workstation.groups
  minimal
  essentials
  terminal
  desktop
  development
  communication
  creative
  virtualization
  themes
```

This keeps the system composable:

```bash
setup install essentials
setup install creative
setup install containers
```

## Why generated theme files are not dotfiles

The theme JSON is the source. Files such as Kitty's `generated/theme.conf` are outputs. Storing generated outputs in Chezmoi would create two owners for the same file and cause drift.

Chezmoi stores the stable Kitty settings, including the line that imports the generated theme. The theme engine owns only the generated palette.

## Machine-specific behavior

- Distribution differences are represented by separate `apt/` and `pacman/` lists.
- CachyOS shares Arch lists and receives explicit additions only.
- Chezmoi prompts for a machine role and desktop family.
- Hardware fixes should eventually live in opt-in modules, never in universal profiles.

## Rerun model

The setup command is meant to be rerun. Package managers already skip installed packages; repository integrations update existing clones; group markers record the most recent successful run.

> [!warning]
> A group marker is documentation, not a guarantee that every package succeeded. Always run `setup doctor` after a rebuild.
