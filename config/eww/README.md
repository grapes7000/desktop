# Homepage

The desktop homepage is an Eww window started by Hyprland through
`~/.config/eww/launch.sh`. It provides a clock, date, welcome panel, and
discoverable shortcuts on a fresh install.

Logs are written to:

```text
~/.local/state/hyprland-setup/homepage.log
```

Restart it with:

```sh
pkill -x eww
bash ~/.config/eww/launch.sh
```
