#!/usr/bin/env python3
"""Exercise login filling in a private, offscreen QtWebEngine using dummy data."""

import json
import os
from pathlib import Path
import runpy
import shlex
import tempfile
import unittest
from types import SimpleNamespace
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[2]
JAVASCRIPT = (ROOT / ".config/qutebrowser/bitwarden-fill.js").read_text()
SCRATCH = tempfile.TemporaryDirectory(prefix="qute-bitwarden-dom-")
for name in ("XDG_CONFIG_HOME", "XDG_CACHE_HOME", "XDG_DATA_HOME", "XDG_RUNTIME_DIR"):
    directory = Path(SCRATCH.name) / name
    directory.mkdir(mode=0o700)
    os.environ[name] = str(directory)
os.environ["QT_QPA_PLATFORM"] = "offscreen"
os.environ["QT_QPA_PLATFORMTHEME"] = ""
os.environ["QT_STYLE_OVERRIDE"] = "Fusion"
os.environ["QTWEBENGINE_CHROMIUM_FLAGS"] = "--disable-gpu"

from PyQt6.QtCore import QEventLoop, QTimer, QUrl
from PyQt6.QtWidgets import QApplication
from PyQt6.QtWebEngineCore import QWebEnginePage, QWebEngineProfile
from PyQt6.QtWebEngineWidgets import QWebEngineView


APP = QApplication(["qute-bitwarden-dom-test"])
APP.setApplicationName("qute-bitwarden-dom-test")


class FillTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.profile = QWebEngineProfile(APP)  # unnamed profiles are off the record
        cls.page = QWebEnginePage(cls.profile)
        cls.view = QWebEngineView()
        cls.view.setPage(cls.page)
        cls.view.resize(800, 600)
        cls.view.show()

    def wait_for(self, start):
        loop = QEventLoop()
        result = []
        timer = QTimer()
        timer.setSingleShot(True)
        timer.timeout.connect(loop.quit)

        def completed(value):
            result.append(value)
            loop.quit()

        timer.start(10000)
        start(completed)
        if not result:
            loop.exec()
        timer.stop()
        self.assertTrue(result, "Offscreen browser operation timed out")
        return result[0]

    def js(self, script):
        return self.wait_for(lambda callback: self.page.runJavaScript(script, callback))

    def load(self, content):
        def start(callback):
            def loaded(success):
                self.page.loadFinished.disconnect(loaded)
                callback(success)
            self.page.loadFinished.connect(loaded)
            self.page.setHtml("<html><body tabindex='-1'>" + content + "</body></html>", QUrl("https://example.test/"))
        self.assertTrue(self.wait_for(start))

    def fill(self, mode="login", url="https://example.test/"):
        payload = {"url": url, "username": "dummy@example.test", "password": "synthetic-pw-'\\\"<>&é", "mode": mode}
        return self.js("(" + JAVASCRIPT + ")(" + json.dumps(payload) + ")")

    def values(self):
        return self.js("Array.from(document.querySelectorAll('input')).map(e => e.value)")

    def test_starting_cursor_does_not_change_fields(self):
        for focus in ("document.body", "document.querySelector('#user')", "document.querySelector('#pass')", "document.querySelector('button')"):
            with self.subTest(focus=focus):
                self.load("<form><input id='user' autocomplete='username' value='old'><button type='button'>Show</button><input id='pass' type='password' value='old'></form>")
                self.js(focus + ".focus()")
                self.assertEqual(self.fill(), {"ok": True, "filled": "login"})
                self.assertEqual(self.values(), ["dummy@example.test", "synthetic-pw-'\\\"<>&é"])

    def test_password_only_never_writes_username(self):
        self.load("<form><input id='user' value='keep-me'><input type='password'></form>")
        self.js("document.querySelector('#user').focus()")
        self.assertEqual(self.fill("password"), {"ok": True, "filled": "password"})
        self.assertEqual(self.values(), ["keep-me", "synthetic-pw-'\\\"<>&é"])

    def test_two_step_username_page_never_receives_password(self):
        self.load("<input type='email' autocomplete='username'>")
        self.assertEqual(self.fill(), {"ok": True, "filled": "username"})
        self.assertEqual(self.values(), ["dummy@example.test"])
        self.assertEqual(self.fill("password"), {"ok": False, "error": "no-password"})
        self.assertEqual(self.values(), ["dummy@example.test"])

    def test_ambiguous_forms_require_a_focused_form(self):
        self.load("<form><input id='first' autocomplete='username'><input type='password'></form><form><input id='second' autocomplete='username'><input type='password'></form>")
        self.assertEqual(self.fill(), {"ok": False, "error": "ambiguous"})
        self.assertEqual(self.values(), ["", "", "", ""])
        self.js("document.querySelector('#second').focus()")
        self.assertTrue(self.fill()["ok"])
        self.assertEqual(self.values(), ["", "", "dummy@example.test", "synthetic-pw-'\\\"<>&é"])

    def test_hidden_fields_and_otp_are_ignored(self):
        self.load("<form><input type='email'><input autocomplete='one-time-code'><input type='password' style='display:none'><input type='password'></form>")
        self.assertTrue(self.fill()["ok"])
        self.assertEqual(self.values(), ["dummy@example.test", "", "", "synthetic-pw-'\\\"<>&é"])

    def test_navigation_prevents_filling(self):
        self.load("<form><input type='email'><input type='password'></form>")
        self.assertEqual(self.fill(url="https://other.test/"), {"ok": False, "error": "changed-page"})
        self.assertEqual(self.values(), ["", ""])

    def test_input_and_change_events_reach_controlled_fields(self):
        self.load("<form><input type='email'><input type='password'></form>")
        self.js("for (const input of document.querySelectorAll('input')) { input.dataset.events = ''; for (const event of ['input', 'change']) input.addEventListener(event, () => input.dataset.events += event + ','); }")
        self.assertTrue(self.fill()["ok"])
        self.assertEqual(self.js("Array.from(document.querySelectorAll('input')).map(e => e.dataset.events)"), ["input,change,", "input,change,"])

    def test_private_handoff_reaches_fields_and_rejects_navigation(self):
        # Exercise the actual userscript -> private JSON -> browser command ->
        # renderer path, without starting bw or opening a real login page.
        from qutebrowser.config import config
        from qutebrowser.utils import standarddir
        from qutebrowser.api import cmdutils

        runtime = Path(os.environ["XDG_RUNTIME_DIR"])
        standarddir._locations[standarddir._Location.runtime] = str(runtime)
        helper = runpy.run_path(str(ROOT / ".config/qutebrowser/bitwarden_fill.py"))
        userscript = runpy.run_path(str(ROOT / ".config/qutebrowser/userscripts/qute-bitwarden"))
        self.load("<form><input type='email'><input type='password'></form>")
        self.js("document.querySelector('input[type=password]').focus()")
        tab = SimpleNamespace(url=lambda: QUrl("https://example.test/"))
        browser = SimpleNamespace(widget=SimpleNamespace(currentWidget=lambda: tab, currentIndex=lambda: 0))
        sent = []

        def deliver(command):
            sent.append(command)
            name, filename = shlex.split(command)
            self.assertEqual(name, "bitwarden-fill-data")
            self.assertEqual(Path(filename).stat().st_mode & 0o777, 0o600)
            helper["bitwarden_fill_data"](filename, win_id=1)
            self.assertFalse(Path(filename).exists())

        env = {"QUTE_FIFO": str(runtime / "test-fifo"), "QUTE_URL": "https://example.test/", "QUTE_TAB_INDEX": "1"}
        with patch.dict(os.environ, env), patch.object(helper["objreg"], "get", return_value=browser), patch.object(helper["modeman"], "enter"), patch.dict(userscript["fill_login"].__globals__, {"qute_command": deliver}):
            def start(done):
                def evaluate(code, callback, world):
                    def complete(result):
                        callback(result)
                        done(result)
                    self.page.runJavaScript(code, complete)
                tab.run_js_async = evaluate
                userscript["fill_login"]("handoff-user", "handoff-password", "login", True)
            self.assertTrue(self.wait_for(start)["ok"])
            self.assertEqual(self.values(), ["handoff-user", "handoff-password"])
            self.assertNotIn("handoff-password", sent[0])
            with patch.dict(os.environ, {"QUTE_URL": "https://other.test/"}):
                with self.assertRaises(cmdutils.CommandError):
                    userscript["fill_login"]("wrong-user", "wrong-password", "login", True)
            self.assertEqual(self.values(), ["handoff-user", "handoff-password"])
        self.assertEqual(list(runtime.glob("bitwarden-fill-*.json")), [])


if __name__ == "__main__":
    unittest.main()
