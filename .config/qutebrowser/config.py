# qutebrowser — Gruvbox Material Dark, matching Waybar, Ghostty, and Qt.
#
# NOTE: config.py is intended for advanced users who are comfortable with
# manually migrating the config file on qutebrowser upgrades. You can also
# configure qutebrowser using :set/:bind/:config-* commands.
#
# Documentation:
#   qute://help/configuring.html
#   qute://help/settings.html
# Reload this file with :config-source. Use :help <setting> for option details.

# This is here so settings configured via the GUI and :set/:bind are still
# loaded. Do not edit autoconfig.yml by hand: qutebrowser overwrites that file.
# Theme settings below take precedence over autoconfig.yml at startup/reload.
config.load_autoconfig(True)

# Restrict WebRTC to the public interface and keep local HTML from reading
# other local files. Avoid speculative DNS requests and unsolicited playback.
c.content.webrtc_ip_handling_policy = "default-public-interface-only"
c.content.local_content_can_access_file_urls = False
c.content.dns_prefetch = False
c.content.autoplay = False
# Reject invalid background connections without offering a bypass prompt.
# Direct page visits still ask; accepting explicitly loads them insecurely.
c.content.tls.certificate_errors = "ask-block-thirdparty"

# Continue the last browsing session on startup. A fixed autosave target keeps
# named tab collections from becoming the session overwritten when quitting.
c.auto_save.session = True
c.session.default_name = "default"

# Direct search shortcuts: o !yt query, O !gh query, etc. DuckDuckGo remains
# the default, and its own !bang shortcuts still work for other services.
search_engines = dict(c.url.searchengines)
# Clear removed shortcuts on reload as well as on a fresh start.
search_engines.pop("!w", None)
search_engines.pop("!gemini", None)
search_engines.update({
    "DEFAULT": "https://duckduckgo.com/?q={}",
    "!yt": "https://www.youtube.com/results?search_query={}",
    "!gh": "https://github.com/search?q={}",
    "!aw": "https://wiki.archlinux.org/index.php?search={}",
    "!apkg": "https://archlinux.org/packages/?q={}",
    "!goog": "https://www.google.com/search?q={}",
    "!gpt": "https://chatgpt.com/?q={}",
    "!chatgpt": "https://chatgpt.com/?q={}",
    "!claude": "https://claude.ai/new?q={}",
})
c.url.searchengines = search_engines
# A shortcut alone opens the engine's homepage instead of searching DuckDuckGo.
c.url.open_base_url = True

# Shared desktop palette (sainnhe/gruvbox-material, medium dark background).
palette = {
    "bg0": "#282828",
    "bg1": "#32302f",
    "bg2": "#3c3836",
    "bg3": "#504945",
    "fg": "#d4be98",
    "grey": "#928374",
    "red": "#ea6962",
    "green": "#a9b665",
    "yellow": "#d8a657",
    "blue": "#7daea3",
    "purple": "#d3869b",
    "aqua": "#89b482",
    "orange": "#e78a4e",
}

# Default font families used for browser UI. An empty list would use Qt's
# system default. Webpage fonts are configured separately with fonts.web.*.
c.fonts.default_family = ["CaskaydiaMono Nerd Font Propo", "monospace"]
c.fonts.default_size = "11pt"
c.fonts.prompts = "default_size default_family"
c.fonts.contextmenu = "default_size default_family"
c.fonts.tooltip = "default_size default_family"

# Padding is measured in pixels. Keep tabs and the status bar comfortably
# readable alongside the desktop's 14px Waybar without hiding keyboard hints.
c.tabs.padding = {"top": 6, "bottom": 6, "left": 10, "right": 10}
c.statusbar.padding = {"top": 4, "bottom": 4, "left": 8, "right": 8}

# Completion menu (:open, :tab-select, commands, bookmarks, and history).
c.colors.completion.fg = palette["fg"]
c.colors.completion.odd.bg = palette["bg0"]
c.colors.completion.even.bg = palette["bg1"]
c.colors.completion.category.fg = palette["aqua"]
c.colors.completion.category.bg = palette["bg2"]
c.colors.completion.category.border.top = palette["bg3"]
c.colors.completion.category.border.bottom = palette["bg3"]
c.colors.completion.item.selected.fg = palette["bg0"]
c.colors.completion.item.selected.bg = palette["blue"]
c.colors.completion.item.selected.border.top = palette["blue"]
c.colors.completion.item.selected.border.bottom = palette["blue"]
c.colors.completion.item.selected.match.fg = palette["bg0"]
c.colors.completion.match.fg = palette["yellow"]
c.colors.completion.scrollbar.fg = palette["bg3"]
c.colors.completion.scrollbar.bg = palette["bg1"]

# Tooltips and context menus; disabled items retain a muted foreground.
c.colors.tooltip.bg = palette["bg2"]
c.colors.tooltip.fg = palette["fg"]
c.colors.contextmenu.menu.bg = palette["bg1"]
c.colors.contextmenu.menu.fg = palette["fg"]
c.colors.contextmenu.selected.bg = palette["blue"]
c.colors.contextmenu.selected.fg = palette["bg0"]
c.colors.contextmenu.disabled.bg = palette["bg1"]
c.colors.contextmenu.disabled.fg = palette["grey"]

# Downloads use a blue-to-green progress gradient and red for errors.
# "rgb" interpolates colors in RGB space, rather than around the HSV wheel.
c.colors.downloads.bar.bg = palette["bg0"]
c.colors.downloads.start.fg = palette["bg0"]
c.colors.downloads.start.bg = palette["blue"]
c.colors.downloads.stop.fg = palette["bg0"]
c.colors.downloads.stop.bg = palette["green"]
c.colors.downloads.system.fg = "rgb"
c.colors.downloads.system.bg = "rgb"
c.colors.downloads.error.fg = palette["bg0"]
c.colors.downloads.error.bg = palette["red"]

# Link hints (f/F) and key-chain hints. Dark text on yellow keeps link labels
# legible over both light and dark webpages; typed hint letters use red.
c.colors.hints.bg = palette["yellow"]
c.colors.hints.fg = palette["bg0"]
c.colors.hints.match.fg = "#7c2d28"
c.hints.border = "1px solid " + palette["bg0"]
# gi and ;t share the input hint group. Include custom search/text widgets
# which expose an ARIA role instead of a standard input/textarea element.
input_selectors = dict(c.hints.selectors)
input_selectors["inputs"] = list(dict.fromkeys([
    *input_selectors["inputs"],
    'input[type=""]',
    '[role~="searchbox" i]',
    '[role~="textbox" i]',
    '[role~="combobox" i][aria-autocomplete]',
]))
c.hints.selectors = input_selectors
# GitHub's header search is a dialog launcher styled as an input. Hint it
# while collapsed; once open, the regular input selectors handle the field.
github_input_selectors = dict(input_selectors)
github_input_selectors["inputs"] = [
    *input_selectors["inputs"],
    'button[aria-label^="Search or jump to"][aria-expanded="false"]',
    'button[data-target="qbsearch-input.inputButton"]',
]
config.set("hints.selectors", github_input_selectors, "https://github.com/*")
config.bind("gi", "hint inputs --first")
c.colors.keyhint.bg = palette["bg1"]
c.colors.keyhint.fg = palette["fg"]
c.colors.keyhint.suffix.fg = palette["yellow"]

# Messages keep their severity colors; informational messages use the normal
# surface so routine notifications do not look like warnings.
c.colors.messages.error.bg = palette["red"]
c.colors.messages.error.fg = palette["bg0"]
c.colors.messages.error.border = palette["red"]
c.colors.messages.warning.bg = palette["yellow"]
c.colors.messages.warning.fg = palette["bg0"]
c.colors.messages.warning.border = palette["yellow"]
c.colors.messages.info.bg = palette["bg1"]
c.colors.messages.info.fg = palette["fg"]
c.colors.messages.info.border = palette["bg3"]

# Permission, authentication, and filename prompts.
c.colors.prompts.bg = palette["bg1"]
c.colors.prompts.fg = palette["fg"]
c.colors.prompts.border = "1px solid " + palette["blue"]
c.colors.prompts.selected.bg = palette["blue"]
c.colors.prompts.selected.fg = palette["bg0"]

# Status-bar colors identify the current keyboard mode at a glance:
# green = insert, blue = passthrough, purple = caret, orange = selection.
# Private browsing has a distinct purple foreground, including command mode.
c.colors.statusbar.normal.bg = palette["bg0"]
c.colors.statusbar.normal.fg = palette["fg"]
c.colors.statusbar.insert.bg = palette["green"]
c.colors.statusbar.insert.fg = palette["bg0"]
c.colors.statusbar.passthrough.bg = palette["blue"]
c.colors.statusbar.passthrough.fg = palette["bg0"]
c.colors.statusbar.caret.bg = palette["purple"]
c.colors.statusbar.caret.fg = palette["bg0"]
c.colors.statusbar.caret.selection.bg = palette["orange"]
c.colors.statusbar.caret.selection.fg = palette["bg0"]
c.colors.statusbar.private.bg = palette["bg1"]
c.colors.statusbar.private.fg = palette["purple"]
c.colors.statusbar.command.bg = palette["bg1"]
c.colors.statusbar.command.fg = palette["fg"]
c.colors.statusbar.command.private.bg = palette["bg1"]
c.colors.statusbar.command.private.fg = palette["purple"]
c.colors.statusbar.progress.bg = palette["blue"]
c.colors.statusbar.url.fg = palette["fg"]
c.colors.statusbar.url.error.fg = palette["red"]
c.colors.statusbar.url.hover.fg = palette["aqua"]
c.colors.statusbar.url.success.http.fg = palette["fg"]
c.colors.statusbar.url.success.https.fg = palette["green"]
c.colors.statusbar.url.warn.fg = palette["yellow"]

# Tabs: selected tabs use tmux's active-window yellow. Pinned tabs are aqua,
# while their selected state stays consistent with ordinary selected tabs.
# private_tabs.py overrides the selected tab to red in private windows only.
c.colors.tabs.bar.bg = palette["bg0"]
c.colors.tabs.odd.bg = palette["bg0"]
c.colors.tabs.odd.fg = palette["fg"]
c.colors.tabs.even.bg = palette["bg1"]
c.colors.tabs.even.fg = palette["fg"]
c.colors.tabs.selected.odd.bg = palette["yellow"]
c.colors.tabs.selected.odd.fg = palette["bg0"]
c.colors.tabs.selected.even.bg = palette["yellow"]
c.colors.tabs.selected.even.fg = palette["bg0"]
c.colors.tabs.pinned.odd.bg = palette["bg2"]
c.colors.tabs.pinned.odd.fg = palette["aqua"]
c.colors.tabs.pinned.even.bg = palette["bg1"]
c.colors.tabs.pinned.even.fg = palette["aqua"]
c.colors.tabs.pinned.selected.odd.bg = palette["yellow"]
c.colors.tabs.pinned.selected.odd.fg = palette["bg0"]
c.colors.tabs.pinned.selected.even.bg = palette["yellow"]
c.colors.tabs.pinned.selected.even.fg = palette["bg0"]
c.colors.tabs.indicator.start = palette["blue"]
c.colors.tabs.indicator.stop = palette["green"]
c.colors.tabs.indicator.error = palette["red"]
c.colors.tabs.indicator.system = "rgb"

# Leave websites at browser defaults. Gruvbox is opt-in via ,d only
# (greasemonkey/gruvbox-dark.user.js); keep Chromium's inversion disabled.
c.colors.webpage.preferred_color_scheme = "auto"
c.colors.webpage.darkmode.enabled = False
c.colors.webpage.bg = "white"

# Press comma, then d to toggle Gruvbox rendering for this site. The script
# remembers the choice in site storage; reload to update embedded frames too.
config.bind(
    ",d",
    "jseval --world main window.__quteGruvboxDark ? "
    "window.__quteGruvboxDark.toggle() : 'Gruvbox dark mode is not loaded.'",
)

# YouTube's optional Greasemonkey ad skipper can be disabled for the current
# tab without removing its file. A page reload enables it again.
config.bind(
    ",a",
    "jseval --world main window.__quteYoutubeAdSkip ? "
    "window.__quteYoutubeAdSkip.toggle() : 'Ad skipping is not loaded in this tab.'",
)

# Display PDFs in the browser using PDF.js (Arch package: pdfjs).
# The viewer still offers a download button. Local .html files render with
# :open ~/path/file.html; relative CSS, images, and JavaScript use defaults.
c.content.pdfjs = True
# PDF.js 6 needs a startup-script CSP hash and WeakMap/math compatibility shims.
from pathlib import Path
import shlex

config.source(str(Path(__file__).resolve().with_name("pdf_viewer.py")))
config.source(str(Path(__file__).resolve().with_name("private_tabs.py")))

# Optional browser tools. Comma-prefixed keys preserve the normal bindings.
# Reader mode uses the local Python environment (or python-readability-lxml).
# Translation opens Google Translate only when requested; English is the
# default target language.
# Pass a language to :translate / :translate-selection, e.g. :translate si.
browser_tools_dir = Path(__file__).resolve().parent
browser_tools_python = browser_tools_dir / ".reader-venv" / "bin" / "python"
browser_tools = "spawn --userscript "
if browser_tools_python.is_file():
    browser_tools += shlex.quote(str(browser_tools_python)) + " "
browser_tools += shlex.quote(str(browser_tools_dir / "userscripts" / "browser-tools"))
config.bind(",D", browser_tools + " downloads")
config.bind(",r", browser_tools + " reader")
config.bind(",t", browser_tools + " translate")
for mode in ("normal", "caret"):
    config.bind(",T", browser_tools + " translate --selection", mode=mode)
config.bind(",m", "spawn --detach mpv -- {url}")
config.bind(",M", "hint links spawn --detach mpv -- {hint-url}")
config.bind(",v", "spawn --verbose yt-dlp --no-playlist -P /home/rivindu02/Downloads -- {url}")
config.bind(",V", "hint links spawn --verbose yt-dlp --no-playlist -P /home/rivindu02/Downloads -- {hint-url}")
# Report early launch errors and request a visible window, including when
# Brave already has background/app windows. The userscript detaches safely.
config.bind(",b", browser_tools + " brave")

# Preserve the built-in aliases (including :wq) and any saved user aliases.
browser_aliases = dict(c.aliases)
browser_aliases.update({
    "downloads": browser_tools + " downloads",
    "reader": browser_tools + " reader",
    "translate": browser_tools + " translate",
    "translate-selection": browser_tools + " translate --selection",
})
c.aliases = browser_aliases

# Search imported bookmarks with b; B opens the selection in a new tab.
# qutebrowser's defaults use these keys for quickmarks, a separate collection.
# The -s flag adds the space needed to complete the first bookmark argument.
config.bind("b", "cmd-set-text -s :bookmark-load")
config.bind("B", "cmd-set-text -s :bookmark-load -t")

# Bitwarden: first run bw login in a terminal. Ctrl+Shift+L finds the login
# fields and fills username + password; Ctrl+Alt+L fills only the password
# for two-step login pages. These shortcuts work in normal and insert modes.
# The unlock prompt is masked, and the session key expires after five minutes.
# The local fill helper uses a private temporary handoff, which is deleted
# after reading. Passwords are never sent to a username field or the clipboard.
config.source(str(Path(__file__).resolve().with_name("bitwarden_fill.py")))
bitwarden_script = Path(__file__).resolve().parent / "userscripts" / "bitwarden"
bitwarden_fill = "spawn --userscript " + shlex.quote(str(bitwarden_script))
for mode in ("normal", "insert"):
    config.bind("<Ctrl-Shift-l>", bitwarden_fill, mode=mode)
    config.bind("<Ctrl-Alt-l>", bitwarden_fill + " --password-only", mode=mode)

# Tab collections:
#   Ctrl+S       suggests an editable name; Enter saves and leaves tabs open.
#   Ctrl+Shift+S opens session completion; choose a collection and press Enter.
# Suggested names contain a timestamp; collections are kept after restoration.
# qutebrowser restores sessions in a new window. URLs, titles, and tab history
# are saved together; private windows are excluded. Keep history enabled:
# qutebrowser's no-history saver can omit the current-page marker.
# Session files live in qutebrowser's data directory, outside these dotfiles.
from qutebrowser.api import cmdutils
from qutebrowser.misc import objects

config.source(str(Path(__file__).resolve().with_name("command_enter.py")))
config.bind("<Return>", "command-enter-next", mode="command")
# Explicit bindings take priority over Ctrl+J's default mapping to Enter and
# Ctrl+K's default line-editing action while the command/completion bar is open.
config.bind("<Ctrl-j>", "completion-item-focus next", mode="command")
config.bind("<Ctrl-k>", "completion-item-focus prev", mode="command")

# :config-source executes this file again; replace our command on reload.
objects.commands.pop("tabs-shelve", None)
objects.commands.pop("tabs-save", None)


@cmdutils.register(name="tabs-save")
@cmdutils.argument("win_id", value=cmdutils.Value.win_id)
def tabs_save(win_id: int):
    """Suggest an editable collection name before saving the current tabs."""
    from datetime import datetime

    from qutebrowser.utils import objreg

    browser = objreg.get("tabbed-browser", scope="window", window=win_id)
    if browser.is_private:
        raise cmdutils.CommandError("Private tabs are not saved to collections.")

    tabs = list(browser.widgets())
    if not tabs:
        return

    name = datetime.now().strftime("tabs-%Y-%m-%d-%H%M%S-%f")
    command = objreg.get("status-command", scope="window", window=win_id)
    command.cmd_set_text(
        ":session-save --only-active-window " + name
    )


# Normal mode only, so Ctrl+S in a text field remains available to the page.
config.bind("<Ctrl-s>", "tabs-save")
# Include custom collection names as well as timestamped names in completion.
config.bind("<Ctrl-Shift-s>", "cmd-set-text -s :session-load --temp")
