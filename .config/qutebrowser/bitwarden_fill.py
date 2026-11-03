"""Receive a private userscript payload and fill the original login page."""

import json
import os
from pathlib import Path
import stat

from qutebrowser.api import cmdutils, message
from qutebrowser.keyinput import modeman
from qutebrowser.misc import objects
from qutebrowser.qt.core import QUrl
from qutebrowser.utils import objreg, standarddir, usertypes


_fill_javascript = Path(__file__).resolve().with_name("bitwarden-fill.js").read_text()
objects.commands.pop("bitwarden-fill-data", None)


@cmdutils.register(name="bitwarden-fill-data")
@cmdutils.argument("win_id", value=cmdutils.Value.win_id)
def bitwarden_fill_data(filename: str, win_id: int):
    """Fill login fields from a private, temporary userscript handoff."""
    path = Path(filename)
    runtime = Path(standarddir.runtime()).resolve()
    if path.parent != runtime or not path.name.startswith("bitwarden-fill-"):
        raise cmdutils.CommandError("Bitwarden: invalid fill request.")
    try:
        descriptor = os.open(path, os.O_RDONLY | os.O_NOFOLLOW)
        with os.fdopen(descriptor, encoding="utf-8") as stream:
            info = os.fstat(stream.fileno())
            if (not stat.S_ISREG(info.st_mode) or info.st_uid != os.getuid()
                    or stat.S_IMODE(info.st_mode) != 0o600 or info.st_size > 1024 * 1024):
                raise ValueError("Invalid handoff permissions")
            payload = json.load(stream)
    except (OSError, ValueError):
        raise cmdutils.CommandError("Bitwarden: the fill request expired or could not be read.") from None
    finally:
        path.unlink(missing_ok=True)

    if (not isinstance(payload, dict)
            or any(not isinstance(payload.get(key), str) for key in ("url", "username", "password"))
            or payload.get("mode") not in ("login", "username", "password")
            or not isinstance(payload.get("tab_index"), int)):
        raise cmdutils.CommandError("Bitwarden: invalid fill request.")

    browser = objreg.get("tabbed-browser", scope="window", window=win_id)
    tab = browser.widget.currentWidget()
    if (tab is None or browser.widget.currentIndex() + 1 != payload["tab_index"]
            or tab.url() != QUrl(payload["url"])):
        raise cmdutils.CommandError("Bitwarden: the page changed while choosing a login. Try again.")

    def filled(result):
        if not isinstance(result, dict) or not result.get("ok"):
            errors = {
                "changed-page": "The page changed while choosing a login. Try again.",
                "no-password": "No visible password field was found. Continue to the password step first.",
                "ambiguous": "More than one login form was found. Focus a field in the form you want.",
                "no-fields": "No visible login fields were found.",
            }
            code = result.get("error") if isinstance(result, dict) else None
            message.error("Bitwarden: " + errors.get(code, "Could not fill this login form."))
            return
        if payload.get("insert_mode", True):
            modeman.enter(win_id, usertypes.KeyMode.insert, "Bitwarden filled login")
        if result.get("filled") == "username":
            message.info("Bitwarden: username filled. Continue to the password step, then use Ctrl+Alt+L.")

    # The FIFO command contains only a filename. Credentials are read and
    # removed before filling, and never included in browser command strings.
    tab.run_js_async(
        "(" + _fill_javascript + ")(" + json.dumps(payload, ensure_ascii=True) + ")",
        callback=filled,
        world=usertypes.JsWorld.main,
    )
