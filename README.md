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
