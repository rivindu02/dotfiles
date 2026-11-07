#!/usr/bin/env python3
"""Exercise browser routing with isolated settings and fake browser executables."""
import configparser
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time
import unittest
from urllib.parse import quote


ROOT = Path(__file__).resolve().parents[2]
LAUNCHER = ROOT / "scripts/.local/bin/default-browser"
DESKTOP = ROOT / "scripts/.local/share/applications/default-browser.desktop"


class BrowserTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="browser-tests-")
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)
        self.config = self.home / ".config/browser/default"
        self.config.parent.mkdir(parents=True)
        self.bin = self.home / ".local/bin"
        self.bin.mkdir(parents=True)
        (self.bin / "default-browser").symlink_to(LAUNCHER)
        self.log = self.home / "launch.json"
        self.env = dict(
            os.environ,
            HOME=str(self.home),
            XDG_CONFIG_HOME=str(self.home / ".config"),
            XDG_CONFIG_DIRS=str(self.home / "empty-config"),
            XDG_DATA_HOME=str(self.home / ".local/share"),
            XDG_CURRENT_DESKTOP="Hyprland",
            PATH=f"{self.bin}:/usr/bin:/bin",
            BROWSER_LOG=str(self.log),
        )
        # Keep desktop launches isolated when Exec uses an absolute user path.
        self.desktop = self.home / "default-browser.desktop"
        self.desktop.write_text(DESKTOP.read_text().replace(str(Path.home()), str(self.home)))
        for browser in ("qutebrowser", "brave", "firefox", "chromium"):
            stub = self.bin / browser
            stub.write_text(
                '#!/usr/bin/python3\nimport json, os, sys\n'
                'with open(os.environ["BROWSER_LOG"], "w") as f:\n'
                '    json.dump([os.path.basename(sys.argv[0]), *sys.argv[1:]], f)\n'
            )
            stub.chmod(0o755)
        self.select("qutebrowser")

    def select(self, browser):
        self.config.write_text(browser + "\n")

    def run_command(self, *args):
        return subprocess.run(
            args, env=self.env, text=True, capture_output=True, timeout=10
        )

    def launched(self):
        return json.loads(self.log.read_text())

    def test_rereads_selection_and_uses_private_flags(self):
        for browser, normal, private in (
            ("qutebrowser", ["--target", "tab", "--untrusted-args"],
             ["--target", "private-window", "--untrusted-args"]),
            ("brave", ["--new-tab", "--"], ["--incognito", "--"]),
            ("firefox", ["--new-tab", "--"], ["--private-window", "--"]),
            ("chromium", ["--new-tab", "--"], ["--incognito", "--"]),
        ):
            self.select(browser)
            for options, expected in (([], normal), (["--private"], private)):
                with self.subTest(browser=browser, options=options):
                    result = self.run_command(str(LAUNCHER), *options, "https://example.org")
                    self.assertEqual(result.returncode, 0, result.stderr)
                    self.assertEqual(self.launched(), [browser, *expected, "https://example.org"])

    def test_urls_are_separate_untrusted_arguments(self):
        urls = [":quit", "--private", 'https://example.org/?q="a b"&x=$HOME;echo bad',
                str(self.home / "a file.html")]
        result = self.run_command(str(LAUNCHER), "--", *urls)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.launched(), ["qutebrowser", "--target", "tab", "--untrusted-args", *urls])

    def test_selection_can_be_queried_without_launching(self):
        result = self.run_command(str(LAUNCHER), "--print")
        self.assertEqual(result.stdout, "qutebrowser\n")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(self.log.exists())

    def test_invalid_and_missing_config_fail_without_fallback(self):
        for invalid in ("", "default-browser", "qutebrowser --temp-basedir"):
            self.select(invalid)
            result = self.run_command(str(LAUNCHER), "https://example.org")
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("unsupported browser", result.stderr)
            self.assertFalse(self.log.exists())
        self.config.unlink()
        result = self.run_command(str(LAUNCHER))
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("missing config", result.stderr)

    def test_missing_executable_reports_error(self):
        (self.bin / "qutebrowser").unlink()
        self.env["PATH"] = str(self.bin)
        result = self.run_command("/usr/bin/bash", str(LAUNCHER))
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("executable not found", result.stderr)

    def test_bookmark_shortcut_uses_qutebrowser_without_rofi(self):
        result = self.run_command(str(ROOT / "scripts/.local/bin/bookmark"))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.launched()[-1], "qute://bookmarks/")

    def test_search_launchers_use_selected_browser(self):
        toggle = self.home / ".config/rofi/scripts/toggle.sh"
        toggle.parent.mkdir(parents=True)
        toggle.write_text("rofi_toggle() { return 0; }\n")
        # Exercise the shared suggestion launcher with fake Rofi; no GUI or requests.
        for filename in ("query-suggestions.sh", "search-suggestions.c", "search-suggestions.py"):
            (toggle.parent / filename).symlink_to(ROOT / ".config/rofi/scripts" / filename)
        self.env["XDG_CACHE_HOME"] = str(self.home / "cache")
        rofi = self.bin / "rofi"
        rofi.write_text('#!/bin/sh\nprintf "%s\\n" "$SEARCH_QUERY"\n')
        rofi.chmod(0o755)
        self.env["SEARCH_QUERY"] = "cats & dogs 日本語"
        url = "https://duckduckgo.com/?q=" + quote(self.env["SEARCH_QUERY"])
        for script, target in (("search", "tab"), ("psearch", "private-window")):
            with self.subTest(script=script):
                result = self.run_command(str(ROOT / "scripts/.local/bin" / script))
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(self.launched(), ["qutebrowser", "--target", target, "--untrusted-args", url])

    @unittest.skipUnless(shutil.which("gio"), "GIO is required for desktop integration")
    def test_desktop_entry_preserves_urls_without_local_bin_on_path(self):
        # GUI launchers need not have ~/.local/bin on PATH.
        (self.home / "fake-bin").mkdir()
        (self.home / "fake-bin/qutebrowser").symlink_to(self.bin / "qutebrowser")
        self.env["PATH"] = f"{self.home}/fake-bin:/usr/bin:/bin"
        urls = ['https://example.org/?q="a%20b"&x=$HOME;echo%20bad',
                "file:///tmp/a%20file.html"]
        result = self.run_command("gio", "launch", str(self.desktop), *urls)
        self.assertEqual(result.returncode, 0, result.stderr)
        deadline = time.monotonic() + 3
        while not self.log.exists() and time.monotonic() < deadline:
            time.sleep(0.02)
        self.assertTrue(self.log.exists(), result.stderr)
        # GIO resolves a local file URI into its native path before launching.
        self.assertEqual(self.launched(), ["qutebrowser", "--target", "tab", "--untrusted-args",
                                          urls[0], "/tmp/a file.html"])

    @unittest.skipUnless(shutil.which("xdg-mime"), "xdg-mime is required")
    def test_default_associations_resolve_to_shared_desktop_entry(self):
        applications = self.home / ".local/share/applications"
        applications.mkdir(parents=True)
        (applications / DESKTOP.name).symlink_to(self.desktop)
        shutil.copyfile(ROOT / "system_prefs/.config/mimeapps.list",
                        self.home / ".config/mimeapps.list")
        desktop = configparser.ConfigParser(interpolation=None)
        desktop.read(DESKTOP)
        advertised = desktop["Desktop Entry"]["MimeType"].split(";")
        for mime in ("x-scheme-handler/http", "x-scheme-handler/https", "text/html", "application/pdf"):
            self.assertIn(mime, advertised)
            result = self.run_command("xdg-mime", "query", "default", mime)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(result.stdout.strip(), DESKTOP.name)

    @unittest.skipUnless(shutil.which("xdg-open"), "xdg-open is required")
    def test_xdg_open_launches_from_a_gui_path_without_local_bin(self):
        applications = self.home / ".local/share/applications"
        applications.mkdir(parents=True)
        (applications / DESKTOP.name).symlink_to(self.desktop)
        shutil.copyfile(ROOT / "system_prefs/.config/mimeapps.list",
                        self.home / ".config/mimeapps.list")
        (self.home / "fake-bin").mkdir()
        (self.home / "fake-bin/qutebrowser").symlink_to(self.bin / "qutebrowser")
        self.env["PATH"] = f"{self.home}/fake-bin:/usr/bin:/bin"
        self.env["DISPLAY"] = ":test"
        self.env.pop("BROWSER", None)
        url = 'https://example.org/?q="a%20b"&x=$HOME;echo%20bad'
        result = self.run_command("xdg-open", url)
        self.assertEqual(result.returncode, 0, result.stderr)
        # xdg-open can report success even when Exec failed to start a browser.
        self.assertTrue(self.log.exists(), result.stderr)
        self.assertEqual(self.launched(), ["qutebrowser", "--target", "tab", "--untrusted-args", url])


if __name__ == "__main__":
    unittest.main()
