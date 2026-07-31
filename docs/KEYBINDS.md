# Keybind Reference

*Auto-generated from `hypr/conf/keybinds.conf`.*

## Duplicate shortcuts

- `Super+Space`: "Run: ~/.local/bin/wofi-singleton --show drun --style ~/.config/wofi/style.css" / "Run: ~/.local/bin/wofi-singleton --show drun --style ~/.config/wofi/style.css"
- `Super+T`: "Run: ~/.local/bin/theme-menu" / "Run: ~/.local/bin/theme-menu"
- `Super+Shift+W`: "Run: ~/.config/bin/workspace-switcher" / "Run: ~/.config/bin/workspace-switcher"
- `Super+Shift+P`: "Run: ~/.config/bin/power-menu" / "Run: ~/.config/bin/power-menu"

## apps / session

| Shortcut | Action |
|----------|--------|
| `Super+Enter` | Run: kitty |
| `Super+Space` | Run: ~/.local/bin/wofi-singleton --show drun --style ~/.config/wofi/style.css |
| `Super+B` | Run: rofi-rbw |
## wofi: click outside, or same key again, to close

| Shortcut | Action |
|----------|--------|
| `LMB` | Run: pkill -x wofi |
| `RMB` | Run: pkill -x wofi |
| `Super+Space` | Run: ~/.local/bin/wofi-singleton --show drun --style ~/.config/wofi/style.css |
| `Super+T` | Run: ~/.local/bin/theme-menu |
| `Super+Shift+P` | Run: ~/.config/bin/power-menu |
| `Super+Shift+W` | Run: ~/.config/bin/workspace-switcher |
| `Super+Q` | Close window |
| `Super+Shift+E` | Exit Hyprland |
| `Super+F` | Fullscreen |
| `Super+V` | Toggle float |
| `Super+X` | Layout: togglesplit |
| `Super+P` | Pseudo-tile |
## focus (vim h/j/k/l + arrows)

| Shortcut | Action |
|----------|--------|
| `Super+h` | Focus: l |
| `Super+l` | Focus: r |
| `Super+k` | Focus: u |
| `Super+j` | Focus: d |
| `Super+left` | Focus: l |
| `Super+right` | Focus: r |
| `Super+up` | Focus: u |
| `Super+down` | Focus: d |
## move window (Shift + vim + arrows)

| Shortcut | Action |
|----------|--------|
| `Super+Shift+h` | Move window: l |
| `Super+Shift+l` | Move window: r |
| `Super+Shift+k` | Move window: u |
| `Super+Shift+j` | Move window: d |
| `Super+Shift+left` | Move window: l |
| `Super+Shift+right` | Move window: r |
| `Super+Shift+up` | Move window: u |
| `Super+Shift+down` | Move window: d |
## resize (Ctrl + vim)

| Shortcut | Action |
|----------|--------|
| `Super+Ctrl+h` | Resize: -40 0 |
| `Super+Ctrl+l` | Resize: 40 0 |
| `Super+Ctrl+k` | Resize: 0 -40 |
| `Super+Ctrl+j` | Resize: 0  40 |
## workspaces

| Shortcut | Action |
|----------|--------|
| `Super+1` | Go to workspace: 1 |
| `Super+2` | Go to workspace: 2 |
| `Super+3` | Go to workspace: 3 |
| `Super+4` | Go to workspace: 4 |
| `Super+5` | Go to workspace: 5 |
| `Super+6` | Go to workspace: 6 |
| `Super+7` | Go to workspace: 7 |
| `Super+8` | Go to workspace: 8 |
| `Super+9` | Go to workspace: 9 |
| `Super+0` | Go to workspace: 10 |
| `Super+Shift+1` | Move to workspace: 1 |
| `Super+Shift+2` | Move to workspace: 2 |
| `Super+Shift+3` | Move to workspace: 3 |
| `Super+Shift+4` | Move to workspace: 4 |
| `Super+Shift+5` | Move to workspace: 5 |
| `Super+Shift+6` | Move to workspace: 6 |
| `Super+Shift+7` | Move to workspace: 7 |
| `Super+Shift+8` | Move to workspace: 8 |
| `Super+Shift+9` | Move to workspace: 9 |
| `Super+Shift+0` | Move to workspace: 10 |
| `Super+ScrollDown` | Go to workspace: e+1 |
| `Super+ScrollUp` | Go to workspace: e-1 |
## theme picker (Super+T)

| Shortcut | Action |
|----------|--------|
| `Super+T` | Run: ~/.local/bin/theme-menu |
## workspace switcher (Super+Shift+W)

| Shortcut | Action |
|----------|--------|
| `Super+Shift+W` | Run: ~/.config/bin/workspace-switcher |
## power menu (Super+Shift+P)

| Shortcut | Action |
|----------|--------|
| `Super+Shift+P` | Run: ~/.config/bin/power-menu |
## quick notes (Super+Shift+N)

| Shortcut | Action |
|----------|--------|
| `Super+Shift+N` | Run: ~/.config/bin/quick-note |
## notifications (Super+N / Super+Ctrl+N)

| Shortcut | Action |
|----------|--------|
| `Super+N` | Run: ~/.config/bin/notification-center |
| `Super+Ctrl+N` | Run: dunstctl history-pop |
## grouped windows

| Shortcut | Action |
|----------|--------|
| `Super+G` | Toggle group |
| `Super+Alt+left` | Switch tab: b |
| `Super+Alt+right` | Switch tab: f |
| `Super+Shift+G` | Lock group: toggle |
## keybind menu (Super+Shift+/)

| Shortcut | Action |
|----------|--------|
| `Super+Shift+/` | Run: ~/.config/bin/keybind-menu |
## screenshots

| Shortcut | Action |
|----------|--------|
| `PrtSc` | Run: grim -g "$(slurp)" - | wl-copy |
| `Super+S` | Run: grim -g "$(slurp)" - | wl-copy |
## media / brightness (repeat while held)

| Shortcut | Action |
|----------|--------|
| `XF86AudioRaiseVolume` | Run: pamixer -i 5 |
| `XF86AudioLowerVolume` | Run: pamixer -d 5 |
| `XF86AudioMute` | Run: pamixer -t |
| `XF86AudioPlay` | Run: playerctl play-pause |
| `XF86AudioNext` | Run: playerctl next |
| `XF86AudioPrev` | Run: playerctl previous |
| `XF86MonBrightnessUp` | Run: brightnessctl set 5%+ |
| `XF86MonBrightnessDown` | Run: brightnessctl set 5%- |
## mouse drag

| Shortcut | Action |
|----------|--------|
| `Super+LMB` | Move window |
| `Super+RMB` | Resize window |
