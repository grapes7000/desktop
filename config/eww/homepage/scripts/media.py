#!/usr/bin/env python3
import hashlib
import json
import os
import shutil
import subprocess
import tempfile
from pathlib import Path
from urllib.parse import unquote, urlparse
from urllib.request import Request, urlopen

MAX_ART_BYTES = 8 * 1024 * 1024
CACHE = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "theme-homepage" / "album-art"

def run(*args):
    try:
        return subprocess.run(args, check=False, capture_output=True, text=True, timeout=2).stdout.strip()
    except (OSError, subprocess.TimeoutExpired):
        return ""

def cached_remote_art(url):
    CACHE.mkdir(parents=True, exist_ok=True)
    digest = hashlib.sha256(url.encode("utf-8", errors="replace")).hexdigest()[:24]
    existing = next(CACHE.glob(digest + ".*"), None)
    if existing and existing.is_file():
        return str(existing)
    try:
        request = Request(url, headers={"User-Agent": "theme-homepage/1.0"})
        with urlopen(request, timeout=3) as response:
            data = response.read(MAX_ART_BYTES + 1)
            content_type = response.headers.get_content_type()
        if not data or len(data) > MAX_ART_BYTES:
            return ""
        suffixes = {
            "image/jpeg": ".jpg", "image/png": ".png", "image/webp": ".webp",
            "image/gif": ".gif", "image/svg+xml": ".svg",
        }
        suffix = suffixes.get(content_type)
        if suffix is None:
            candidate = Path(urlparse(url).path).suffix.lower()
            suffix = candidate if candidate in {".jpg", ".jpeg", ".png", ".webp", ".gif", ".svg"} else ".img"
        target = CACHE / f"{digest}{suffix}"
        fd, temp_name = tempfile.mkstemp(prefix=digest + ".", suffix=suffix, dir=CACHE)
        try:
            with os.fdopen(fd, "wb") as handle:
                handle.write(data)
            os.replace(temp_name, target)
        except BaseException:
            try:
                os.unlink(temp_name)
            except OSError:
                pass
            raise
        return str(target)
    except (OSError, ValueError, TimeoutError):
        return ""

def resolve_art(raw):
    if not raw:
        return ""
    parsed = urlparse(raw)
    if parsed.scheme == "file" and parsed.netloc in {"", "localhost"}:
        path = Path(unquote(parsed.path))
        return str(path) if path.is_file() else ""
    if parsed.scheme in {"http", "https"}:
        return cached_remote_art(raw)
    path = Path(raw).expanduser()
    return str(path) if path.is_file() else ""

empty = {
    "visible": False, "playing": False, "status": "", "status_label": "",
    "title": "", "artist": "", "album": "", "art": "",
}
if not shutil.which("playerctl"):
    print(json.dumps(empty))
    raise SystemExit
status = run("playerctl", "status")
visible = status in {"Playing", "Paused"}
if not visible:
    print(json.dumps(empty))
    raise SystemExit
print(json.dumps({
    "visible": True,
    "playing": status == "Playing",
    "status": status,
    "status_label": "NOW PLAYING" if status == "Playing" else "PAUSED",
    "title": run("playerctl", "metadata", "title") or "Unknown title",
    "artist": run("playerctl", "metadata", "artist") or "Unknown artist",
    "album": run("playerctl", "metadata", "album"),
    "art": resolve_art(run("playerctl", "metadata", "mpris:artUrl")),
}))
