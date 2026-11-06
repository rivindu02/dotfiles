"""Check isolated app launches without opening a real browser."""
import ast
import configparser
import json
import os
from pathlib import Path
import runpy
import shlex
import subprocess
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import Mock

ROOT = Path(__file__).resolve().parents[2]
LAUNCHER = ROOT / "scripts/.local/bin/qute-webapp"


class WebAppTests(unittest.TestCase):
    def test_launcher_isolates_apps_and_protects_url_arguments(self):
        with tempfile.TemporaryDirectory(prefix="qute-app-test-") as folder:
            scratch = Path(folder)
            browser = scratch / "qutebrowser"
            browser.write_text(
                '#!/usr/bin/python3\nimport json, os, sys\n'
                'with open(os.environ["APP_LOG"], "w") as f:\n'
                '    json.dump(sys.argv[1:], f)\n'
            )
            browser.chmod(0o755)
            log = scratch / "args.json"
            env = dict(os.environ, PATH=f"{scratch}:/usr/bin:/bin",
                       XDG_DATA_HOME=str(scratch / "data"), APP_LOG=str(log))
            urls = ["https://web.whatsapp.com/", ":quit", "--temp-basedir"]
            for _ in range(2):
                subprocess.run([str(LAUNCHER), *urls], env=env, check=True)
                args = json.loads(log.read_text())
                self.assertEqual(args, [
                    "--basedir", str(scratch / "data/qutebrowser-webapps"),
                    "--config-py", str(ROOT / ".config/qutebrowser/webapp.py"),
                    "--desktop-file-name", "org.qutebrowser.webapps",
                    "--override-restore", "--target", "window",
                    "--untrusted-args", *urls,
                ])
            scripts = scratch / "data/qutebrowser-webapps/config/greasemonkey"
            self.assertEqual(scripts.resolve(), ROOT / ".config/qutebrowser/greasemonkey")

    def test_app_config_hides_chrome_and_prevents_restoration(self):
        c = SimpleNamespace(tabs=SimpleNamespace(), statusbar=SimpleNamespace(),
                            auto_save=SimpleNamespace(), session=SimpleNamespace())
        config = Mock()
        path = ROOT / ".config/qutebrowser/webapp.py"
        runpy.run_path(str(path), init_globals={"c": c, "config": config})
        config.source.assert_called_once_with(str(path.with_name("config.py")))
        self.assertEqual(c.tabs.show, "never")
        self.assertEqual(c.statusbar.show, "never")
        self.assertTrue(c.tabs.tabs_are_windows)
        self.assertFalse(c.auto_save.session)
        self.assertIsNone(c.session.default_name)
        ast.parse(path.read_text())

    def test_all_desktop_actions_use_app_launcher(self):
        entries = list((ROOT / "scripts/.local/share/applications").glob("brave-*-Default.desktop"))
        self.assertEqual(len(entries), 7)
        actions = 0
        for path in entries:
            config = configparser.ConfigParser(interpolation=None)
            config.read(path)
            self.assertEqual(config["Desktop Entry"]["StartupWMClass"],
                             "org.qutebrowser.webapps")
            for section in config.sections():
                if "Exec" not in config[section]:
                    continue
                args = shlex.split(config[section]["Exec"])
                self.assertEqual(args[0], str(Path.home() / ".local/bin/qute-webapp"))
                self.assertEqual(len(args), 2)
                self.assertTrue(args[1].startswith("https://"))
                actions += 1
        self.assertEqual(actions, 10)


if __name__ == "__main__":
    unittest.main()
