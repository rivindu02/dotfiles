# mpv controls

This setup combines VLC shortcuts with Vim-style playback navigation and uosc
menus. Restart mpv after changing configuration files.

`~/.config/mpv` links to this directory in the dotfiles repository.

## Menus and files

| Key | Action |
| --- | --- |
| `p` | Playlist, including when only one file is loaded |
| `o` | Browse files with uosc |
| `w` | Continue Watching: files with saved playback positions |
| `c` | Chapters |
| `F1` | Main menu |
| `n` | Next playlist item, or next media file in the folder |
| `Shift+p` | Previous playlist item, or previous media file in the folder |

The toolbar's Playlist/Files button shows the playlist when there are multiple
items; otherwise, it browses files. The `p` shortcut always shows the playlist.

In uosc menus, use arrow keys to navigate, `Enter` to select, `/` or `Ctrl+f` to
search, and `Esc` to leave search or close the menu. Vim `h/j/k/l` mappings apply
to playback; use arrows inside menus. The Continue Watching menu uses mpv's
built-in selector and supports typing to filter.

## Playback and volume

| Key | Action |
| --- | --- |
| `Space` | Play/pause |
| `j`, `Down`, `Ctrl+Down` | Volume down 5 percentage points |
| `k`, `Up`, `Ctrl+Up` | Volume up 5 percentage points |
| `m` | Mute/unmute |
| `f` | Toggle fullscreen |
| `Esc` | Leave fullscreen when no menu is active |
| `t` | Show playback position |
| `q`, `Ctrl+q` | Quit and save playback position |

## Seeking

| Key | Action |
| --- | --- |
| `h` / `l`, `Left` / `Right` | Backward / forward 5 seconds |
| `H` / `L` (`Shift+h` / `Shift+l`) | Backward / forward 1 minute |
| `Shift+Left` / `Shift+Right` | Backward / forward 3 seconds |
| `Alt+Left` / `Alt+Right` | Backward / forward 10 seconds |
| `Ctrl+Left` / `Ctrl+Right` | Backward / forward 1 minute |
| `Ctrl+Alt+Left` / `Ctrl+Alt+Right` | Backward / forward 5 minutes |
| `Ctrl+u` / `Ctrl+d` | Backward / forward 30 seconds |
| `gg`, `0` | Jump to the start (`gg` means press `g` twice) |
| `G` (`Shift+g`) | Jump to the end |
| `u`, `Shift+Backspace` | Undo the previous seek |
| `PageUp` / `PageDown` | Next / previous chapter |
| `e` | Advance one frame and pause |

Jumping to the end leaves the final frame visible because `keep-open=yes`.

## Speed, repeat, tracks, and screenshots

| Key | Action |
| --- | --- |
| `[` / `]` | Reduce / increase speed by 0.1 |
| `+` / `-` | Multiply speed by 1.5 / approximately 0.667 |
| `=`, `Backspace` | Reset speed to 1x |
| `Ctrl+l` | Mark A, then B to loop a section; press again to clear |
| `b` | Cycle audio tracks |
| `v` | Cycle subtitles |
| `Alt+k` / `Alt+j` | Delay / advance audio by 0.05 seconds |
| `(` / `)` | Show subtitles 0.05 seconds earlier / later to sync with audio |
| `s` | Screenshot with subtitles |
| `Ctrl+s` | Screenshot of the window, including the interface |
| `i` / `Shift+i` | Show / toggle playback statistics |
| `?` (`Shift+/`) | Toggle your shortcut guide; disabled defaults are excluded |

The toolbar also provides speed adjustment, repeat-current-file, and track
selection. Chapter and extra track buttons appear when relevant to the file.

The `?` help menu reads the shortcut tables above from this README each time it
opens. Browse by category or press `/` to search. It describes shortcuts without
running them. Keep these tables updated when editing `input.conf`.

## Disabled advanced defaults

`input-builtin-bindings=no` in `mpv.conf` turns off mpv's stock shortcuts.
`input-default-bindings=yes` keeps script callbacks and menu controls working.
Playback shortcuts are explicitly listed in `input.conf`; script-managed menus
and the uosc interface keep their own navigation controls.

Legacy shortcuts such as `x`, `z`, `Z`, `.`, `,`, `/`, `9`, and `*` have no
playback action. Picture adjustments, pan/zoom, decoder toggles, subtitle styling,
and continuous screenshots are also disabled. `/` still starts search inside
uosc menus.

The Vim, arrow-key, and VLC aliases documented above remain intentional.
Mouse-wheel volume, double-click fullscreen, media play/pause, next/previous,
volume/mute, and closing the window are explicitly retained in `input.conf`.
Dedicated Play and Pause media keys explicitly play and pause; the combined
Play/Pause key toggles playback. The old `Alt+g`/`Alt+h` subtitle-sync aliases are
disabled; use `(`/`)` instead.

## Configuration files and backups

- `input.conf`: the explicit list of enabled playback shortcuts.
- `mpv.conf`: video, window, fonts, and playback resume settings.
- `script-opts/uosc.conf`: toolbar, menu behavior, and theme overrides.
- `scripts/uosc/`: installed uosc interface.
- `scripts/shortcut-help.lua`: the `?` help menu, built from this README.

New configuration backups are saved under `~/.local/state/mpv/config-backups/`.
Earlier session backups remain in this directory's `backups/` folder.

To restore another shortcut, add its key and command to `input.conf` and restart mpv.
To change a shortcut, edit its existing line rather than adding a duplicate.
