#!/usr/bin/env python3
"""Compact system monitor for Waybar custom module.

Reads CPU, memory, disk, uptime from /proc and os.statvfs.
Outputs JSON: {"text": "...", "tooltip": "...", "class": ["..."]}
"""
import json
import os
import sys
import time

RUNTIME_DIR = os.environ.get("XDG_RUNTIME_DIR", "/tmp")
CPU_STATE = os.path.join(RUNTIME_DIR, "sysstat-cpu.json")

WARN_CPU = 75
CRIT_CPU = 90
WARN_MEM = 75
CRIT_MEM = 90
WARN_DISK = 85


def read_cpu():
    try:
        with open("/proc/stat") as f:
            parts = f.readline().split()
        idle = int(parts[4])
        total = sum(int(x) for x in parts[1:])
    except (OSError, IndexError, ValueError):
        return None

    prev_idle, prev_total = 0, 0
    try:
        with open(CPU_STATE) as f:
            prev = json.load(f)
            prev_idle, prev_total = prev["idle"], prev["total"]
    except (OSError, json.JSONDecodeError, KeyError):
        pass

    try:
        with open(CPU_STATE, "w") as f:
            json.dump({"idle": idle, "total": total}, f)
    except OSError:
        pass

    d_total = total - prev_total
    d_idle = idle - prev_idle
    if d_total <= 0:
        return None
    return round((1 - d_idle / d_total) * 100)


def read_memory():
    try:
        info = {}
        with open("/proc/meminfo") as f:
            for line in f:
                parts = line.split()
                if parts[0] in ("MemTotal:", "MemAvailable:"):
                    info[parts[0]] = int(parts[1])
        total_kb = info["MemTotal:"]
        avail_kb = info["MemAvailable:"]
        used_kb = total_kb - avail_kb
        pct = round(used_kb / total_kb * 100)
        used_gib = round(used_kb / 1048576, 1)
        total_gib = round(total_kb / 1048576, 1)
        return pct, used_gib, total_gib
    except (OSError, KeyError, ZeroDivisionError):
        return None


def read_disk():
    try:
        st = os.statvfs("/")
        total = st.f_blocks * st.f_frsize
        free = st.f_bavail * st.f_frsize
        used = total - free
        pct = round(used / total * 100)
        used_gib = round(used / (1024 ** 3), 1)
        total_gib = round(total / (1024 ** 3), 1)
        return pct, used_gib, total_gib
    except (OSError, ZeroDivisionError):
        return None


def read_uptime():
    try:
        with open("/proc/uptime") as f:
            secs = int(float(f.read().split()[0]))
        hours = secs // 3600
        mins = (secs % 3600) // 60
        if hours > 0:
            return f"{hours}h {mins}m"
        return f"{mins}m"
    except (OSError, ValueError, IndexError):
        return None


def read_load():
    try:
        with open("/proc/loadavg") as f:
            return f.read().split()[0]
    except (OSError, IndexError):
        return None


def read_temp():
    try:
        for base in ("/sys/class/thermal",):
            for d in sorted(os.listdir(base)):
                path = os.path.join(base, d, "temp")
                if os.path.exists(path):
                    with open(path) as f:
                        val = int(f.read().strip())
                    if 1000 <= val <= 150000:
                        return val // 1000
    except (OSError, ValueError):
        pass
    return None


def main():
    cpu = read_cpu()
    mem = read_memory()
    disk = read_disk()
    uptime = read_uptime()
    load_avg = read_load()
    temp = read_temp()

    text_parts = []
    tooltip_parts = []
    classes = []

    if cpu is not None:
        text_parts.append(f"󰻠 {cpu}%")
        tooltip_parts.append(f"CPU {cpu}%")
        if cpu >= CRIT_CPU:
            classes.append("critical")
        elif cpu >= WARN_CPU:
            classes.append("warning")
    if mem is not None:
        pct, used, total = mem
        text_parts.append(f"󰘚 {pct}%")
        tooltip_parts.append(f"Memory {used}/{total} GiB")
        if pct >= CRIT_MEM:
            classes.append("critical")
        elif pct >= WARN_MEM:
            classes.append("warning")
    if disk is not None:
        pct, used, total = disk
        tooltip_parts.append(f"Disk {pct}% ({used}/{total} GiB)")
        if pct >= WARN_DISK:
            classes.append("warning")
    if load_avg is not None:
        tooltip_parts.append(f"Load {load_avg}")
    if uptime is not None:
        tooltip_parts.append(f"Uptime {uptime}")
    if temp is not None:
        tooltip_parts.append(f"Temp {temp}°C")

    if not classes:
        classes.append("normal")

    output = {
        "text": "  ".join(text_parts) if text_parts else "…",
        "tooltip": "\n".join(tooltip_parts),
        "class": classes,
    }
    json.dump(output, sys.stdout)
    sys.stdout.write("\n")


if __name__ == "__main__":
    main()
