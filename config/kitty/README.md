# kitty

Terminal config. **Generic — works in kitty on any OS**, not tied to Hyprland
or Arch.

## Use standalone
Copy `kitty.conf` to `~/.config/kitty/kitty.conf`.

The repo installer also sets Kitty's shell to Zsh and installs the JetBrains
Mono Nerd Font used by this config.

The config includes a self-contained Gruvbox palette and never depends on a
generated theme file. Reload a running Kitty after changes with
`kill -SIGUSR1 $(pgrep kitty)`.
