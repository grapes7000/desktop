#!/usr/bin/env python3
import json, os
from pathlib import Path

def cpu_sample():
    fields = [int(value) for value in Path("/proc/stat").read_text().splitlines()[0].split()[1:]]
    idle = fields[3] + (fields[4] if len(fields) > 4 else 0)
    return idle, sum(fields)

state = Path(os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")) / "theme-homepage-cpu.json"
idle, total = cpu_sample()
cpu = 0
try:
    previous = json.loads(state.read_text())
    delta_total = total - int(previous["total"])
    delta_idle = idle - int(previous["idle"])
    if delta_total > 0:
        cpu = max(0, min(100, round(100 * (delta_total - delta_idle) / delta_total)))
except (OSError, ValueError, KeyError, TypeError, json.JSONDecodeError):
    pass
state.parent.mkdir(parents=True, exist_ok=True)
tmp = state.with_suffix(".tmp")
tmp.write_text(json.dumps({"idle": idle, "total": total}))
os.replace(tmp, state)
mem = {}
for line in Path("/proc/meminfo").read_text().splitlines():
    key, value = line.split(":", 1)
    mem[key] = int(value.split()[0])
used_kb = mem["MemTotal"] - mem.get("MemAvailable", mem.get("MemFree", 0))
used = used_kb / 1048576
total_gb = mem["MemTotal"] / 1048576
mem_percent = round(100 * used_kb / mem["MemTotal"]) if mem["MemTotal"] else 0
stat = os.statvfs("/")
disk = round(100 * (1 - stat.f_bavail / stat.f_blocks)) if stat.f_blocks else 0
seconds = int(float(Path("/proc/uptime").read_text().split()[0]))
days, remainder = divmod(seconds, 86400)
hours, remainder = divmod(remainder, 3600)
minutes = remainder // 60
uptime = f"{days}d {hours}h" if days else f"{hours}h {minutes}m"
print(json.dumps({
    "cpu": cpu,
    "mem": f"{used:.1f}/{total_gb:.0f}G",
    "mem_percent": max(0, min(100, mem_percent)),
    "disk": max(0, min(100, disk)),
    "uptime": uptime,
}))
