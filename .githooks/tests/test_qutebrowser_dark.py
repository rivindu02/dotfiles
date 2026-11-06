"""Exercise dark rendering, toggles and YouTube navigation in QtWebEngine."""
import os
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = (ROOT / ".config/qutebrowser/greasemonkey/gruvbox-dark.user.js").read_text()
SCRATCH = tempfile.TemporaryDirectory(prefix="qute-dark-test-")
for key in ("XDG_CONFIG_HOME", "XDG_DATA_HOME", "XDG_CACHE_HOME", "XDG_RUNTIME_DIR"):
    folder = Path(SCRATCH.name) / key
    folder.mkdir(mode=0o700)
    os.environ[key] = str(folder)
os.environ["QT_QPA_PLATFORM"] = "offscreen"
os.environ["QT_QPA_PLATFORMTHEME"] = ""
os.environ["QT_STYLE_OVERRIDE"] = "Fusion"
os.environ["QTWEBENGINE_CHROMIUM_FLAGS"] = "--disable-gpu"

from PyQt6.QtCore import QEventLoop, QTimer, QUrl
from PyQt6.QtWidgets import QApplication
from PyQt6.QtWebEngineCore import QWebEnginePage, QWebEngineProfile, QWebEngineScript
from PyQt6.QtWebEngineWidgets import QWebEngineView
from qutebrowser.browser.greasemonkey import GreasemonkeyScript
from qutebrowser.misc import objects
from qutebrowser.utils import usertypes

objects.backend = usertypes.Backend.QtWebEngine
SCRIPT = GreasemonkeyScript.parse(SCRIPT).code()

APP = QApplication(["qute-dark-test"])


class DarkTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.profile = QWebEngineProfile(APP)
        cls.page = QWebEnginePage(cls.profile)
        cls.view = QWebEngineView()
        cls.view.setPage(cls.page)
        cls.view.show()

    @classmethod
    def tearDownClass(cls):
        cls.view.close()
        cls.page.deleteLater()
        APP.processEvents()

    def wait_for(self, start):
        loop = QEventLoop()
        result = []
        timer = QTimer()
        timer.setSingleShot(True)
        timer.timeout.connect(loop.quit)
        def done(value):
            result.append(value)
            loop.quit()
        timer.start(10000)
        start(done)
        if not result:
            loop.exec()
        timer.stop()
        self.assertTrue(result, "Browser operation timed out")
        return result[0]

    def js(self, source):
        return self.wait_for(lambda done: self.page.runJavaScript(source, done))

    def settle(self):
        self.wait_for(lambda done: QTimer.singleShot(300, lambda: done(True)))

    def load(self, host="www.youtube.com", disabled=False, native_dark=False, legacy=False):
        def start(done):
            def loaded(ok):
                self.page.loadFinished.disconnect(loaded)
                done(ok)
            self.page.loadFinished.connect(loaded)
            self.page.setHtml("""<!doctype html><html><head><style>
              body {background: white; color: black;}
              html[dark] body {background: #0f0f0f; color: white;}
              </style></head><body><ytd-app>Video title
              <video style='width:100px;height:50px'></video><img src='data:,'>
              </ytd-app></body></html>""", QUrl(f"https://{host}/watch?v=test"))
        self.assertTrue(self.wait_for(start))
        self.js("localStorage.clear();")
        if native_dark:
            self.js("document.documentElement.setAttribute('dark', 'native');")
        if legacy:
            self.js("localStorage.setItem('qutebrowser.gruvbox-dark.disabled', 'false');")
        elif not disabled:
            self.js("localStorage.setItem('qutebrowser.gruvbox-dark.enabled', 'true');")
        self.js(SCRIPT)
        self.settle()

    def test_youtube_uses_native_theme_without_dynamic_rewriting(self):
        self.load()
        self.assertEqual(self.js("window.__quteGruvboxDark.mode"), "youtube-native")
        self.assertEqual(self.js("getComputedStyle(document.body).backgroundColor"), "rgb(40, 40, 40)")
        self.assertEqual(self.js("document.querySelectorAll('.darkreader').length"), 0)

    def test_document_creation_injection_before_the_root_exists(self):
        script = QWebEngineScript()
        script.setName("gruvbox-document-start")
        script.setInjectionPoint(QWebEngineScript.InjectionPoint.DocumentCreation)
        script.setWorldId(QWebEngineScript.ScriptWorldId.MainWorld)
        script.setSourceCode(SCRIPT)
        self.load("music.youtube.com")
        self.page.scripts().insert(script)
        try:
            self.load("music.youtube.com")
            self.assertEqual(self.js("window.__quteGruvboxDark.mode"), "youtube-native")
            self.assertEqual(self.js("getComputedStyle(document.body).backgroundColor"), "rgb(40, 40, 40)")
        finally:
            self.page.scripts().remove(script)
        self.assertEqual(self.js("['video','img'].map(s => getComputedStyle(document.querySelector(s)).filter)"), ["none", "none"])
        self.js("for(let i=0;i<2000;i++) document.body.appendChild(document.createElement('div')); document.dispatchEvent(new Event('yt-navigate-finish')); document.documentElement.removeAttribute('dark');")
        self.settle()
        self.assertTrue(self.js("document.documentElement.hasAttribute('dark')"))
        self.assertEqual(self.js("document.querySelectorAll('#qute-youtube-gruvbox').length"), 1)
        self.assertEqual(self.js("document.querySelectorAll('.darkreader').length"), 0)

    def test_toggle_is_immediate_and_saved_without_reload(self):
        self.load()
        self.js("window.pageMarker = 42; window.__quteGruvboxDark.toggle()")
        self.settle()
        self.assertFalse(self.js("document.documentElement.hasAttribute('dark')"))
        self.assertEqual(self.js("getComputedStyle(document.body).backgroundColor"), "rgb(255, 255, 255)")
        self.assertEqual(self.js("localStorage.getItem('qutebrowser.gruvbox-dark.enabled')"), "false")
        self.assertEqual(self.js("window.pageMarker"), 42)
        self.js("window.__quteGruvboxDark.toggle()")
        self.assertTrue(self.js("document.documentElement.hasAttribute('dark')"))

    def test_disabled_and_embedded_players(self):
        for host in ("m.youtube.com", "www.youtube-nocookie.com"):
            self.load(host, disabled=True)
            self.assertEqual(self.js("window.__quteGruvboxDark.mode"), "youtube-native")
            self.assertFalse(self.js("document.documentElement.hasAttribute('dark')"))
            self.assertEqual(self.js("document.querySelectorAll('.darkreader').length"), 0)

    def test_default_and_legacy_preferences_leave_pages_untouched(self):
        for host in ("www.youtube.com", "m.youtube.com", "www.youtube-nocookie.com", "example.test"):
            for legacy in (False, True):
                self.load(host, disabled=True, legacy=legacy)
                self.assertEqual(self.js("getComputedStyle(document.body).backgroundColor"), "rgb(255, 255, 255)")
                self.assertEqual(self.js("document.querySelectorAll('.darkreader, #qute-youtube-gruvbox').length"), 0)
                self.assertFalse(self.js("document.documentElement.hasAttribute('data-darkreader-mode')"))

    def test_disabled_youtube_preserves_native_dark_and_stops_enforcing_theme(self):
        self.load(disabled=True, native_dark=True)
        self.js("document.dispatchEvent(new Event('yt-navigate-finish'))")
        self.settle()
        self.assertEqual(self.js("document.documentElement.getAttribute('dark')"), "native")
        self.js("window.__quteGruvboxDark.toggle()")
        self.settle()
        self.assertEqual(self.js("getComputedStyle(document.body).backgroundColor"), "rgb(40, 40, 40)")
        self.js("window.__quteGruvboxDark.toggle()")
        self.settle()
        self.assertEqual(self.js("document.documentElement.getAttribute('dark')"), "native")
        self.assertEqual(self.js("getComputedStyle(document.body).backgroundColor"), "rgb(15, 15, 15)")
        self.js("document.documentElement.removeAttribute('dark'); document.dispatchEvent(new Event('yt-navigate-finish'))")
        self.settle()
        self.assertFalse(self.js("document.documentElement.hasAttribute('dark')"))
        self.assertEqual(self.js("document.querySelectorAll('#qute-youtube-gruvbox').length"), 0)

    def test_regular_site_toggle_without_storage_restores_defaults(self):
        self.load("example.test", disabled=True)
        self.js("Storage.prototype.setItem = () => { throw new Error('Storage blocked'); }; window.__quteGruvboxDark.toggle()")
        self.settle()
        self.assertEqual(self.js("getComputedStyle(document.body).backgroundColor"), "rgb(40, 40, 40)")
        self.js("window.__quteGruvboxDark.toggle()")
        self.settle()
        self.assertEqual(self.js("getComputedStyle(document.body).backgroundColor"), "rgb(255, 255, 255)")
        self.assertEqual(self.js("document.querySelectorAll('.darkreader').length"), 0)

    def test_regular_site_still_gets_dynamic_dark_colors_and_no_duplicate_instance(self):
        self.load("example.test")
        self.assertEqual(self.js("window.__quteGruvboxDark.mode"), "darkreader")
        self.assertEqual(self.js("getComputedStyle(document.body).backgroundColor"), "rgb(40, 40, 40)")
        before = self.js("document.querySelectorAll('.darkreader').length")
        self.assertGreater(before, 0)
        self.js(SCRIPT)
        self.assertEqual(self.js("document.querySelectorAll('.darkreader').length"), before)


if __name__ == "__main__":
    unittest.main()
