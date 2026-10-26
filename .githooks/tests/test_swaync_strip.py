#!/usr/bin/env python3
"""Exercise the privacy filter using synthetic data and isolated Git indexes."""

import copy
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


FILTER = Path(__file__).resolve().parents[1] / "swaync-strip.py"
PRIVATE = "SYNTHETIC_PRIVATE_CALENDAR_TEXT"
CONFIG_PATH = ".config/swaync/config.json"


def fixture():
    return {
        "widgets": ["title", "label#gcal-today-timed", "notifications"],
        "widget-config": {
            "title": {"text": "Keep this title"},
            "label#weather": {"text": PRIVATE, "max-lines": 2},
            "label#gcal-header": {"text": PRIVATE},
            "label#gcal-today-timed": {"text": PRIVATE, "max-lines": 30},
            "label#gcal-custom": {"text": PRIVATE},
            "notifications": {"visible": True},
        },
        "custom-setting": {"message": "Keep Unicode: ☀ café", "enabled": True},
    }


def run_filter(raw):
    return subprocess.run(
        [sys.executable, str(FILTER)], input=raw, capture_output=True
    )


class FilterTests(unittest.TestCase):
    def test_valid_input_preserves_static_settings_and_removes_generated_text(self):
        source = fixture()
        result = run_filter(json.dumps(source).encode())
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stderr, b"")
        self.assertNotIn(PRIVATE.encode(), result.stdout)
        cleaned = json.loads(result.stdout)
        expected = copy.deepcopy(source)
        for name, settings in expected["widget-config"].items():
            if name.startswith("label#gcal-") or name == "label#weather":
                settings["text"] = ""
        expected["widgets"] = [
            "title", "label#weather", "label#gcal-header",
            "label#gcal-today-timed", "notifications",
        ]
        self.assertEqual(cleaned, expected)

    def test_filter_is_idempotent(self):
        first = run_filter(json.dumps(fixture()).encode())
        second = run_filter(first.stdout)
        self.assertEqual(second.returncode, 0, second.stderr)
        self.assertEqual(second.stdout, first.stdout)

    def test_optional_widget_fields_can_be_absent(self):
        for config in ({}, {"widgets": []}, {"widget-config": {}}):
            with self.subTest(config=config):
                result = run_filter(json.dumps(config).encode())
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(json.loads(result.stdout), config)

    def test_malformed_inputs_fail_without_disclosing_content(self):
        invalid = [
            b"", b"{", ('{"private": "' + PRIVATE + '"').encode(),
            json.dumps(fixture()).encode() + b" trailing data",
            ('{"private": "' + PRIVATE + '\xff"}').encode("latin-1"),
            b'{"private": NaN}', b'{"private": Infinity}',
            b'{"private": -Infinity}',
            b'{"private": 1e9999}', b'{"private": "\\ud800"}',
            b"[" * 2000,
        ]
        for raw in invalid:
            with self.subTest(raw=raw):
                result = run_filter(raw)
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(result.stdout, b"")
                self.assertIn(b"refusing", result.stderr)
                self.assertNotIn(PRIVATE.encode(), result.stderr)
                self.assertNotIn(b"Traceback", result.stderr)

    def test_unsupported_structures_fail_without_disclosing_content(self):
        invalid = [
            None, [], PRIVATE,
            {"widget-config": PRIVATE}, {"widget-config": None},
            {"widget-config": []}, {"widgets": PRIVATE},
            {"widgets": [PRIVATE, {}]},
            {"widget-config": {"label#weather": PRIVATE}},
            {"widget-config": {"label#gcal-today-timed": PRIVATE}},
        ]
        for config in invalid:
            with self.subTest(config=config):
                result = run_filter(json.dumps(config).encode())
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(result.stdout, b"")
                self.assertNotIn(PRIVATE.encode(), result.stderr)
                self.assertNotIn(b"Traceback", result.stderr)


class GitIntegrationTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="swaync-filter-test-")
        self.addCleanup(self.temporary.cleanup)
        self.repo = Path(self.temporary.name)
        self.env = {k: v for k, v in os.environ.items() if not k.startswith("GIT_")}
        self.env.update(GIT_CONFIG_NOSYSTEM="1", GIT_CONFIG_GLOBAL=os.devnull)
        self.git("init", "--quiet")
        (self.repo / ".githooks").mkdir()
        shutil.copy2(FILTER, self.repo / ".githooks/swaync-strip.py")
        (self.repo / ".gitattributes").write_text(
            f"{CONFIG_PATH} filter=swaync-strip\n", encoding="utf-8"
        )
        self.git("config", "filter.swaync-strip.clean", "python3 .githooks/swaync-strip.py")
        self.git("config", "filter.swaync-strip.smudge", "cat")
        self.git("config", "filter.swaync-strip.required", "true")
        self.config = self.repo / CONFIG_PATH
        self.config.parent.mkdir(parents=True)

    def git(self, *args, check=True):
        return subprocess.run(
            ["git", *args], cwd=self.repo, env=self.env,
            capture_output=True, check=check,
        )

    def test_valid_staging_removes_private_text_without_changing_working_file(self):
        raw = json.dumps(fixture()).encode()
        self.config.write_bytes(raw)
        self.git("add", "--", CONFIG_PATH)
        staged = self.git("show", f":{CONFIG_PATH}").stdout
        self.assertNotIn(PRIVATE.encode(), staged)
        self.assertEqual(json.loads(staged)["custom-setting"], fixture()["custom-setting"])
        self.assertEqual(self.config.read_bytes(), raw)

    def test_malformed_input_cannot_enter_an_empty_index(self):
        raw = ('{"private": "' + PRIVATE + '"').encode()
        self.config.write_bytes(raw)
        result = self.git("add", "--", CONFIG_PATH, check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn(PRIVATE.encode(), result.stdout + result.stderr)
        self.assertEqual(self.git("ls-files", "--", CONFIG_PATH).stdout, b"")
        self.assertEqual(self.config.read_bytes(), raw)

    def test_failed_staging_preserves_the_previous_sanitized_index(self):
        self.config.write_text(json.dumps(fixture()), encoding="utf-8")
        self.git("add", "--", CONFIG_PATH)
        before = self.git("show", f":{CONFIG_PATH}").stdout
        raw = ('{"private": "' + PRIVATE + '"').encode()
        self.config.write_bytes(raw)
        result = self.git("add", "--", CONFIG_PATH, check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.git("show", f":{CONFIG_PATH}").stdout, before)
        self.assertEqual(self.config.read_bytes(), raw)


if __name__ == "__main__":
    unittest.main(verbosity=2)
