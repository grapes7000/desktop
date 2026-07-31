---
title: Adding Packages
tags: [linux, packages, maintenance]
---

# Adding Packages

## Add a native package

Find the matching group and add one package name per line:

```text
packages/apt/development.txt
packages/pacman/development.txt
```

Package names may differ. Add the Ubuntu-family name to `apt/` and Arch name to `pacman/`.

## Add a Flatpak

Add the exact application ID:

```text
packages/flatpak/creative.txt
```

Example:

```text
org.kde.krita
```

## Add a CachyOS-only package

Use:

```text
packages/cachyos/<group>.txt
```

Do not duplicate ordinary Arch packages there.

## Test safely

```bash
./install.sh --dry-run creative
setup install creative --dry-run
```

Then test in a VM before relying on the package during a real wipe.

## Promote a group into a profile

Add its name to a file under `profiles/`. Groups are executed in listed order.
