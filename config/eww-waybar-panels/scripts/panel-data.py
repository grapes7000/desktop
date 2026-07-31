#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

def runtime_state(name: str) -> Path:
    root = Path(os.environ["XDG_RUNTIME_DIR"]) if os.environ.get("XDG_RUNTIME_DIR") else Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state")) / "waybar-panels"
    try:
        root.mkdir(parents=True, exist_ok=True, mode=0o700)
        root.chmod(0o700)
    except OSError:
        pass
    return root / name


NETWORK_STATE = runtime_state("network.json")


def run(*args: str) -> str:
    try:
        return subprocess.run(args, check=False, capture_output=True, text=True, timeout=2).stdout.strip()
    except (OSError, subprocess.TimeoutExpired):
        return ""


ART_CACHE = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "waybar-panels" / "album-art"


def _download_art(url: str, key: str) -> str:
    ART_CACHE.mkdir(parents=True, exist_ok=True)
    import hashlib
    digest = hashlib.sha256(key.encode()).hexdigest()[:20]
    existing = next(ART_CACHE.glob(f"{digest}.*"), None)
    if existing and existing.is_file():
        return str(existing)
    try:
        from urllib.request import Request, urlopen
        req = Request(url, headers={"User-Agent": "waybar-panels/1.0"})
        with urlopen(req, timeout=4) as resp:
            data = resp.read(4 * 1024 * 1024)
            ct = resp.headers.get_content_type() or ""
        ext = {
            "image/jpeg": ".jpg", "image/png": ".png",
            "image/webp": ".webp", "image/gif": ".gif",
        }.get(ct, ".jpg")
        target = ART_CACHE / f"{digest}{ext}"
        import tempfile
        fd, tmp = tempfile.mkstemp(dir=ART_CACHE, suffix=ext)
        try:
            with os.fdopen(fd, "wb") as f:
                f.write(data)
            os.replace(tmp, target)
        except BaseException:
            try:
                os.unlink(tmp)
            except OSError:
                pass
            raise
        return str(target)
    except (OSError, ValueError, TimeoutError):
        return ""


def resolve_album_art(art_url: str, artist: str, album: str) -> str:
    if art_url:
        from urllib.parse import unquote, urlparse
        parsed = urlparse(art_url)
        if parsed.scheme == "file":
            p = Path(unquote(parsed.path))
            if p.is_file():
                return str(p)
        elif parsed.scheme in {"http", "https"}:
            result = _download_art(art_url, art_url)
            if result:
                return result
    if artist and album:
        key = f"{artist}||{album}"
        cached = next(ART_CACHE.glob(f"{__import__('hashlib').sha256(key.encode()).hexdigest()[:20]}.*"), None) if ART_CACHE.exists() else None
        if cached and cached.is_file():
            return str(cached)
        try:
            from urllib.request import Request, urlopen
            from urllib.parse import quote
            query = quote(f'{artist} {album}')
            url = f"https://musicbrainz.org/ws/2/release/?query={query}&fmt=json&limit=1"
            req = Request(url, headers={"User-Agent": "waybar-panels/1.0 (album-art-lookup)"})
            with urlopen(req, timeout=4) as resp:
                data = json.loads(resp.read(64 * 1024))
            releases = data.get("releases", [])
            if releases:
                mbid = releases[0].get("id", "")
                if mbid:
                    cover_url = f"https://coverartarchive.org/release/{mbid}/front-250"
                    return _download_art(cover_url, key)
        except (OSError, ValueError, KeyError, TimeoutError, json.JSONDecodeError):
            pass
    return ""


def audio() -> dict:
    has_pamixer = bool(shutil.which("pamixer"))
    volume = int(run("pamixer", "--get-volume") or "0") if has_pamixer else 0
    muted = run("pamixer", "--get-mute") == "true" if has_pamixer else False
    mic_muted = run("pamixer", "--default-source", "--get-mute") == "true" if has_pamixer else True
    mic_volume = int(run("pamixer", "--default-source", "--get-volume") or "0") if has_pamixer else 0

    # Output devices
    default_sink = run("pactl", "get-default-sink")
    sinks = []
    raw = run("pactl", "-f", "json", "list", "sinks")
    if raw:
        try:
            for s in json.loads(raw):
                sinks.append({
                    "name": s.get("name", ""),
                    "description": s.get("description", s.get("name", "")),
                    "active": s.get("name") == default_sink,
                })
        except (json.JSONDecodeError, TypeError):
            pass
    if not sinks:
        sinks = [{"name": default_sink or "", "description": default_sink or "Unknown", "active": True}]

    # Per-app volumes
    apps = []
    raw = run("pactl", "-f", "json", "list", "sink-inputs")
    if raw:
        try:
            for si in json.loads(raw):
                props = si.get("properties", {})
                name = props.get("application.name", props.get("media.name", "Unknown"))
                vols = si.get("volume", {})
                vol_pct = 0
                if vols:
                    first = next(iter(vols.values()), {})
                    val = first.get("value_percent", "0%")
                    vol_pct = int(str(val).rstrip("%")) if str(val).rstrip("%").isdigit() else 0
                apps.append({
                    "name": name,
                    "volume": vol_pct,
                    "muted": si.get("mute", False),
                    "index": si.get("index", 0),
                })
        except (json.JSONDecodeError, TypeError):
            pass

    # Media
    has_playerctl = bool(shutil.which("playerctl"))
    status = run("playerctl", "status") if has_playerctl else ""
    playing = status == "Playing"
    media_visible = status in {"Playing", "Paused"}
    title = run("playerctl", "metadata", "title") if media_visible else ""
    artist = run("playerctl", "metadata", "artist") if media_visible else ""
    album = run("playerctl", "metadata", "album") if media_visible else ""
    art_url = run("playerctl", "metadata", "mpris:artUrl") if media_visible else ""
    art = resolve_album_art(art_url, artist, album)

    position = 0.0
    length = 0.0
    if media_visible:
        try:
            position = float(run("playerctl", "position") or "0")
        except ValueError:
            pass
        try:
            length = float(run("playerctl", "metadata", "mpris:length") or "0") / 1_000_000
        except ValueError:
            pass
    progress = int(position / length * 100) if length > 0 else 0

    def fmt_time(secs: float) -> str:
        m, s = divmod(int(secs), 60)
        return f"{m}:{s:02d}"

    return {
        "volume": volume,
        "muted": muted,
        "mic_muted": mic_muted,
        "mic_volume": mic_volume,
        "sinks": sinks,
        "apps": apps,
        "media": {
            "visible": media_visible,
            "playing": playing,
            "title": title or "Nothing playing",
            "artist": artist,
            "album": album,
            "art": art,
            "progress": progress,
            "position": fmt_time(position),
            "length": fmt_time(length),
        },
    }


def network() -> dict:
    route = run("ip", "route", "show", "default").split()
    device = route[4] if len(route) > 4 else ""
    address = run("ip", "-4", "-o", "addr", "show", "dev", device).split() if device else []
    ipv4 = address[3].split("/")[0] if len(address) > 3 else ""
    gateway = route[2] if len(route) > 2 and route[0] == "default" and route[1] == "via" else ""

    active_wifi = run("nmcli", "-t", "-f", "ACTIVE,SSID,SIGNAL,SECURITY", "dev", "wifi")
    fields = next((line.split(":", 3) for line in active_wifi.splitlines() if line.startswith("yes:")), [])
    is_wifi = len(fields) == 4
    ssid = fields[1] if is_wifi else ("Ethernet" if device else "")
    signal = int(fields[2]) if is_wifi and fields[2].isdigit() else 0
    security = fields[3] if is_wifi else ""

    received, sent = interface_bytes(device) if device else (0, 0)
    down, up = transfer_rate(device, received, sent) if device else ("Idle", "Idle")

    wifi = {
        "connected": bool(device),
        "ssid": ssid,
        "signal": signal,
        "security": security,
        "ipv4": ipv4,
        "gateway": gateway,
        "down": down,
        "up": up,
        "interface": device or "none",
        "is_wifi": is_wifi,
    }

    mullvad_raw = run("mullvad", "status") if shutil.which("mullvad") else ""
    mullvad_connected = "connected" in mullvad_raw.lower() and "disconnected" not in mullvad_raw.lower()
    mullvad_location = ""
    if mullvad_connected:
        for line in mullvad_raw.splitlines():
            if "relay" in line.lower() or "location" in line.lower() or "in " in line.lower():
                mullvad_location = line.strip()
                break
        if not mullvad_location:
            parts = mullvad_raw.strip().splitlines()
            mullvad_location = parts[-1].strip() if len(parts) > 1 else ""

    mullvad = {
        "installed": bool(shutil.which("mullvad")),
        "connected": mullvad_connected,
        "status": mullvad_raw.splitlines()[0].strip() if mullvad_raw else "Not installed",
        "location": mullvad_location,
    }

    ts_ip = run("tailscale", "ip", "-4") if shutil.which("tailscale") else ""
    ts_connected = bool(ts_ip)
    ts_peers = 0
    if ts_connected:
        ts_status = run("tailscale", "status")
        ts_peers = max(0, sum(1 for line in ts_status.splitlines() if line.strip()) - 1) if ts_status else 0

    tailscale = {
        "installed": bool(shutil.which("tailscale")),
        "connected": ts_connected,
        "ip": ts_ip,
        "peers": ts_peers,
    }

    return {"wifi": wifi, "mullvad": mullvad, "tailscale": tailscale}


def interface_bytes(device: str) -> tuple[int, int]:
    try:
        values = Path("/proc/net/dev").read_text().splitlines()
        line = next(line for line in values if line.strip().startswith(f"{device}:"))
        fields = line.split(":", 1)[1].split()
        return int(fields[0]), int(fields[8])
    except (OSError, StopIteration, ValueError, IndexError):
        return 0, 0


def transfer_rate(device: str, received: int, sent: int) -> tuple[str, str]:
    try:
        prior = json.loads(NETWORK_STATE.read_text())
        down = max(0, received - int(prior["received"])) if prior["device"] == device else 0
        up = max(0, sent - int(prior["sent"])) if prior["device"] == device else 0
    except (OSError, ValueError, KeyError, json.JSONDecodeError):
        down, up = 0, 0
    try:
        NETWORK_STATE.write_text(json.dumps({"device": device, "received": received, "sent": sent}))
    except OSError:
        pass
    return (f"{down / 1024:.0f} KiB/s" if down else "Idle", f"{up / 1024:.0f} KiB/s" if up else "Idle")


def clock() -> dict[str, str]:
    return {"time": run("date", "+%H:%M:%S"), "date": run("date", "+%A, %B %d, %Y"), "timezone": run("date", "+%Z"), "calendar": run("cal") or "Unavailable"}


_FRIENDLY_NAMES: dict[str, str] = {
    "com.anthropic.claude": "Claude",
    "com.anthropic.Claude": "Claude",
    "org.mozilla.firefox": "Firefox",
    "org.mozilla.thunderbird": "Thunderbird",
    "com.google.Chrome": "Chrome",
    "codium": "VSCodium",
    "code": "VS Code",
    "vscodium": "VSCodium",
    "floorp": "Floorp",
    "kitty": "Kitty",
    "alacritty": "Alacritty",
    "wezterm": "WezTerm",
    "foot": "Foot",
    "discord": "Discord",
    "slack": "Slack",
    "telegram-desktop": "Telegram",
    "spotify": "Spotify",
    "steam": "Steam",
    "lutris": "Lutris",
    "thunar": "Thunar",
    "nautilus": "Files",
    "dolphin": "Dolphin",
    "pavucontrol": "PulseAudio",
    "blueman-manager": "Bluetooth",
    "nm-connection-editor": "Network",
    "obs": "OBS Studio",
    "gimp": "GIMP",
    "inkscape": "Inkscape",
    "libreoffice-writer": "Writer",
    "libreoffice-calc": "Calc",
    "libreoffice-impress": "Impress",
    "vlc": "VLC",
    "mpv": "mpv",
    "zathura": "Zathura",
    "evince": "Evince",
    "eog": "Eye of GNOME",
    "feh": "feh",
    "imv": "imv",
    "btop": "btop",
    "htop": "htop",
}

_NERD_ICONS: dict[str, str] = {
    "firefox": "", "floorp": "", "chromium": "", "google-chrome": "", "brave": "",
    "kitty": "", "alacritty": "", "wezterm": "", "foot": "", "xterm": "",
    "code": "", "codium": "", "vscodium": "", "jetbrains": "",
    "discord": "󰙯", "slack": "󰒱", "telegram-desktop": "", "signal": "󰭹",
    "spotify": "", "deadbeef": "󰎈", "ncmpcpp": "󰎈",
    "thunar": "", "nautilus": "", "dolphin": "", "nemo": "", "pcmanfm": "",
    "steam": "󰓓", "lutris": "󰊗", "heroic": "󰊗",
    "vlc": "󰕼", "mpv": "󰐹",
    "gimp": "", "inkscape": "", "krita": "",
    "obs": "󰑋",
    "zathura": "", "evince": "", "okular": "",
    "pavucontrol": "󰕾", "blueman-manager": "󰂯", "nm-connection-editor": "󰤨",
    "htop": "󰍛", "btop": "󰍛",
    "feh": "", "imv": "", "eog": "",
    "com.anthropic.claude": "󰚩", "com.anthropic.Claude": "󰚩",
}

_ICON_CACHE: dict[str, str] = {}


def _resolve_icon(app_class: str) -> str:
    if app_class in _ICON_CACHE:
        return _ICON_CACHE[app_class]
    icon_name = ""
    desktop_names = [app_class, app_class.lower(), f"vs{app_class.lower()}", f"org.mozilla.{app_class.lower()}"]
    for dname in desktop_names:
        desktop_file = Path(f"/usr/share/applications/{dname}.desktop")
        if desktop_file.exists():
            for line in desktop_file.read_text(errors="replace").splitlines():
                if line.startswith("Icon="):
                    icon_name = line[5:].strip()
                    break
            if icon_name:
                break
    if not icon_name:
        icon_name = app_class.lower()
    icon_path = ""
    for size in ["128x128", "256x256", "64x64", "48x48"]:
        for ext in [".png"]:
            candidate = Path(f"/usr/share/icons/hicolor/{size}/apps/{icon_name}{ext}")
            if candidate.exists():
                icon_path = str(candidate)
                break
        if icon_path:
            break
    if not icon_path:
        pixmap = Path(f"/usr/share/pixmaps/{icon_name}.png")
        if pixmap.exists():
            icon_path = str(pixmap)
    _ICON_CACHE[app_class] = icon_path
    return icon_path


def apps() -> dict:
    try:
        clients = json.loads(run("hyprctl", "clients", "-j"))
        active = json.loads(run("hyprctl", "activeworkspace", "-j")).get("id", 0)
    except (json.JSONDecodeError, AttributeError):
        return {"apps": []}
    terminals = {"kitty", "alacritty", "wezterm", "xterm", "foot"}
    result = []
    for item in clients:
        if not item.get("mapped") or item.get("workspace", {}).get("id", -1) <= 0:
            continue
        app_class = str(item.get("class") or "Unknown")
        title = str(item.get("title") or "")
        ws = item.get("workspace", {}).get("id", 0)
        friendly = _FRIENDLY_NAMES.get(app_class, app_class)
        icon = _resolve_icon(app_class)
        glyph = _NERD_ICONS.get(app_class, _NERD_ICONS.get(app_class.lower(), "󰣆"))
        if app_class.lower() in terminals:
            subtitle = title
        else:
            subtitle = title[:50] + "…" if len(title) > 50 else title
        result.append({
            "address": str(item.get("address", "")),
            "name": friendly,
            "subtitle": subtitle,
            "icon": icon,
            "glyph": glyph,
            "workspace": ws,
            "active": ws == active,
        })
    result.sort(key=lambda a: (a["workspace"], a["name"].lower()))
    return {"apps": result}


def main() -> int:
    name = sys.argv[1] if len(sys.argv) == 2 else ""
    payload = {"audio": audio, "network": network, "clock": clock, "apps": apps}.get(name)
    if payload is None:
        return 2
    print(json.dumps(payload(), ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
