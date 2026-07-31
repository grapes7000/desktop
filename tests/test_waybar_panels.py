from __future__ import annotations

import importlib.util
import json
import os
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PANEL_DIR = ROOT / "eww" / "waybar-panels"
SCRIPTS_DIR = PANEL_DIR / "scripts"
HELPER = ROOT / "bin" / "waybar-panel"


def load_module(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


def balanced_yuck(text: str) -> bool:
    depth = 0
    quoted = False
    escaped = False
    for character in text:
        if escaped:
            escaped = False
        elif character == "\\" and quoted:
            escaped = True
        elif character == '"':
            quoted = not quoted
        elif not quoted and character == "(":
            depth += 1
        elif not quoted and character == ")":
            depth -= 1
            if depth < 0:
                return False
    return depth == 0 and not quoted


def test_theme_css_generates_semantic_scss(tmp_path: Path) -> None:
    theme = tmp_path / "theme.css"
    theme.write_text("@define-color bg #101010;\n@define-color accent #aabbcc;\n")
    module = load_module("generate_eww_theme", SCRIPTS_DIR / "generate-theme.py")

    output = module.generate_scss(theme)

    assert "$bg: #101010;" in output
    assert "$accent: #aabbcc;" in output
    assert "$text: #d8dee9;" in output


def test_missing_semantic_roles_use_fallbacks(tmp_path: Path) -> None:
    theme = tmp_path / "theme.css"
    theme.write_text("@define-color bg #101010;\n")
    module = load_module("generate_eww_theme_fallback", SCRIPTS_DIR / "generate-theme.py")

    output = module.generate_scss(theme)

    assert "$bg: #101010;" in output
    assert "$urgent: #f38ba8;" in output


def test_system_stats_json_schema_and_ranges() -> None:
    result = subprocess.run(
        [sys.executable, str(SCRIPTS_DIR / "system-stats.py")],
        check=True,
        capture_output=True,
        text=True,
    )

    data = json.loads(result.stdout)

    assert {"cpu", "memory", "disk", "temperature", "uptime", "load", "processes", "network", "battery"} <= set(data)
    for name in ("cpu", "memory", "disk"):
        assert 0 <= data[name]["percent"] <= 100
    assert data["temperature"]["celsius"] >= -1
    assert len(data["processes"]) <= 5


def test_missing_temperature_is_unavailable(monkeypatch) -> None:
    module = load_module("system_stats_missing_temp", SCRIPTS_DIR / "system-stats.py")
    monkeypatch.setattr(module, "THERMAL_ROOT", Path("/definitely/missing"))

    assert module.read_temperature() == {"celsius": -1}


def test_yuck_is_balanced_and_uses_two_second_polling() -> None:
    yuck = (PANEL_DIR / "eww.yuck").read_text()

    assert balanced_yuck(yuck)
    assert ":interval \"2s\"" in yuck
    assert "system-monitor" in yuck


def test_helper_rejects_unknown_panels_and_supports_dev_override(tmp_path: Path) -> None:
    config = tmp_path / "panels"
    config.mkdir()
    env = dict(os.environ, EWW_PANEL_CONFIG_DIR=str(config))

    result = subprocess.run([str(HELPER), "unknown", "toggle"], env=env, capture_output=True, text=True)

    assert result.returncode == 2
    assert "unknown panel" in result.stderr
    assert "EWW_PANEL_CONFIG_DIR" in HELPER.read_text()


def test_helper_never_targets_unrelated_eww_processes() -> None:
    source = HELPER.read_text()

    assert "cmdline_matches_config" in source
    assert "/proc/$pid/cmdline" in source
    assert "pkill" not in source
    assert "killall" not in source
    assert "stop_daemon" in source
    assert "close_all" in source


def test_missing_btop_reports_unavailable(tmp_path: Path) -> None:
    env = dict(os.environ, PATH="/usr/bin:/bin")

    result = subprocess.run([str(HELPER), "system", "btop"], env=env, capture_output=True, text=True)

    assert result.returncode != 0
    assert "btop is unavailable" in result.stderr


def test_open_closes_previously_tracked_panel() -> None:
    source = HELPER.read_text()

    assert 'start_daemon; close_all; eww open "$window_name"' in source


def test_no_shell_true_in_panel_scripts() -> None:
    assert "shell=True" not in "".join(path.read_text() for path in SCRIPTS_DIR.glob("*.py"))


def test_theme_watcher_reloads_the_dedicated_config() -> None:
    source = (SCRIPTS_DIR / "theme-watch.py").read_text()

    assert '"eww", "reload", "--config", str(config_dir)' in source
