"""Tests for the keybind documentation generator."""
import importlib.util
import importlib.machinery
import json
import os
import sys
import tempfile
import pytest

SCRIPT_PATH = os.path.join(
    os.path.dirname(__file__), "..", "bin", "generate-keybinds"
)
spec = importlib.util.spec_from_loader(
    "generate_keybinds",
    importlib.machinery.SourceFileLoader("generate_keybinds", SCRIPT_PATH),
)
gen = importlib.util.module_from_spec(spec)
spec.loader.exec_module(gen)

KEYBINDS_CONF = os.path.join(
    os.path.dirname(__file__), "..", "hypr", "conf", "keybinds.conf"
)


class TestParseKeybinds:
    def test_parses_real_config(self):
        entries, duplicates = gen.parse_keybinds(KEYBINDS_CONF)
        assert len(entries) > 30

    def test_entries_have_required_fields(self):
        entries, _ = gen.parse_keybinds(KEYBINDS_CONF)
        for e in entries:
            assert "section" in e
            assert "shortcut" in e
            assert "description" in e
            assert "bind_type" in e

    def test_detects_bind_types(self):
        entries, _ = gen.parse_keybinds(KEYBINDS_CONF)
        types = {e["bind_type"] for e in entries}
        assert "bind" in types

    def test_resolves_variables(self):
        entries, _ = gen.parse_keybinds(KEYBINDS_CONF)
        shortcuts = [e["shortcut"] for e in entries]
        for s in shortcuts:
            assert "$mod" not in s
            assert "$term" not in s

    def test_detects_wofi_submap_duplicates(self):
        entries, duplicates = gen.parse_keybinds(KEYBINDS_CONF)
        assert len(duplicates) > 0

    def test_handles_bindel(self):
        with tempfile.NamedTemporaryFile(mode="w", suffix=".conf", delete=False) as f:
            f.write("bindel = , XF86AudioRaiseVolume, exec, pamixer -i 5\n")
            f.flush()
            entries, _ = gen.parse_keybinds(f.name)
        os.unlink(f.name)
        assert len(entries) == 1
        assert entries[0]["bind_type"] == "bindel"

    def test_handles_bindm(self):
        with tempfile.NamedTemporaryFile(mode="w", suffix=".conf", delete=False) as f:
            f.write("bindm = $mod, mouse:272, movewindow\n")
            f.flush()
            entries, _ = gen.parse_keybinds(f.name)
        os.unlink(f.name)
        assert len(entries) == 1
        assert "LMB" in entries[0]["shortcut"]


class TestGenerateMarkdown:
    def test_generates_markdown(self, tmp_path):
        entries = [
            {"section": "Test", "bind_type": "bind",
             "shortcut": "Super+A", "description": "Do something"}
        ]
        md_path = str(tmp_path / "KEYBINDS.md")
        gen.generate_markdown(entries, [], md_path)
        content = open(md_path).read()
        assert "# Keybind Reference" in content
        assert "Super+A" in content
        assert "Do something" in content


class TestGenerateTsv:
    def test_generates_tsv(self, tmp_path):
        entries = [
            {"section": "Test", "bind_type": "bind",
             "shortcut": "Super+B", "description": "Another action"}
        ]
        tsv_path = str(tmp_path / "keybinds.tsv")
        gen.generate_tsv(entries, tsv_path)
        content = open(tsv_path).read()
        assert "Super+B\tAnother action\tTest" in content
