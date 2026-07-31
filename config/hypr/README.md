# hypr

The Hyprland configuration, modularised. `hyprland.conf` is the entry point and
`source`s everything else in order:

1. `conf/env.conf` — environment variables
2. `conf/monitors.conf` — every output at its preferred/native resolution
3. `generated/theme.conf` — colors + decoration (written by the themes engine)
4. `conf/behavior.conf` — layout, animations, misc
5. `conf/input.conf` — input devices
6. `conf/keybinds.conf` — all keybindings
7. `conf/windowrules.conf` — window rules
8. `conf/autostart.conf` — `exec-once` services

`hyprpaper.conf`, `hyprlock.conf`, `hypridle.conf` configure the wallpaper, lock
screen and idle daemon.

> **Note:** `conf/autostart.conf` contains the spice-vdagent `DISPLAY` fix (see
> ../docs/TROUBLESHOOTING.md §1). `generated/theme.conf` comes from the themes
> engine and is created by the root `install.sh`; run `theme <name>` to switch
> it later.
