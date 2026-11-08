"""Check installed PDF.js APIs, CSP integration, and actual page rendering."""

import base64
from fractions import Fraction
import hashlib
import json
import os
from pathlib import Path
import re
import random
import runpy
import tempfile
import struct
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
HELPER = ROOT / ".config/qutebrowser/pdf_viewer.py"
SCRATCH = tempfile.TemporaryDirectory(prefix="qute-pdf-check-")
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
from PyQt6.QtWebEngineCore import QWebEnginePage, QWebEngineProfile, QWebEngineSettings
from PyQt6.QtWebEngineWidgets import QWebEngineView
from qutebrowser.browser import pdfjs, qutescheme
from qutebrowser.browser.webengine import webenginequtescheme
from qutebrowser.config import config, configcache, configdata, configfiles
from qutebrowser.utils import standarddir

webenginequtescheme.init()
APP = QApplication(["qute-pdf-check"])
APP.setApplicationName("qute-pdf-check")
for location in standarddir._Location:
    standarddir._locations[location] = SCRATCH.name
runpy.run_path(str(HELPER))
configdata.init()
config.instance = config.Config(yaml_config=configfiles.YamlConfig())
config.val = config.ConfigContainer(config.instance)
config.key_instance = config.KeyConfig(config.instance)
config.cache = configcache.ConfigCache()
configfiles.read_config_py(ROOT / ".config/qutebrowser/config.py", raising=True, warn_autoconfig=True)


def sample_pdf():
    """One page with a black rectangle: parsing and painting must both work."""
    stream = b"0 0 0 rg 0 0 50 50 re f\n"
    objects = [
        b"<< /Type /Catalog /Pages 2 0 R >>",
        b"<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
        b"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 100 100] /Contents 4 0 R >>",
        f"<< /Length {len(stream)} >>\nstream\n".encode() + stream + b"endstream",
    ]
    data = b"%PDF-1.4\n"
    offsets = [0]
    for number, obj in enumerate(objects, 1):
        offsets.append(len(data))
        data += f"{number} 0 obj\n".encode() + obj + b"\nendobj\n"
    xref = len(data)
    data += b"xref\n0 5\n0000000000 65535 f \n"
    data += b"".join(f"{offset:010d} 00000 n \n".encode() for offset in offsets[1:])
    return data + f"trailer\n<< /Size 5 /Root 1 0 R >>\nstartxref\n{xref}\n%%EOF".encode()


class ConsolePage(QWebEnginePage):
    def javaScriptConsoleMessage(self, level, message, line, source):
        self.messages.append(message)


class PDFTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.profile = QWebEngineProfile(APP)
        cls.handler = webenginequtescheme.QuteSchemeHandler(cls.profile)
        cls.handler.install(cls.profile)
        cls.page = ConsolePage(cls.profile)
        cls.page.messages = []
        cls.view = QWebEngineView()
        cls.view.setPage(cls.page)
        cls.view.show()

    def setUp(self):
        self.page.messages.clear()
        self.page.settings().setAttribute(QWebEngineSettings.WebAttribute.LocalContentCanAccessFileUrls, True)

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

        def completed(value):
            result.append(value)
            loop.quit()

        timer.start(15000)
        start(completed)
        if not result:
            loop.exec()
        timer.stop()
        self.assertTrue(result, "Offscreen browser operation timed out: " + repr(self.page.messages))
        return result[0]

    def js(self, source):
        return self.wait_for(lambda done: self.page.runJavaScript(source, done))

    def load(self, path):
        def start(done):
            def loaded(ok):
                self.page.loadFinished.disconnect(loaded)
                done(ok)
            self.page.loadFinished.connect(loaded)
            self.page.load(QUrl.fromLocalFile(str(path)))
        self.assertTrue(self.wait_for(start))

    def test_reload_and_viewer_csp(self):
        before = pdfjs._get_polyfills()
        runpy.run_path(str(HELPER))
        self.assertEqual(before, pdfjs._get_polyfills())
        self.assertTrue(pdfjs.get_pdfjs_res("build/pdf.worker.mjs").startswith(before.encode()))
        html = pdfjs.generate_pdfjs_page("sample.pdf", QUrl("https://example.test/sample.pdf"))
        script = re.search(r"</body><script>(.*?)</script>", html, re.DOTALL)
        self.assertIsNotNone(script, "qutebrowser changed its viewer startup integration")
        digest = base64.b64encode(hashlib.sha256(script[1].encode()).digest()).decode()
        self.assertIn("'sha256-" + digest + "'", html)
        self.assertIn("'wasm-unsafe-eval'", html)
        self.assertNotIn("'unsafe-inline'", html)

    def test_full_internal_viewer_loads_styles_modules_and_pdf(self):
        url = pdfjs.get_main_url("sample.pdf", QUrl("https://example.test/sample.pdf"))
        setting = "content.local_content_can_access_file_urls"
        self.assertFalse(config.instance.get(setting, url=QUrl("file:///tmp/untrusted.html")))
        self.page.settings().setAttribute(
            QWebEngineSettings.WebAttribute.LocalContentCanAccessFileUrls,
            config.instance.get(setting, url=url),
        )
        pdf = Path(SCRATCH.name) / "sample.pdf"
        pdf.write_bytes(sample_pdf())
        with patch.object(qutescheme, "_pdf_path", return_value=str(pdf)):
            def load(done):
                def loaded(ok):
                    self.page.loadFinished.disconnect(loaded)
                    done(ok)
                self.page.loadFinished.connect(loaded)
                self.page.load(url)
            self.assertTrue(self.wait_for(load))
            # A bare, unstyled HTML viewer can report a successful page load.
            self.assertTrue(self.js("Array.from(document.styleSheets).some(s => s.href && s.href.endsWith('/viewer.css') && s.cssRules.length > 0)"),
                            "Internal PDF viewer stylesheet was blocked")

            def poll(done):
                def received(result):
                    if result:
                        done(result)
                    else:
                        QTimer.singleShot(50, lambda: self.page.runJavaScript(
                            "Boolean(window.PDFViewerApplication?.pdfDocument)", received))
                self.page.runJavaScript(
                    "Boolean(window.PDFViewerApplication?.pdfDocument)", received)
            self.assertTrue(self.wait_for(poll))
            self.assertEqual(self.js("window.PDFViewerApplication.pdfDocument.numPages"), 1)
            self.assertEqual(self.js("typeof window.PDFViewerApplicationOptions.set"), "function")

    def test_render_and_required_apis(self):
        # Use the installed distribution and qutebrowser's patched worker,
        # including its upstream and local compatibility shims.
        module, path = pdfjs.get_pdfjs_res_and_path("build/pdf.mjs")
        self.assertIsNotNone(path, "This check expects the system PDF.js installation")
        worker = Path(SCRATCH.name) / "pdf.worker.mjs"
        worker.write_bytes(pdfjs.get_pdfjs_res("build/pdf.worker.mjs"))
        html = Path(SCRATCH.name) / "test.html"
        html.write_text("<canvas id='canvas'></canvas><script>" + pdfjs._get_polyfills() + "</script>")
        self.load(html)
        missing = self.js("""(() => {
          const required = {
            'Promise.withResolvers': Promise.withResolvers,
            'URL.parse': URL.parse, 'RegExp.escape': RegExp.escape,
            'Math.sumPrecise': Math.sumPrecise,
            'Uint8Array.fromBase64': Uint8Array.fromBase64,
            'Uint8Array.toBase64': Uint8Array.prototype.toBase64,
            'Uint8Array.toHex': Uint8Array.prototype.toHex,
            'Set.difference': Set.prototype.difference,
            'Set.intersection': Set.prototype.intersection,
            'Set.isSubsetOf': Set.prototype.isSubsetOf,
            'Map.getOrInsert': Map.prototype.getOrInsert,
            'Map.getOrInsertComputed': Map.prototype.getOrInsertComputed,
            'WeakMap.getOrInsert': WeakMap.prototype.getOrInsert,
            'WeakMap.getOrInsertComputed': WeakMap.prototype.getOrInsertComputed
          };
          return Object.keys(required).filter(key => typeof required[key] !== 'function');
        })()""")
        self.assertEqual(missing, [], "Installed PDF.js requires missing browser APIs")
        encoded = base64.b64encode(sample_pdf()).decode()
        self.js("""window.renderResult = null;
          (async () => {
            try {
              const lib = await import(MODULE);
              lib.GlobalWorkerOptions.workerSrc = WORKER;
              const task = lib.getDocument({data: Uint8Array.from(atob(DATA), c => c.charCodeAt(0))});
              const doc = await task.promise;
              const page = await doc.getPage(1);
              const canvas = document.querySelector('canvas');
              canvas.width = canvas.height = 100;
              const context = canvas.getContext('2d');
              await page.render({canvasContext: context, viewport: page.getViewport({scale: 1})}).promise;
              const pixel = Array.from(context.getImageData(25, 75, 1, 1).data);
              await task.destroy();
              window.renderResult = {pixel};
            } catch (error) { window.renderResult = {error: String(error.stack)}; }
          })(); void 0;
        """.replace("MODULE", json.dumps(QUrl.fromLocalFile(path).toString()))
             .replace("WORKER", json.dumps(QUrl.fromLocalFile(str(worker)).toString()))
             .replace("DATA", json.dumps(encoded)))

        def poll(done):
            def received(result):
                if result is not None:
                    done(result)
                else:
                    QTimer.singleShot(50, lambda: self.page.runJavaScript("window.renderResult", received))
            self.page.runJavaScript("window.renderResult", received)
        self.assertEqual(self.wait_for(poll), {"pixel": [0, 0, 0, 255]})

    def test_math_precision_against_exact_rational_sums(self):
        html = Path(SCRATCH.name) / "math.html"
        html.write_text("<script>" + pdfjs._get_polyfills() + "</script>")
        self.load(html)
        rng = random.Random(42)
        cases = [[1e16, 1, -1e16], [1e308, 1e308, -1e308],
                 [float.fromhex("0x1.fffffffffffffp+1023"), 2 ** 970, -2 ** -1074]]
        for _ in range(128):
            values = []
            while len(values) < 32:
                value = struct.unpack("d", rng.getrandbits(64).to_bytes(8, "little"))[0]
                if value == value and abs(value) != float("inf"):
                    values.append(value)
            cases.append(values)
        for values in cases:
            exact = sum(map(Fraction, values), Fraction())
            try:
                expected = float(exact)
            except OverflowError:
                expected = float("inf") if exact > 0 else -float("inf")
            self.assertTrue(self.js(
                "Object.is(Math.sumPrecise(" + json.dumps(values) + "), " + json.dumps(expected) + ")"
            ), f"Incorrect sum for {values!r}")

    def test_polyfill_edge_cases_and_native_preservation(self):
        html = Path(SCRATCH.name) / "edges.html"
        html.write_text("<script>" + pdfjs._get_polyfills() + "</script>")
        self.load(html)
        self.assertTrue(self.js("""(() => {
          if (!Object.is(Math.sumPrecise([]), -0) || !Object.is(Math.sumPrecise([-0]), -0) ||
              !Object.is(Math.sumPrecise([-0, 0]), 0) ||
              !Number.isNaN(Math.sumPrecise([Infinity, -Infinity])) ||
              Math.sumPrecise([Infinity, 2]) !== Infinity) return false;
          let closed = false;
          function* invalid() { try { yield 1; yield '2'; } finally { closed = true; } }
          try { Math.sumPrecise(invalid()); return false; } catch (e) { if (!(e instanceof TypeError)) return false; }
          if (!closed) return false;
          const cache = new WeakMap(), key = {}; let calls = 0;
          cache.getOrInsertComputed(key, () => { calls++; return undefined; });
          cache.getOrInsertComputed(key, () => { calls++; return 7; });
          if (calls !== 1 || cache.get(key) !== undefined) return false;
          const other = {};
          if (cache.getOrInsert(other, 1) !== 1 || cache.getOrInsert(other, 2) !== 1) return false;
          return true;
        })()"""))
        self.js("window.originalMathSum = Math.sumPrecise; window.originalWeakMap = WeakMap.prototype.getOrInsertComputed;")
        self.js(pdfjs._get_polyfills())
        self.assertTrue(self.js("Math.sumPrecise === window.originalMathSum && WeakMap.prototype.getOrInsertComputed === window.originalWeakMap"))


if __name__ == "__main__":
    unittest.main()
