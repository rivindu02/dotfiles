# My dotfiles

Arch Linux + Hyprland setup, managed with GNU Stow.

Every installed tool, keybinding and script is explained in [TOOLS.md](TOOLS.md).

## Layout

| Path | Stowed to | Notes |
|---|---|---|
| `.config/*` | `~/.config/*` | App configs (hypr, waybar, nvim, rofi, swaync, …) |
| `.config/scripts/` | `~/.config/scripts/` | Helper scripts called by Hyprland/Waybar/systemd |
| `scripts/.local/bin/` | `~/.local/bin/` | CLI tools (`sysclean`, `tailscale-menu`, `secure-perms`, …) |
| `zsh/`, `git/`, `ssh/` | `~/` | Stow packages: `.zshrc`, `.gitconfig`, `~/.ssh/config` |
| `system_prefs/` | `~/` | `mimeapps.list` |
| `system/` | *not stowed* | Root-owned files for `/etc` and `/usr/local/bin` (see below) |
| `pkglist.txt`, `aurlist.txt` | *not stowed* | Auto-updated by `system/pacman/hooks/pkglist.hook` |

## Install

```bash
sudo pacman -S --needed git stow
git clone git@github.com:rivindu02/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Packages
sudo pacman -S --needed - < pkglist.txt
yay -S --needed - < aurlist.txt

# Symlinks
stow zsh git ssh scripts system_prefs
stow .            # .config/* (see .stow-local-ignore)

# Lock down secret files (git doesn't preserve permissions)
secure-perms

# Pre-commit secret scanner
git config core.hooksPath .githooks

# Keep generated calendar/weather text out of commits (swaync config.json)
git config filter.swaync-strip.clean "python3 .githooks/swaync-strip.py"
git config filter.swaync-strip.smudge cat
git config filter.swaync-strip.required true
```

The calendar/weather clean filter requires Python 3 and the Git settings above
in each clone. Invalid JSON or unsupported widget structures block staging with
a redacted error; the working file is left intact. Fix the JSON and stage it
again rather than disabling the required filter. This protects generated widget
text, not arbitrary secrets elsewhere in the file or existing Git history.

Run its isolated checks (synthetic data only; no desktop reload needed):

```bash
python3 .githooks/tests/test_swaync_strip.py
```

## Default browser

Edit `~/.config/browser/default` (`.config/browser/default` in this repo) to
choose the browser in one place. It currently contains `qutebrowser`; supported
commands are `qutebrowser`, `brave` (also `brave-browser`,
`brave-browser-stable`, `brave-browser-nightly`), `firefox`, and `chromium`.

`default-browser` reads that file on every launch. Hyprland's `SUPER+B`, web
searches, private searches, Yazi's web-file opener, and the default
link/HTML/PDF associations all use it. Hyprland also sets
`BROWSER` to this launcher for applications that consult the environment.
After the initial Stow setup and Hyprland reload, changing the file takes
effect on the next launch without restowing, reloading, or running
`xdg-settings` again.

`SUPER+SHIFT+B` opens qutebrowser's live bookmarks page. With Brave selected it
uses the existing Rofi bookmark manager (close Brave before adding entries).
This shortcut supports qutebrowser and Brave; bookmarks are not migrated when
switching. Installed web apps (WhatsApp, YouTube, NotebookLM, Google Calendar,
Maps, Photos, and Tailscale) and the Waybar calendar shortcut open qutebrowser
app windows without tab/status bars, independently of the default browser
selection. `qute-webapp` uses a separate persistent profile shared by the web
apps at `~/.local/share/qutebrowser-webapps` (or `$XDG_DATA_HOME/qutebrowser-webapps`).
The launcher keeps that profile and its `download/` directory private (mode 700)
and starts the browser with a restrictive file-creation mask.
App windows use the separate `org.qutebrowser.webapps` Wayland class, so the
normal browser's workspace-1 rule does not match them; they open on the current
workspace. After changing the app launcher's class, close all app windows and
relaunch so the existing app process picks up the new identity.
App links requesting new tabs open new windows, and app launches do not restore
the normal browser session. Sign in once in this app profile; normal browser
cookies are separate. Their desktop entries
retain the existing IDs and icons; sign in again using qutebrowser when needed.
Qutebrowser's `,b` shortcut opens the current page in Brave.

Check the selection with `default-browser --print`, open a URL with
`default-browser https://example.org`, or use
`default-browser --private https://example.org` for a private window.

## System files (need sudo)

```bash
# Keep pkglist.txt / aurlist.txt in sync on every pacman transaction
sudo install -Dm644 system/pacman/hooks/pkglist.hook /etc/pacman.d/hooks/pkglist.hook

# Firewall (default-deny inbound; Tailscale, Docker/Podman, LocalSend allowed)
sudo install -Dm644 system/nftables/nftables.conf /etc/nftables.conf
sudo systemctl enable --now nftables

# udev: suspend at 5% (charge limit is asusd's job: asusctl battery limit 80)
sudo install -Dm644 system/udev/99-lowbat.rules -t /etc/udev/rules.d/

# ASUS camera key daemon, sleep hook
sudo install -Dm755 system/systemd/camera-toggle-daemon.sh /usr/local/bin/camera-toggle-daemon.sh
sudo install -Dm755 system/systemd/asus-sleep.sh /usr/lib/systemd/system-sleep/asus-sleep.sh
sudo install -Dm644 system/systemd/camera-toggle.service -t /etc/systemd/system/
sudo systemctl enable --now camera-toggle

# Hardening + privacy (sysctl, no core dumps, LLMNR off, DNS-over-TLS, MAC randomization,
# uinput group, reflector): see the script for details
sudo bash system/apply-security-hardening.sh

# SDDM theme
sudo install -Dm644 system/sddm/theme.conf /usr/share/sddm/themes/sugar-candy/theme.conf

# Seagate backup HDD: use usb-storage instead of UAS (UAS drops it mid-write)
sudo bash system/apply-hdd-no-uas.sh

# LUKS header copy onto the backup HDD (HDD mounted)
sudo bash system/apply-luks-header-backup.sh
```

## Backups

Encrypted, deduplicated restic backups of `$HOME` to the uni OneDrive (uom.lk Microsoft 365, 100 GB), using rclone.
The exclude list is `.config/backup/excludes.txt`; to skip any folder, put an empty `.nobackup` file in it.

```bash
rclone config create uomdrive onedrive drive_type business access_scopes "Files.Read Files.ReadWrite Files.Read.All Files.ReadWrite.All offline_access"
# ↑ opens a browser: sign in with your @uom.lk account
backup-home init                                       # SAVE the printed password off-laptop
backup-home dry-run                                    # preview size
backup-home run --force                                # first backup
systemctl --user enable --now backup-home.timer        # then automatic (daily, on AC)
```

Restore: `backup-home restic restore latest --target ~/restore --include ~/Documents`

## Secrets

Secrets never go into git. API keys live in gnome-keyring: add them with `apikey set <name>`, list them with `apikey list`. The AI wrappers in `.zshrc` fetch a key only when a tool runs, so the keyring unlock prompt appears at most once per boot. `.githooks/pre-commit` blocks commits that contain tokens or sensitive paths.

Credential-path guards cover these locations at the repository root and inside
individual Stow packages:

- AWS `credentials`, `config`, and SSO/CLI/login credential caches under `.aws/`.
- `.config/rclone/rclone.conf` (also `.old`/`.bak`) and `.config/restic/password`.
- GitHub CLI `hosts.yml`, the calendar auth directory, and `.local/share/keyrings/`.
- `.claude/.credentials.json`, `.codex/auth.json`, `.gemini/oauth_creds.json`,
  `.npmrc`, and `.netrc`.

Git ignores these paths; the enabled pre-commit hook also blocks them after
`git add --force`. AWS `config` and `.npmrc` are treated as potentially private;
use sanitized `.example` templates when documenting them. Ordinary settings
such as `gh/config.yml`, `backup/excludes.txt`, Claude settings, Codex config,
and Gemini settings remain trackable. A private-store entry ending in `.pub`
is still blocked; public SSH keys outside those stores pass the hook.

Nvim disables automatic persistent undo and swap for protected paths, including
new files and renamed buffers. Its targeted `backupskip` entries also suppress
backup/writebackup copies without changing ordinary buffers. Restart Nvim to
load the updated options. Existing undo, swap, backup, and history data is not
removed. These are path-based safeguards; renamed copies and nonstandard
credential locations need explicit rules, and local hooks can be bypassed.

Run the synthetic credential checks with Python 3, Git, Bash, and Nvim:

```bash
python3 .githooks/tests/test_credential_paths.py
```

The tests use temporary Git repositories and plugin-free headless Nvim, with
isolated editor state. They do not read real credentials. Without Nvim, editor
tests are reported as skipped; a complete validation requires them to pass.
