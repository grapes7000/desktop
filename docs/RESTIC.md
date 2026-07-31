---
title: Restic Backup Plan
tags: [restic, backup, recovery, linux]
---

# Restic Backup Plan

Restic is installed by the `essentials` group, but this starter intentionally does not create a repository or store a password.

## Git versus Restic

```text
GitHub stores instructions and configuration.
Restic stores actual personal and application data.
```

Good Restic candidates:

- Documents and Obsidian vaults
- creative projects and source media
- application data that cannot be regenerated
- exported databases
- selected Docker volume backups from the future homelab repo

Do not back up disposable caches or a full home directory blindly before reviewing exclusions.

## Future design

Use at least two destinations:

1. A local external disk for fast recovery.
2. An independent server or off-site destination.

Store the Restic password in a password manager and an offline recovery record. Never commit it to either repository.

> [!todo]
> Add a separate reviewed Restic module only after the first setup profiles are tested. Backup scripts should not silently guess which personal folders matter.
