# waybar

Top bar for wlroots compositors (Hyprland, sway, river, …). Portable beyond
Hyprland, though the `hyprland/*` modules in `config.jsonc` assume Hyprland —
swap them for `sway/*` etc. on other compositors.

- `config.jsonc` — modules (workspaces, window, clock, cpu, mem, audio, net, tray)
- `style.css` — styling; colors come from `@import "generated/theme.css"`,
  written by the [`themes`](../../themes) engine.

Copy both to `~/.config/waybar/`. Reload a running waybar: `pkill -SIGUSR2 waybar`.
