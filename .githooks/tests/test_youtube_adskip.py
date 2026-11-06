"""Exercise ad skipping on synthetic pages in a private QtWebEngine profile."""
import os
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = (ROOT / ".config/qutebrowser/greasemonkey/youtube-adskip.user.js").read_text()
SCRATCH = tempfile.TemporaryDirectory(prefix="qute-adskip-test-")
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
from PyQt6.QtWebEngineCore import QWebEnginePage, QWebEngineProfile
from PyQt6.QtWebEngineWidgets import QWebEngineView
from qutebrowser.browser.greasemonkey import GreasemonkeyScript
from qutebrowser.misc import objects
from qutebrowser.utils import usertypes

# Exercise qutebrowser's real window proxy, including main-world exports.
objects.backend = usertypes.Backend.QtWebEngine
SCRIPT = GreasemonkeyScript.parse(SCRIPT).code()

APP = QApplication(["qute-adskip-test"])
APP.setApplicationName("qute-adskip-test")

PLAYER = '''<div id="movie_player" class="html5-video-player">
<video id="main" class="html5-main-video" style="width:320px;height:180px"></video>
<button id="skip" class="ytp-ad-skip-button-modern" onclick="window.clicks++">Skip</button>
</div><video id="outside" style="width:200px;height:100px"></video>
<button class="ytp-ad-skip-button" onclick="window.outsideClicks++">Unrelated</button>'''


class AdSkipTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.profile = QWebEngineProfile(APP)
        cls.page = QWebEnginePage(cls.profile)
        cls.view = QWebEngineView()
        cls.view.setPage(cls.page)
        cls.view.resize(900, 600)
        cls.view.show()

    @classmethod
    def tearDownClass(cls):
        cls.page.setHtml("")
        cls.view.close()
        cls.page.deleteLater()
        APP.processEvents()

    def wait_for(self, start):
        result = []
        loop = QEventLoop()
        timer = QTimer()
        timer.setSingleShot(True)
        timer.timeout.connect(loop.quit)

        def done(value):
            result.append(value)
            loop.quit()

        timer.start(5000)
        start(done)
        if not result:
            loop.exec()
        timer.stop()
        self.assertTrue(result, "Browser operation timed out")
        return result[0]

    def js(self, source):
        return self.wait_for(lambda callback: self.page.runJavaScript(source, callback))

    def settle(self, milliseconds=180):
        self.wait_for(lambda callback: QTimer.singleShot(milliseconds, lambda: callback(True)))

    def prepare_media(self):
        self.js('''window.clicks=0; window.outsideClicks=0; window.seeks=0;
          for (const video of document.querySelectorAll('video')) {
            Object.defineProperty(video, 'readyState', {get:()=>4, configurable:true});
            Object.defineProperty(video, 'currentTime', {
              get:()=>37, set:()=>{window.seeks++;}, configurable:true
            });
            video.playbackRate=2; video.muted=false;
          }''')

    def load(self, ad=False, host="www.youtube.com", body=PLAYER, setup=""):
        def start(callback):
            def loaded(ok):
                self.page.loadFinished.disconnect(loaded)
                callback(ok)
            self.page.loadFinished.connect(loaded)
            self.page.setHtml("<!doctype html><html><body>" + body + "</body></html>", QUrl(f"https://{host}/watch?v=test"))
        self.assertTrue(self.wait_for(start))
        self.prepare_media()
        if ad:
            self.js("document.getElementById('movie_player').classList.add('ad-showing')")
        if setup:
            self.js(setup)
        self.js(SCRIPT)

    def state(self):
        return self.js('''(() => {
          const video=document.querySelector('#main');
          return {rate:video.playbackRate, muted:video.muted,
                  time:video.currentTime, seeks:window.seeks,
                  clicks:window.clicks, outsideClicks:window.outsideClicks};
        })()''')

    def test_normal_video_is_untouched_even_with_skip_buttons(self):
        self.load()
        self.settle(600)
        self.assertEqual(self.state(), dict(rate=2, muted=False, time=37, seeks=0, clicks=0, outsideClicks=0))

    def test_marked_ad_is_sped_up_and_skip_is_player_scoped(self):
        self.load(ad=True)
        self.assertEqual(self.state(), dict(rate=16, muted=True, time=37, seeks=0, clicks=1, outsideClicks=0))
        self.assertEqual(self.js("document.querySelector('#outside').playbackRate"), 2)
        self.js("document.querySelector('#movie_player').classList.remove('ad-showing')")
        self.settle()
        self.assertEqual(self.state()['rate'], 2)
        self.assertFalse(self.state()['muted'])

    def test_skip_that_ends_ad_does_not_change_real_playback(self):
        self.load(ad=True, setup="document.querySelector('#skip').onclick=()=>{window.clicks++;document.querySelector('#movie_player').classList.remove('ad-showing')}")
        self.assertEqual(self.state(), dict(rate=2, muted=False, time=37, seeks=0, clicks=1, outsideClicks=0))

    def test_hidden_or_disabled_skip_buttons_are_not_clicked(self):
        self.load(ad=True, setup="document.querySelector('#skip').style.display='none'")
        self.assertEqual(self.state()['clicks'], 0)
        self.js("document.querySelector('#skip').style.display='';document.querySelector('#skip').disabled=true")
        self.settle(600)
        self.assertEqual(self.state()['clicks'], 0)
        self.assertEqual(self.state()['outsideClicks'], 0)

    def test_toggle_restores_preferences_and_stays_disabled(self):
        self.load(ad=True)
        self.assertEqual(self.js("window.__quteYoutubeAdSkip.toggle()"), "YouTube ad skipping: off")
        self.settle(600)
        self.assertEqual(self.state()['rate'], 2)
        self.assertFalse(self.state()['muted'])
        self.assertEqual(self.js("window.__quteYoutubeAdSkip.toggle()"), "YouTube ad skipping: on")
        self.assertEqual(self.state()['rate'], 16)

    def test_navigation_restores_speed_while_old_ad_flag_remains(self):
        self.load(ad=True)
        self.js("document.dispatchEvent(new Event('yt-navigate-start'))")
        self.settle(600)
        self.assertEqual(self.state()['rate'], 2)
        self.assertFalse(self.state()['muted'])
        self.js("document.querySelector('#movie_player').classList.remove('ad-showing');document.dispatchEvent(new Event('yt-navigate-finish'))")
        self.settle()
        self.assertEqual(self.state()['rate'], 2)

    def test_manual_preferences_are_preserved_on_ad_exit(self):
        self.load(ad=True, setup="document.querySelector('#main').muted=true;document.querySelector('#main').playbackRate=1.25")
        self.js("document.querySelector('#movie_player').classList.remove('ad-showing')")
        self.settle()
        self.assertEqual(self.state()['rate'], 1.25)
        self.assertTrue(self.state()['muted'])

    def test_late_player_is_detected_and_other_sites_are_excluded(self):
        self.load(body="<div>Loading player</div>")
        import json
        self.js("document.body.innerHTML=" + json.dumps(PLAYER))
        self.prepare_media()
        self.js("document.querySelector('#movie_player').classList.add('ad-showing')")
        self.settle(650)
        self.assertEqual(self.state()['rate'], 16)
        self.load(ad=True, host="example.test")
        self.assertEqual(self.state()['rate'], 2)
        self.assertEqual(self.js("typeof window.__quteYoutubeAdSkip"), "undefined")


if __name__ == "__main__":
    unittest.main()
