# qutebrowser on this desktop

The active `~/.config/qutebrowser/config.py` points into this directory. Keep
the Python/JavaScript helpers and `userscripts` alongside the real config.
Existing explanatory comments are retained in `config.py`.

Normal windows have a yellow selected tab; private windows have a red selected
tab (`#ea6962`), including pinned tabs. The small `private_tabs.py` drawing
helper provides the private-window color separately from the shared tab theme.

Run `:config-source` after editing. Comma shortcuts are sequences in normal
mode: press comma, release it, then the listed letter. Uppercase needs Shift.

## Everyday features

| Shortcut | Action |
| --- | --- |
| `gi` / `;t` | Focus the first visible text field / show hints to choose one (includes custom search/text widgets) |
| `,D` or `:downloads` | Pick a downloaded file in Rofi and open it in its associated application |
| `,r` or `:reader` | Extract the current article locally into a new reader tab |
| `,t` or `:translate` | Open the current page in Google Translate, targeting English |
| `,T` or `:translate-selection` | Translate selected text; also available in caret mode |
| `,m` | Open the current video/page in mpv |
| `,M` | Show link labels, then type the label on a video link to open it in mpv |
| `,v` | Download the current video with yt-dlp to `~/Downloads` |
| `,V` | Show link labels, then choose a video link to download to `~/Downloads` |
| `,b` | Open the current page in a new Brave window; report early launch errors |
| `,d` | Toggle Gruvbox webpage dark mode for this site (reloads except on YouTube) |
| `,a` | Toggle YouTube ad skipping in the current tab; reloading enables it again |
| `b` / `B` | Search bookmarks, opening in current / new tab |
| `Ctrl+J` / `Ctrl+K` | Move down / up in command-bar completion lists |
| `Ctrl+S` | Edit the suggested collection name, then Enter to save; tabs stay open |
| `Ctrl+Shift+S` | Pick a saved collection to restore in a new window |
| `Ctrl+Shift+L` | Fill a Bitwarden login (normal/insert modes) |
| `Ctrl+Alt+L` | Fill only the Bitwarden password (normal/insert modes) |

Tabs restore automatically after quitting/reopening. The `default` session is
the automatic save target; named collections remain separate. Ctrl+S suggests
a timestamped name which you can replace (quote names containing spaces).
Private windows are excluded by qutebrowser's normal session-saving rules.

`gi` looks within the visible part of the page. Scroll the search box into view
and open any collapsed search panel first. If several fields are visible, use
`;t` to choose one. Fields inside cross-origin frames or closed shadow roots
can still require clicking manually.
On GitHub, the search dialog launcher also counts as an input hint, so `gi`
can open it before the actual search field exists.

## Search shortcuts

In the command bar, Enter after a command missing a required argument advances
to argument completion. Press Enter again to select a completion, then Enter
to run the completed command. Tab still cycles completions as usual.

Press `o` for this tab or `O` for a new tab, then enter a shortcut and query:

| Example | Search |
| --- | --- |
| `!yt linux tutorial` | YouTube |
| `!gh qutebrowser` | GitHub |
| `!aw bluetooth` | ArchWiki |
| `!apkg mpv` | Arch packages |
| `!goog qtwebengine` | Google |
| `!gpt explain systemd` | ChatGPT (also `!chatgpt`) |
| `!claude explain systemd` | Claude |

Unprefixed queries use DuckDuckGo, explicitly set in `config.py`.
Its other bang shortcuts also remain available.
Use a shortcut alone (such as `!claude` or `!aw`) to open its homepage.

AI shortcuts open the provider with your query in its URL. Signing in and
pressing Enter may be required; these website URL parameters can change.

## Optional tools and dependencies

- **PDF viewer:** requires Arch's `pdfjs` package. `pdf_viewer.py` authorizes
  qutebrowser's startup script under PDF.js 6's Content Security Policy and
  supplies missing WeakMap methods and `Math.sumPrecise` for QtWebEngine 6.11.
  The math helper preserves exact summation and only installs if the browser
  lacks that API. Keep `pdf-math-polyfill.js` alongside `pdf_viewer.py`.
  The internal `qute://pdfjs/*` pages have a local-resource exception so the
  viewer can load its CSS, modules, and worker. Ordinary local HTML stays blocked.
  After changing this helper, run `:config-source` and reload the PDF tab.
- **Webpage dark mode:** Off by default. Websites use their own appearance,
  browser-default color preference and page background. Press `,d` to opt a site
  into Gruvbox, and again to restore its default appearance. Choices persist per
  origin; clearing site data resets them to off. Old automatic dark-mode
  preferences are ignored, so existing sites start with their defaults too.
  YouTube uses its native dark theme with a small Gruvbox stylesheet while
  enabled; disabling removes it, restores the original native theme flag, and
  stops watching/enforcing theme changes. Video/images are never filtered.
  Other HTTP(S) pages initialize bundled Dark Reader 4.9.134 only when enabled
  (MIT; license in `vendor/darkreader-LICENSE`); toggling reloads the page.
  Frames on other origins keep their own choice. Cross-origin stylesheets still
  need the site's normal CORS permission. Chromium's forced inversion is off.
  Browser internal pages, local files, and the PDF viewer retain their styles.
  The script must be linked into `~/.config/qutebrowser/greasemonkey` alongside
  the YouTube helper. Run `:config-source`, then `:greasemonkey-reload` and reload
  open webpages after installation. A restart also loads everything.
- **YouTube ad skipping:** `greasemonkey/youtube-adskip.user.js` clicks visible
  Skip buttons and speeds up/mutes playback only while YouTube marks its player
  as showing an ad. It restores playback speed/muting afterward and never seeks
  the video. It also handles YouTube's navigation between videos. This is an
  ad-skipping trial; ads can still load, and YouTube changes can break it.
  Use `,a` to turn it off for the current tab. To disable permanently, rename the
  installed `.js` file/link to end in `.disabled`, run `:greasemonkey-reload`,
  and reload YouTube. The config's `greasemonkey` directory must be linked into
  `~/.config/qutebrowser/greasemonkey` if that config directory is not itself
  symlinked to these dotfiles.
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
  and are deleted after five minutes by a detached cleanup process. Loaded tabs
  remain readable, but reopening/reloading an expired file requires extracting
  the article again. Bookmark the **original page** for later use. Multiple
  reader tabs use separate files.
- **Translation:** no extra package. Page/selected text is sent to Google
  Translate only when invoked. Choose another target with `:translate si`,
  `:translate ta`, or `:translate-selection si`; source language is automatic.
  Page translation needs a remotely accessible HTTP(S) page. For local files
  or login-only content, select text instead. This opens a translation tab;
  it does not replace the original page or translate pages in the background.
- **Video:** requires `mpv` and `yt-dlp` (already installed). Opens playback in
  mpv; pause the browser's player if it was already playing. Sites requiring
  authentication may need additional mpv/yt-dlp configuration.
- **Brave:** requires `brave` (already installed). `,b` requests a new window
  and reports missing executable/early startup errors in qutebrowser. The
  detached browser survives qutebrowser quitting. PDF viewer links use their
  original source URL; other internal pages show an explanatory error.
  Opening a page does not transfer qutebrowser's cookies/login session into
  Brave. Errors occurring more than two seconds after launch are outside the
  startup check. Window focus and workspace placement follow compositor rules.

Reader extraction follows the bundled qutebrowser `readability` userscript's
approach, using [python-readability](https://github.com/buriy/python-readability).
The [official userscripts list](https://github.com/qutebrowser/qutebrowser/blob/main/misc/userscripts/README.md)
provides the downloads/reader ideas; translation follows
[Qute-Translate](https://github.com/AckslD/Qute-Translate) with URL encoding.

## Checks after upgrades

The current helpers have been checked against qutebrowser 3.7.0 and QtWebEngine
6.11.3. `pdf_viewer.py`, `private_tabs.py`, and `command_enter.py` use private
upstream APIs; review those integrations on every upgrade. The bundled Dark
Reader 4.9.134 is old and runs in the main JavaScript world; keep its license
and rerun the dark-mode tests when re-vendoring it. It initializes only on
sites where dark mode was explicitly enabled.

From the dotfiles repository, run `python .githooks/check-qutebrowser` after
updating qutebrowser, QtWebEngine, PDF.js, or Python. It uses the reader's local
Python environment when available and runs each suite separately because Qt
and qutebrowser configuration are process-wide. Tests use temporary profiles
and synthetic pages; they do not access your browsing profile or vault.

The PDF checks verify required browser APIs, the viewer startup CSP hash,
worker polyfills, precise summation, config reloads, and painting a real PDF
with the installed PDF.js. They also load the full internal viewer through the
Qutebrowser URL handler, checking its stylesheet, modules, and PDF page while
ordinary local HTML remains restricted. Chromium's process sandbox must be able to start.
These checks catch known failure paths; website changes and future upstream
API changes can still require maintenance. After a Python major upgrade,
recreate `.reader-venv` using the setup instructions above if reader imports fail.

## Security and privacy

`config.py` limits WebRTC to the default public interface, disables local
HTML access to other file URLs, speculative DNS lookups, and autoplay.
This also blocks relative stylesheets, images, and external JavaScript in local
HTML pages. For a trusted file that needs those assets, open it and use its
actual file URL in a temporary exception, then reload:

```text
:set -t -u file:///absolute/path/page.html content.local_content_can_access_file_urls true
:reload
```

The exception applies to that file URL until the browser closes, and lets the
page read other local files too. Restore the restriction when finished with
`:set -t -u file:///absolute/path/page.html content.local_content_can_access_file_urls false`,
then reload. Closing just the tab does not clear the exception.
Reader mode's inline styles still work; local image files in articles are blocked.

Restart the browser to apply the WebRTC setting. Canvas reading and third-party
cookies retain their defaults for site compatibility; consider site-specific
restrictions if needed. Review persistent clipboard, notification, and protocol
handler grants in `:set` / `autoconfig.yml` and revoke unused grants through
qutebrowser rather than editing its generated file.

`content.tls.certificate_errors = "ask-block-thirdparty"` automatically blocks
invalid background/resource connections. Direct page visits still ask whether
to bypass certificate errors: answer **no** for untrusted certificates.
Answering yes intentionally bypasses validation and can make the incident
checker report insecure connections. Accepted exceptions can remain cached
for the running browser session; fully quit and restart before rechecking.

Bitwarden passes its session via `BW_SESSION` to `bw` and stdin to `keyctl`,
keeping it out of command-line arguments. Same-user processes can still read
the environment/keyring. Picker rows handle null usernames and delimiters;
merged matches are deduplicated by item ID.

For the eMudhra incident, `python .config/qutebrowser/distrust-emudhra.py`
from the repo root applies the checksum-pinned NSS mitigation from
[upstream issue #9032](https://github.com/qutebrowser/qutebrowser/issues/9032).
It verifies and distrusts 16 certificates (eight keys plus cross-signs) in
`~/.pki/nssdb`. Fully restart all QtWebEngine applications, then run every check
on the [incident test page](https://emudhra.we-have-a-problem.com/) and inspect
failures directly. Upstream has a report of incomplete rejection on 3.7.0;
using `main` is not a verified general fix. Use an updated browser that rejects
all test chains for sensitive work until a fixed QtWebEngine build is verified.

Local verification on 2026-11-06, after applying all 16 distrust entries:
the installed QtWebEngine 6.11.3 rejected all 14 public TLS test hosts with
certificate errors, including both No CT hosts, in a fresh offscreen profile;
`https://example.org` loaded as a valid control. This checks the installed
engine, not an already running qutebrowser process: restart and recheck there.

Follow-up: the running browser's checker initially reported insecure results
after certificate prompts had been accepted. The user confirmed it rejected
the chains when those prompts were declined. This was an explicit validation
bypass, not evidence that the NSS entries were being ignored. Background
certificate prompts are now disabled as described above. An explored handler
workaround was removed; no extra TLS monkeypatch is needed for this behavior.
