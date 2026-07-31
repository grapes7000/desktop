# Hyprland Setup Ricing Suggestions

Here are curated suggestions to enhance the visual appeal and functionality of your Hyprland setup.

## 🎨 Visual Enhancements

### 1. **Workspace Icons with Names**
Replace numeric workspace indicators with names that reflect their purpose:
```jsonc
// In waybar/config.jsonc
"hyprland/workspaces": {
  "format": "{name}",
  "format-icons": {
    "1": "󰣇",    // web
    "2": "󰓓",    // terminal
    "3": "󰅩",    // code
    "4": "󰋜",    // files
    "5": "󰵬",    // media
    "default": "󰆢"
  }
}
```

### 2. **Enhanced Waybar Styling**
- Add gradient backgrounds instead of solid colors
- Use rounded corners with subtle shadows
- Add smooth transitions on hover
```css
/* Add to waybar/style.css */
* {
  transition: all 200ms cubic-bezier(0.4, 0.0, 0.2, 1);
}

#workspaces button:hover {
  opacity: 0.8;
  transform: scale(1.1);
}
```

### 3. **Improved Window Animations**
Enhance Hyprland's animation settings in `hypr/conf/behavior.conf`:
```conf
animations {
  enabled = true
  
  # Spring animations for snappier feel
  bezier = spring, 0.1, 1.0, 0.15, 1.15
  bezier = smoothOut, 0.36, 0, 0.66, -0.56
  
  animation = windows,     1, 6, spring, slide
  animation = windowsOut,  1, 4, smoothOut, slide
  animation = fade,        1, 5, default
  animation = workspaces,  1, 4, spring, slidevert
}
```

### 4. **Custom Cursor Theme**
Add a modern cursor theme and increase size for visibility:
```conf
# Add to hypr/conf/input.conf
cursor {
  no_warping = false
  hotspot_padding = 4
}
```

Then install and set via:
```bash
# Install a nice cursor theme
sudo pacman -S bibata-cursor-theme  # or capitaine-cursors, rose-pine-cursor

# Set in ~/.config/hypr/conf/input.conf
env = HYPRCURSOR_THEME,Bibata-Modern-Classic
env = HYPRCURSOR_SIZE,24
```

## ⌨️ Keybind & Workflow Enhancements

### 5. **Quick Workspace Switcher**
Add a visual workspace switcher with dmenu/rofi:
```bash
bind = $mod, Tab, exec, ~/.local/bin/workspace-switcher
```

Create `~/.local/bin/workspace-switcher`:
```bash
#!/bin/bash
ws=$(seq 1 10 | wofi --dmenu -p "Go to workspace:")
[ -n "$ws" ] && hyprctl dispatch workspace $ws
```

### 6. **Window Swallowing**
Add rules to "swallow" image viewers and other child windows:
```conf
# In hypr/conf/windowrules.conf
windowrule = stayfocused, feh
windowrule = stayfocused, mpv
```

### 7. **Quick Note Taking**
Add a scratchpad terminal for quick notes:
```bash
bind = $mod SHIFT, n, togglespecialworkspace, notes
bind = $mod SHIFT, n, movetoworkspace, +special:notes

# In windowrules.conf
windowrule = workspace special:notes silent, kitty --title notes
```

## 🔧 Functional Improvements

### 8. **System Monitor in Waybar**
Replace simple CPU/Memory with a more detailed monitor:
```jsonc
"custom/sysstat": {
  "exec": "~/.config/waybar/scripts/sysstat.sh",
  "return-type": "json",
  "interval": 2
}
```

### 9. **Weather Module**
Add a weather display (requires API):
```jsonc
"custom/weather": {
  "exec": "~/.config/waybar/scripts/weather.sh",
  "interval": 600,
  "return-type": "json",
  "tooltip-format": "{tooltip}"
}
```

### 10. **Notification Center Integration**
Use `dunst` or `mako` with custom themes:
```bash
sudo pacman -S mako  # or dunst
```

Add theme config with accent colors from your theme system.

## 🎯 Advanced Ricing

### 11. **Custom Hyprland Logout Menu**
```bash
# Add to waybar config
bind = $mod, Escape, exec, ~/.local/bin/power-menu

# Create power-menu script using wofi/rofi
```

### 12. **Floating Window Rules Enhancement**
Better organize floating windows:
```conf
# In hypr/conf/windowrules.conf
windowrule = float,        class:^(pavucontrol)$
windowrule = float,        class:^(blueman-manager)$
windowrule = float,        class:^(nm-connection-editor)$
windowrule = size 50% 50%, class:^(pavucontrol)$
windowrule = center,       class:^(pavucontrol)$
```
> Use the unified `windowrule` + `class:^(...)$` matcher (not `windowrulev2`,
> which prints a deprecation overlay on Hyprland 0.56). These are already wired
> up in `hypr/conf/windowrules.conf`.

### 13. **Opacity Layers**
> ⚠️ **Leave opacity to the theme engine.** Active/inactive window opacity is
> generated per-theme into `hypr/generated/theme.conf` (the `decoration {}`
> block, driven by `opacity` / `opacity_inactive` in each `themes/<name>.json`).
> Adding per-window `windowrule = opacity ...` lines here would override the
> active theme and break `theme <name>`. If you want a window *always* opaque
> regardless of theme (e.g. an image viewer), that's the one safe exception:
> ```conf
> windowrule = opacity 1.0 1.0, class:^(feh)$
> ```
> Otherwise, tune the look by editing the theme's `opacity` values instead.

Grouped windows (tabbed containers) don't conflict with the theme and are a
nice addition — put them in `hypr/conf/behavior.conf`:
```conf
group {
  groupbar {
    height = 8
    render_titles = true
  }
}
```

### 14. **Auto-Launch App Indicators**
Show which apps are running via waybar:
```jsonc
"custom/running-apps": {
  "exec": "~/.config/waybar/scripts/running-apps.sh",
  "interval": 5
}
```

## 🛠️ Setup & Configuration Tips

### 15. **Modular Theme Color System**
Leverage your existing theme system by:
- Adding more CSS variables in generated theme
- Creating workspace-specific color schemes
- Adding accent color cycling with keybinds

### 16. **Hyprlock Screen Customization**
Enhance `hypr/hyprlock.conf`:
- Add blur to background
- Custom fonts and layouts
- Time/date formatting
- Password field styling

### 17. **Hyprpaper Multi-Monitor Setup**
Optimize `hypr/hyprpaper.conf`:
```conf
preload = /path/to/primary-wallpaper
preload = /path/to/secondary-wallpaper
wallpaper = HDMI-1,/path/to/primary
wallpaper = eDP-1,/path/to/secondary
```

### 18. **Custom Startup Animations**
Create a fancy startup script in `hypr/conf/autostart.conf`:
```bash
exec-once = sleep 1 && notify-send "Welcome back!" "Hyprland is ready"
```

## 📱 Dotfile Organization

### 19. **Better Project Structure**
Consider organizing further:
```
hyprland-setup/
├── hypr/
│   ├── conf/
│   │   ├── decorations.conf    # NEW: border/shadow styles
│   │   ├── animations.conf     # NEW: movement/window animations
│   │   └── rules/
│   │       ├── floating.conf   # NEW: floating window rules
│   │       ├── opacity.conf    # NEW: transparency rules
│   │       └── special.conf    # NEW: special workspace rules
│   └── scripts/                # NEW: utility scripts
│       ├── power-menu
│       └── workspace-switcher
├── waybar/scripts/             # Already good!
└── docs/
    ├── RICING_SUGGESTIONS.md   # You are here!
    └── CUSTOMIZATION.md        # NEW: guide for customization
```

### 20. **Git-Tracked Keybind Documentation**
Keep a quick-reference file:
```bash
echo "# Keybinds" > hypr/KEYBINDS.md
grep "^bind" hypr/conf/keybinds.conf | sed 's/#//' >> hypr/KEYBINDS.md
```

## 🎪 Popular Ricing Techniques

### Color Accenting
- Use your theme's secondary accent (`@accent2`) for additional elements
- Create visual hierarchy with dim/normal/bright text colors

### Spacing & Padding
- Increase `margin-*` values in waybar for breathing room
- Adjust padding in CSS for consistent spacing

### Gaps Between Windows
- Already using dwindle; consider tweaking `gaps_in` and `gaps_out` in behavior.conf

### Icons Over Text
- Where possible, use only icons to save space
- Ensure icons are from Nerd Font for consistency

## 🚀 Performance Tips

1. **Reduce animation complexity** on slower systems
2. **Use blur selectively** (expensive operation)
3. **Limit waybar refresh rates** with appropriate intervals
4. **Consider disabling rounded corners** for performance

## 📚 Resources

- [Hyprland Wiki](https://wiki.hyprland.org/)
- [Waybar Documentation](https://github.com/Alexays/Waybar/wiki)
- [Nerd Fonts](https://www.nerdfonts.com/) - Find more icons
- [r/unixporn](https://reddit.com/r/unixporn/) - Inspiration gallery

---

**Next Steps:**
1. Pick 2-3 suggestions that appeal to you
2. Implement gradually (test after each change)
3. Share your setup on r/unixporn if you're proud of it!
