---
title: Theme Integration
tags: [themes, hyprland, qtile, kitty, starship]
---

# Theme Integration

The source of truth is the existing private repository:

```text
grapes7000/themes
```

Its `theme <name>` command already reads one JSON file and generates the active styling for supported targets. The setup repo preserves that exact model.

## Installation flow

```text
setup install themes
  ├─ clone or update ~/themes
  ├─ run ~/themes/install.sh
  ├─ install theme helpers into ~/.local/bin
  └─ apply DEFAULT_THEME from config/defaults.env
```

## Commands

```bash
theme                  # list themes and mark the active one
theme y2k              # switch everything supported
theme --list           # names only
theme-new new-name     # scaffold a theme
theme-menu              # graphical picker where supported
wallgen y2k --set       # regenerate and apply wallpaper
```

## Ownership rule

```text
dotfiles repo owns: ~/.config/kitty/kitty.conf
                     ~/.config/starship.toml layout

themes repo owns:   ~/.config/kitty/generated/theme.conf
                     generated palettes and DE target files
```

The Dotfiles aliases intentionally do **not** redefine `theme`. This prevents the old QTile edit-file alias from shadowing the full theme command.

## Selecting a different initial theme

Edit `config/local.env`:

```bash
DEFAULT_THEME="y2k"
```

`config/local.env` is ignored by Git so a machine may choose a local default. Change `config/defaults.env` when you want the repository-wide default changed.
