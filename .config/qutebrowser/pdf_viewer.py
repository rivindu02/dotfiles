"""Keep PDF.js 6 compatible with qutebrowser's viewer and QtWebEngine."""

import base64
import hashlib
from pathlib import Path
import re

from qutebrowser.browser import pdfjs


# qutebrowser 3.7 supplies Map upsert methods, but PDF.js 6.5 also uses
# WeakMap upsert methods and Math.sumPrecise, missing in QtWebEngine 6.11.
# Extend the shared polyfills so both the viewer and PDF worker receive them.
_original_polyfills = getattr(
    pdfjs._get_polyfills, "_qute_original", pdfjs._get_polyfills
)


def get_polyfills():
    math_polyfill = Path(__file__).resolve().with_name("pdf-math-polyfill.js").read_text(encoding="ascii")
    return _original_polyfills() + math_polyfill + """
;(function() {
    if (typeof WeakMap.prototype.getOrInsert === "undefined") {
        Object.defineProperty(WeakMap.prototype, "getOrInsert", {
            configurable: true,
            writable: true,
            value: function(key, defaultValue) {
                if (!this.has(key)) {
                    this.set(key, defaultValue);
                }
                return this.get(key);
            }
        });
    }
    if (typeof WeakMap.prototype.getOrInsertComputed === "undefined") {
        Object.defineProperty(WeakMap.prototype, "getOrInsertComputed", {
            configurable: true,
            writable: true,
            value: function(key, callbackFunction) {
                if (typeof callbackFunction !== "function") {
                    throw new TypeError("Expected a callback function");
                }
                if (!this.has(key)) {
                    this.set(key, callbackFunction(key));
                }
                return this.get(key);
            }
        });
    }
})();
"""


get_polyfills._qute_original = _original_polyfills
pdfjs._get_polyfills = get_polyfills


# PDF.js 6 restricts inline JavaScript, including qutebrowser's own viewer
# startup/polyfill script. Authorize that exact script by hash, keeping the
# rest of the viewer's Content Security Policy intact.
_original = getattr(pdfjs.generate_pdfjs_page, "_qute_original", pdfjs.generate_pdfjs_page)
_policy_meta = re.compile(
    r'''(<meta\b(?=[^>]*\bhttp-equiv\s*=\s*["']Content-Security-Policy["'])[^>]*\bcontent\s*=\s*")([^"]*)(")''',
    re.IGNORECASE,
)


def generate_pdfjs_page(filename, url):
    html = _original(filename, url)
    script = re.search(r"</body><script>(.*?)</script>", html, re.DOTALL)
    if script is None:
        return html
    digest = base64.b64encode(hashlib.sha256(script[1].encode("utf-8")).digest()).decode("ascii")
    allowed_hash = "'sha256-" + digest + "'"

    def allow_startup(match):
        directives = match[2].split(";")
        for index, directive in enumerate(directives):
            tokens = directive.split()
            if tokens and tokens[0].lower() == "script-src":
                if "'unsafe-inline'" not in tokens and allowed_hash not in tokens:
                    directives[index] = directive + " " + allowed_hash
                break
        return match[1] + ";".join(directives) + match[3]

    return _policy_meta.sub(allow_startup, html)


# :config-source must replace the wrapper rather than nest wrappers on reload.
generate_pdfjs_page._qute_original = _original
pdfjs.generate_pdfjs_page = generate_pdfjs_page
