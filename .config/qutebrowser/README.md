# qutebrowser on this desktop

The active `~/.config/qutebrowser/config.py` points into this directory. Keep
the Python/JavaScript helpers and `userscripts` alongside the real config.
Existing explanatory comments are retained in `config.py`.

Run `:config-source` after editing. Comma shortcuts are sequences in normal
mode: press comma, release it, then the listed letter. Uppercase needs Shift.

## Everyday features

| Shortcut | Action |
| --- | --- |
| `,D` or `:downloads` | Pick a downloaded file in Rofi and open it in its associated application |
| `,r` or `:reader` | Extract the current article locally into a new reader tab |
| `,t` or `:translate` | Open the current page in Google Translate, targeting English |
| `,T` or `:translate-selection` | Translate selected text; also available in caret mode |
| `,m` | Open the current video/page in mpv |
| `,M` | Hint a video link to open in mpv |
| `,b` | Open the current page in Brave |
| `,d` | Toggle forced dark rendering and reload |
| `b` / `B` | Search bookmarks, opening in current / new tab |
| `Ctrl+S` | Shelve this window's tabs into a saved collection |
| `Ctrl+Shift+S` | Pick a saved collection to restore in a new window |
| `Ctrl+Shift+L` | Fill a Bitwarden login (normal/insert modes) |
| `Ctrl+Alt+L` | Fill only the Bitwarden password (normal/insert modes) |

Tabs restore automatically after quitting/reopening. The `default` session is
the automatic save target; timestamped `tabs-…` collections remain separate.
Private windows are excluded by qutebrowser's normal session-saving rules.

## Search shortcuts

Press `o` for this tab or `O` for a new tab, then enter a shortcut and query:

| Example | Search |
| --- | --- |
| `!yt linux tutorial` | YouTube |
| `!gh qutebrowser` | GitHub |
| `!aw bluetooth` | ArchWiki |
| `!apkg mpv` | Arch packages |
| `!g qtwebengine` | Google |
| `!w Sri Lanka` | English Wikipedia |

Unprefixed queries still use the existing default search engine (DuckDuckGo).
Its other bang shortcuts also remain available.

## Optional tools and dependencies

- **Downloads:** requires `rofi` and `xdg-open`. Uses qutebrowser's configured
  download directory, normally `~/Downloads`, newest files first. Existing
  download destination prompts are preserved. Esc cancels without an error.
- **Reader:** uses the local `.reader-venv` environment and `readability-lxml`.
  On another machine, recreate it with:

  ```sh
  python -m venv --system-site-packages ~/.config/qutebrowser/.reader-venv
  ~/.config/qutebrowser/.reader-venv/bin/python -m pip install -r ~/.config/qutebrowser/reader-requirements.txt
  ```

  The config falls back to system Python if the environment does not exist;
  Arch's `python-readability-lxml` package also works. Reader mode extracts the
  already loaded page without fetching it again. Sanitized article output has
  scripts/forms/frames disabled and uses the desktop font and Gruvbox colors.
  It works best on articles, not app interfaces. Reader files are temporary
  and last until logout/reboot; bookmark the **original page**, not the reader
  file, for later use. Multiple reader tabs use separate files.
- **Translation:** no extra package. Page/selected text is sent to Google
  Translate only when invoked. Choose another target with `:translate si`,
  `:translate ta`, or `:translate-selection si`; source language is automatic.
  Page translation needs a remotely accessible HTTP(S) page. For local files
  or login-only content, select text instead. This opens a translation tab;
  it does not replace the original page or translate pages in the background.
- **Video:** requires `mpv` and `yt-dlp` (already installed). Opens playback in
  mpv; pause the browser's player if it was already playing. Sites requiring
  authentication may need additional mpv/yt-dlp configuration.
- **Brave:** requires `brave` (already installed). Opening a page does not
  transfer qutebrowser's cookies/login session into Brave.

Reader extraction follows the bundled qutebrowser `readability` userscript's
approach, using [python-readability](https://github.com/buriy/python-readability).
The [official userscripts list](https://github.com/qutebrowser/qutebrowser/blob/main/misc/userscripts/README.md)
provides the downloads/reader ideas; translation follows
[Qute-Translate](https://github.com/AckslD/Qute-Translate) with URL encoding.
