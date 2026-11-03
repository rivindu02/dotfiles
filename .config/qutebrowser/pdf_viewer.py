"""Allow qutebrowser's generated startup script in PDF.js 6's viewer CSP."""

import base64
import hashlib
import re

from qutebrowser.browser import pdfjs


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
