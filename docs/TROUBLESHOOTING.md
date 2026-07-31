---
title: Linux Setup Troubleshooting
tags: [linux, troubleshooting, recovery]
---

# Troubleshooting

## Private repositories will not clone

Authenticate GitHub:

```bash
gh auth login
gh auth setup-git
```

Or change repository URLs to SSH in `config/local.env`.

## `setup` or `theme` is not found

Open a new terminal or run:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

The supplied `.zshrc` adds this path permanently.

## Ubuntu cannot find one package

The installer retries packages individually and reports unavailable entries. Remove or rename the offending package in `packages/apt/<group>.txt` after checking the specific Ubuntu version.

## `fd` or `bat` has the wrong executable name on Ubuntu

The dotfiles use friendly names `fd` and `bat`. A later refinement can add automatic `fdfind` and `batcat` shims. Until then:

```bash
mkdir -p ~/.local/bin
ln -sfn "$(command -v fdfind)" ~/.local/bin/fd
ln -sfn "$(command -v batcat)" ~/.local/bin/bat
```

## Flatpak app ignores the desktop theme

This is a sandbox integration issue, not necessarily a broken theme JSON. Keep the application functional first. Add a Flatpak theme extension or override only after documenting it in the themes repo.

## Docker still requires `sudo`

Log out and back in after installing the `containers` group. Group membership does not update every existing shell session.

## Inspect everything

```bash
setup doctor
setup status
cat ~/.local/state/linux-setup/install.log
chezmoi diff
theme --list
```
