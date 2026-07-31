"""Tests for waybar sysstat module."""
import importlib.util
import importlib.machinery
import json
import os
import sys
import tempfile
import pytest

SCRIPT_PATH = os.path.join(
    os.path.dirname(__file__), "..", "waybar", "scripts", "sysstat.py"
)
spec = importlib.util.spec_from_file_location("sysstat", SCRIPT_PATH)
sysstat = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sysstat)


class TestReadMemory:
    def test_parses_meminfo(self, tmp_path):
        meminfo = tmp_path / "meminfo"
        meminfo.write_text(
            "MemTotal:       16384000 kB\n"
            "MemFree:         4096000 kB\n"
            "MemAvailable:    8192000 kB\n"
        )
        original = sysstat.__builtins__ if hasattr(sysstat, '__builtins__') else {}
        import builtins
        real_open = builtins.open

        def mock_open(path, *a, **kw):
            if path == "/proc/meminfo":
                return real_open(str(meminfo), *a, **kw)
            return real_open(path, *a, **kw)

        builtins.open = mock_open
        try:
            result = sysstat.read_memory()
        finally:
            builtins.open = real_open

        assert result is not None
        pct, used, total = result
        assert 0 <= pct <= 100
        assert total > 0


class TestReadDisk:
    def test_reads_root_disk(self):
        result = sysstat.read_disk()
        assert result is not None
        pct, used, total = result
        assert 0 <= pct <= 100
        assert total > 0


class TestReadUptime:
    def test_reads_uptime(self):
        result = sysstat.read_uptime()
        assert result is not None
        assert "m" in result


class TestReadTemp:
    def test_handles_missing_temp(self):
        result = sysstat.read_temp()
        # May or may not be available; should not crash
        assert result is None or isinstance(result, int)


class TestMainOutput:
    def test_outputs_valid_json(self, capsys):
        sysstat.main()
        captured = capsys.readouterr()
        data = json.loads(captured.out)
        assert "text" in data
        assert "tooltip" in data
        assert "class" in data
        assert isinstance(data["class"], list)
        assert len(data["class"]) > 0
