#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import subprocess
from pathlib import Path

THERMAL_ROOT = Path("/sys/class/thermal")


def runtime_state(name: str) -> Path:
    root = Path(os.environ["XDG_RUNTIME_DIR"]) if os.environ.get("XDG_RUNTIME_DIR") else Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state")) / "waybar-panels"
    try:
        root.mkdir(parents=True, exist_ok=True, mode=0o700)
        root.chmod(0o700)
    except OSError:
        pass
    return root / name


CPU_STATE = runtime_state("cpu.json")
NET_STATE = runtime_state("net.json")


def bounded_percent(value: float) -> int:
    return max(0, min(100, round(value)))


def cpu_percent() -> int:
    try:
        fields = [int(value) for value in Path("/proc/stat").read_text().splitlines()[0].split()[1:]]
        idle, total = fields[3] + (fields[4] if len(fields) > 4 else 0), sum(fields)
        previous = json.loads(CPU_STATE.read_text())
        delta_total, delta_idle = total - int(previous["total"]), idle - int(previous["idle"])
        percent = bounded_percent(100 * (delta_total - delta_idle) / delta_total) if delta_total > 0 else 0
    except (OSError, ValueError, IndexError, KeyError, json.JSONDecodeError, ZeroDivisionError):
        percent, idle, total = 0, 0, 0
    try:
        CPU_STATE.parent.mkdir(parents=True, exist_ok=True)
        CPU_STATE.write_text(json.dumps({"idle": idle, "total": total}))
    except OSError:
        pass
    return percent


def memory() -> dict[str, int | str]:
    values: dict[str, int] = {}
    try:
        for line in Path("/proc/meminfo").read_text().splitlines():
            key, raw = line.split(":", 1)
            values[key] = int(raw.split()[0])
        total, used = values["MemTotal"], values["MemTotal"] - values.get("MemAvailable", values.get("MemFree", 0))
        return {"percent": bounded_percent(100 * used / total), "detail": f"{used / 1048576:.1f}/{total / 1048576:.1f} GiB"}
    except (OSError, ValueError, KeyError, IndexError, ZeroDivisionError):
        return {"percent": 0, "detail": "unavailable"}


def disk() -> dict[str, int | str]:
    try:
        stats = os.statvfs("/")
        total, used = stats.f_blocks * stats.f_frsize, (stats.f_blocks - stats.f_bavail) * stats.f_frsize
        return {"percent": bounded_percent(100 * used / total), "detail": f"{used / 1073741824:.1f}/{total / 1073741824:.1f} GiB"}
    except (OSError, ZeroDivisionError):
        return {"percent": 0, "detail": "unavailable"}


def read_temperature() -> dict[str, int]:
    try:
        for path in sorted(THERMAL_ROOT.glob("thermal_zone*/temp")):
            celsius = int(path.read_text().strip()) // 1000
            if 0 <= celsius <= 150:
                return {"celsius": celsius}
    except (OSError, ValueError):
        return {"celsius": -1}
    return {"celsius": -1}


def uptime() -> str:
    try:
        seconds = int(float(Path("/proc/uptime").read_text().split()[0]))
        days, remainder = divmod(seconds, 86400)
        hours, remainder = divmod(remainder, 3600)
        return f"{days}d {hours}h" if days else f"{hours}h {remainder // 60}m"
    except (OSError, ValueError, IndexError):
        return "unavailable"


def load_average() -> str:
    try:
        return Path("/proc/loadavg").read_text().split()[0]
    except (OSError, IndexError):
        return "unavailable"


def processes() -> list[dict[str, str]]:
    try:
        result = subprocess.run(["ps", "-eo", "pid=,comm=,%cpu=,%mem=", "--sort=-%cpu"], check=False, capture_output=True, text=True, timeout=2)
    except (OSError, subprocess.TimeoutExpired):
        return []
    rows: list[dict[str, str]] = []
    for line in result.stdout.splitlines():
        parts = line.split(None, 3)
        if len(parts) == 4 and parts[0].isdigit():
            rows.append({"pid": parts[0], "name": parts[1], "cpu": parts[2], "memory": parts[3]})
        if len(rows) == 5:
            break
    return rows


def network_rate() -> dict[str, str]:
    try:
        lines = Path("/proc/net/dev").read_text().splitlines()[2:]
        received, sent = (sum(int(line.split(":", 1)[1].split()[index]) for line in lines if ":" in line) for index in (0, 8))
        previous = json.loads(NET_STATE.read_text())
        down, up = max(0, received - int(previous["received"])), max(0, sent - int(previous["sent"]))
    except (OSError, ValueError, KeyError, json.JSONDecodeError, IndexError):
        received, sent, down, up = 0, 0, 0, 0
    try:
        NET_STATE.write_text(json.dumps({"received": received, "sent": sent}))
    except OSError:
        pass
    return {"down": f"{down / 1024:.0f} KiB/s", "up": f"{up / 1024:.0f} KiB/s"}


def battery() -> dict[str, str] | None:
    for path in Path("/sys/class/power_supply").glob("BAT*"):
        try:
            return {"percent": path.joinpath("capacity").read_text().strip(), "status": path.joinpath("status").read_text().strip()}
        except OSError:
            continue
    return None


def main() -> int:
    payload = {"cpu": {"percent": cpu_percent()}, "memory": memory(), "disk": disk(), "temperature": read_temperature(), "uptime": uptime(), "load": load_average(), "processes": processes(), "network": network_rate(), "battery": battery()}
    print(json.dumps(payload, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
