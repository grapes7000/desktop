---
title: Chezmoi Integration
tags: [chezmoi, dotfiles, linux, obsidian]
---

# Chezmoi Integration

Chezmoi is the owner of personal configuration files. The setup repo installs Chezmoi and initializes the separate dotfiles repository.

## Fresh initialization

```bash
chezmoi init --apply https://github.com/grapes7000/dotfiles.git
```

For a private repository, authenticate Git first:

```bash
gh auth login
gh auth setup-git
```

An SSH remote can be used instead:

```bash
chezmoi init --apply git@github.com:grapes7000/dotfiles.git
```

## Daily commands

```bash
chezmoi diff
chezmoi apply
chezmoi edit ~/.zshrc
chezmoi add ~/.config/some-app/config
chezmoi update
chezmoi cd
```

## Boundary

Chezmoi should own stable user configuration. It should not own:

- package installation
- generated theme output
- Docker volumes
- caches
- browser profiles containing active secrets
- SSH private keys in plaintext
- personal documents or media

See the `dotfiles/README.md` file in the separate dotfiles repository after unzipping the bundle.
