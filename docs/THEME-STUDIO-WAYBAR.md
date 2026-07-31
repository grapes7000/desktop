# Theme Studio ↔ Waybar contract

The `themes` repository owns palette and editable Waybar component data. This repository owns the stable Waybar module definitions, scripts, and fallback layout.

## Startup

Hyprland starts:

```bash
bash ~/.config/waybar/launch.sh
```

The launcher always uses `~/.config/waybar/config.jsonc`, the current
repository layout installed by `install.sh`.

It always loads `~/.config/waybar/style.css`.

## CSS layers

`style.css` imports:

```css
@import "generated/theme.css";
@import "generated/component.css";
```

- `theme.css` contains semantic palette roles.
- `component.css` contains geometry, spacing, layout, per-state workspace styles, and optional per-module overrides.
- The remainder of `style.css` contains stable semantic behavior for audio, network, battery, notifications, VPN, system stats, and the tray.

The tracked `generated/component.css` is a safe fallback. Theme Studio replaces it at runtime.

## Generated files

Theme Studio writes its palette and component data inside the existing
generated directory:

```text
waybar/generated/theme.css
waybar/generated/component.css
```

The hand-authored `config.jsonc`, scripts, and semantic state rules remain intact.

## Live reload

Normal changes use:

```bash
pkill -USR2 -x waybar
```

Restarting through `launch.sh` preserves the repository module layout.

## Module ownership

This repository owns module selection, order, and placement. Theme Studio owns
the palette and component styling.

Unknown modules are preserved but surfaced as validation suggestions.
