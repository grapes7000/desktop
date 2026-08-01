#!/usr/bin/env python3
"""Waybar component generator for Theme Studio.

Keeps the hand-authored Waybar config as the fallback and writes generated files
under ~/.config/waybar/generated. The launcher in hyprland-setup selects the
studio-generated config when present.
"""
from __future__ import annotations

from copy import deepcopy
import json
import os
from pathlib import Path
import re
import subprocess
from typing import Any

from theme_schema import DEFAULT_WAYBAR_MODULES, deep_get, ensure_theme_schema, role_color

CFG = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
WAYBAR_DIR = CFG / "waybar"
GENERATED_DIR = WAYBAR_DIR / "generated"


def strip_jsonc(text: str) -> str:
    """Remove // and /* */ comments without damaging quoted strings."""
    out: list[str] = []
    i = 0
    in_string = False
    escaped = False
    while i < len(text):
        char = text[i]
        nxt = text[i + 1] if i + 1 < len(text) else ""
        if in_string:
            out.append(char)
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == '"':
                in_string = False
            i += 1
            continue
        if char == '"':
            in_string = True
            out.append(char)
            i += 1
            continue
        if char == "/" and nxt == "/":
            i += 2
            while i < len(text) and text[i] not in "\r\n":
                i += 1
            continue
        if char == "/" and nxt == "*":
            end = text.find("*/", i + 2)
            i = len(text) if end < 0 else end + 2
            continue
        out.append(char)
        i += 1
    return "".join(out)


def load_base_config(path: Path | None = None) -> dict[str, Any]:
    base = path or WAYBAR_DIR / "config.jsonc"
    if not base.exists():
        return default_base_config()
    try:
        return json.loads(strip_jsonc(base.read_text(encoding="utf-8")))
    except (OSError, json.JSONDecodeError):
        return default_base_config()


def default_base_config() -> dict[str, Any]:
    return {
        "layer": "top",
        "position": "top",
        "height": 34,
        "margin-top": 6,
        "margin-left": 10,
        "margin-right": 10,
        "spacing": 6,
        "modules-left": deepcopy(DEFAULT_WAYBAR_MODULES["left"]),
        "modules-center": deepcopy(DEFAULT_WAYBAR_MODULES["center"]),
        "modules-right": deepcopy(DEFAULT_WAYBAR_MODULES["right"]),
        "clock": {"format": "  {:%a %d %b   %H:%M}", "tooltip-format": "<tt>{calendar}</tt>"},
        "pulseaudio": {
            "format": "{icon}  {volume}%", "format-muted": "  muted",
            "format-icons": {"default": ["", "", ""]},
            "on-click": "pamixer -t", "on-click-right": "pavucontrol",
        },
        "network": {
            "format-wifi": "  {essid}", "format-ethernet": "  {ipaddr}",
            "format-disconnected": "  off", "tooltip-format": "{ifname}: {ipaddr}",
        },
        "battery": {
            "states": {"warning": 25, "critical": 10},
            "format": "{icon} {capacity}%", "format-charging": "󰂄 {capacity}%",
            "format-icons": ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"],
        },
        "tray": {"spacing": 10},
    }


def _module_id(module: str) -> str:
    return "#" + module.replace("/", "-")


def _all_modules(waybar: dict[str, Any]) -> list[str]:
    result: list[str] = []
    for side in ("left", "center", "right"):
        for module in waybar.get("modules", {}).get(side, []):
            if module not in result:
                result.append(module)
    return result


def build_config(theme: dict[str, Any], base: dict[str, Any] | None = None) -> dict[str, Any]:
    theme = ensure_theme_schema(theme)
    bar = theme["components"]["waybar"]
    config = deepcopy(base or load_base_config())
    config["layer"] = "top"
    config["position"] = bar.get("position", "top")
    config["height"] = int(bar.get("height", 34))
    margin = int(bar.get("margin", 10))
    layout = bar.get("layout", "islands")
    if layout == "full":
        margin = 0
    config["margin-left"] = margin
    config["margin-right"] = margin
    if config["position"] == "top":
        config["margin-top"] = margin if layout != "full" else 0
        config.pop("margin-bottom", None)
    else:
        config["margin-bottom"] = margin if layout != "full" else 0
        config.pop("margin-top", None)
    config["spacing"] = int(bar.get("module_gap", 6))
    modules = bar.get("modules", {})
    config["modules-left"] = list(modules.get("left", []))
    config["modules-center"] = list(modules.get("center", []))
    config["modules-right"] = list(modules.get("right", []))
    clock = config.setdefault("clock", {})
    clock["format"] = str(bar.get("clock_format", clock.get("format", "{:%H:%M}")))
    battery = config.setdefault("battery", {})
    battery["states"] = {
        "warning": int(bar.get("battery_warning", 25)),
        "critical": int(bar.get("battery_critical", 10)),
    }
    # Apply optional per-module config overrides without forcing them on beginners.
    for module, override in bar.get("module_overrides", {}).items():
        if isinstance(override, dict):
            config.setdefault(module, {}).update(deepcopy(override.get("config", {})))
    return config


def render_component_css(theme: dict[str, Any]) -> str:
    theme = ensure_theme_schema(theme)
    bar = theme["components"]["waybar"]
    roles = theme["roles"]
    modules = _all_modules(bar)
    selectors = ",\n".join(_module_id(module) for module in modules)
    workspace = [module for module in modules if module.startswith("custom/ws") or module == "hyprland/workspaces"]
    ws_selectors = ",\n".join(_module_id(module) for module in workspace)
    layout = bar.get("layout", "islands")
    module_surface = bar.get("module_surface", "islands")
    radius = int(bar.get("radius", 14))
    padding = int(bar.get("module_padding", 10))
    gap = int(bar.get("module_gap", 6))
    opacity = float(bar.get("opacity", 0.82))
    border_width = int(bar.get("border_width", 1))
    bg_role = str(bar.get("background_role", "surface_0"))
    border_role = str(bar.get("border_role", "border_subtle"))
    text_role = str(bar.get("text_role", "text"))
    font_size = int(bar.get("font_size", 13))
    icon_size = int(bar.get("icon_size", 18))
    shadow = "0 6px 24px alpha(@shadow, 0.35)" if bar.get("shadow") else "none"

    if module_surface == "transparent" or layout == "minimal":
        module_bg = "transparent"
        module_border = "none"
    elif module_surface == "single" or layout in ("full", "floating"):
        module_bg = "transparent"
        module_border = "none"
    else:
        module_bg = f"alpha(@{bg_role}, {opacity:.3f})"
        module_border = f"{border_width}px solid alpha(@{border_role}, 0.55)" if border_width else "none"

    if layout == "full":
        window_bg = f"alpha(@{bg_role}, {opacity:.3f})"
        window_border = "none"
        window_radius = 0
    elif layout == "floating":
        window_bg = f"alpha(@{bg_role}, {opacity:.3f})"
        window_border = f"{border_width}px solid alpha(@{border_role}, 0.55)" if border_width else "none"
        window_radius = radius
    else:
        window_bg = "transparent"
        window_border = "none"
        window_radius = radius

    ws = bar.get("workspace", {})
    css = f'''/* AUTO-GENERATED by Theme Studio — component geometry and states */
* {{
  font-size: {font_size}px;
}}

window#waybar {{
  background: {window_bg};
  color: @{text_role};
  border: {window_border};
  border-radius: {window_radius}px;
  box-shadow: {shadow};
}}

.modules-left > widget, .modules-center > widget, .modules-right > widget {{
  padding: 0 {gap}px;
}}

{selectors or '#clock'} {{
  color: @{text_role};
  background: {module_bg};
  padding: 2px {padding}px;
  margin: 2px 0;
  border-radius: {radius}px;
  border: {module_border};
  min-height: {max(0, int(bar.get('height', 34)) - 8)}px;
}}

{selectors or '#clock'}:hover {{
  background: alpha(@hover, 0.72);
  border-color: alpha(@border_strong, 0.70);
}}

#tray > .passive {{ -gtk-icon-effect: dim; }}
#tray > .needs-attention {{ -gtk-icon-effect: highlight; }}
#tray menu {{ background: @surface_0; color: @text; border: 1px solid @border_subtle; }}

#custom-running-apps {{ font-size: {icon_size}px; }}
'''
    if ws_selectors:
        css += f'''
/* Workspace states */
{ws_selectors} {{
  color: @{ws.get('inactive_role', 'text_dim')};
  background: transparent;
  border-color: transparent;
}}
{ws_selectors}.empty {{ color: @{ws.get('empty_role', 'disabled')}; }}
{ws_selectors}.urgent {{
  color: @{ws.get('urgent_role', 'urgent')};
  background: alpha(@urgent, 0.18);
  border-color: alpha(@urgent, 0.65);
}}
{ws_selectors}.active {{
  color: @{ws.get('active_role', 'accent')};
  background: alpha(@{ws.get('active_background_role', 'selected')}, 0.20);
  border-color: alpha(@{ws.get('active_border_role', 'accent')}, 0.70);
  font-weight: bold;
}}
'''
    # Per-module style overrides are intentionally opt-in.
    for module, override in bar.get("module_overrides", {}).items():
        if not isinstance(override, dict) or not override.get("enabled", False):
            continue
        selector = _module_id(module)
        values: list[str] = []
        if "background_role" in override:
            values.append(f"background: alpha(@{override['background_role']}, {float(override.get('opacity', opacity)):.3f});")
        if "text_role" in override:
            values.append(f"color: @{override['text_role']};")
        if "border_role" in override:
            values.append(f"border-color: alpha(@{override['border_role']}, 0.70);")
        if "padding" in override:
            values.append(f"padding-left: {int(override['padding'])}px; padding-right: {int(override['padding'])}px;")
        if "radius" in override:
            values.append(f"border-radius: {int(override['radius'])}px;")
        if values:
            css += f"\n{selector} {{ {' '.join(values)} }}\n"
    return css


def render_theme_css(theme: dict[str, Any]) -> str:
    roles = ensure_theme_schema(theme)["roles"]
    keys = (
        "bg", "bg_alt", "text", "text_dim", "accent", "accent2", "urgent", "focus",
        "surface_0", "surface_1", "surface_2", "overlay", "hover", "selected",
        "border_subtle", "border_strong", "success", "warning", "info", "disabled",
        "shadow", "on_accent", "on_urgent",
    )
    return "/* AUTO-GENERATED by Theme Studio */\n" + "".join(
        f"@define-color {key} {roles[key]};\n" for key in keys if key in roles
    )


def write_generated(theme: dict[str, Any], waybar_dir: Path | None = None) -> dict[str, Path]:
    target = Path(waybar_dir or WAYBAR_DIR).expanduser()
    generated = target / "generated"
    generated.mkdir(parents=True, exist_ok=True)
    base = load_base_config(target / "config.jsonc")
    config = build_config(theme, base)
    paths = {
        "config": generated / "config.jsonc",
        "component_css": generated / "component.css",
        "theme_css": generated / "theme.css",
    }
    paths["config"].write_text(json.dumps(config, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    paths["component_css"].write_text(render_component_css(theme), encoding="utf-8")
    paths["theme_css"].write_text(render_theme_css(theme), encoding="utf-8")
    return paths


def reload_waybar() -> None:
    try:
        subprocess.run(["pkill", "-USR2", "-x", "waybar"], check=False,
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except FileNotFoundError:
        pass


def restart_waybar(waybar_dir: Path | None = None) -> None:
    target = Path(waybar_dir or WAYBAR_DIR).expanduser()
    launcher = target / "launch.sh"
    try:
        subprocess.run(["pkill", "-x", "waybar"], check=False,
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except FileNotFoundError:
        return
    if launcher.exists():
        subprocess.Popen([str(launcher)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                         start_new_session=True)
    else:
        config = target / "generated" / "config.jsonc"
        style = target / "style.css"
        cmd = ["waybar"]
        if config.exists():
            cmd += ["-c", str(config)]
        if style.exists():
            cmd += ["-s", str(style)]
        try:
            subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                             start_new_session=True)
        except FileNotFoundError:
            pass


def apply(theme: dict[str, Any], restart: bool = False, waybar_dir: Path | None = None) -> dict[str, Path]:
    paths = write_generated(theme, waybar_dir)
    if restart:
        restart_waybar(waybar_dir)
    else:
        reload_waybar()
    return paths
