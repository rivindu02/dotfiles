# My dotfiles

Arch Linux + Hyprland setup, managed with GNU Stow.

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
```

## System files (need sudo)

```bash
# Keep pkglist.txt / aurlist.txt in sync on every pacman transaction
sudo install -Dm644 system/pacman/hooks/pkglist.hook /etc/pacman.d/hooks/pkglist.hook

# Firewall (default-deny inbound; Tailscale, Docker/Podman, LocalSend allowed)
sudo install -Dm644 system/nftables/nftables.conf /etc/nftables.conf
sudo systemctl enable --now nftables

# udev: battery charge limit 80%, suspend at 5%
sudo install -Dm644 system/udev/99-battery-threshold.rules system/udev/99-lowbat.rules -t /etc/udev/rules.d/

# ASUS camera key daemon, sleep hook
sudo install -Dm755 system/systemd/camera-toggle-daemon.sh /usr/local/bin/camera-toggle-daemon.sh
sudo install -Dm755 system/systemd/asus-sleep.sh /usr/lib/systemd/system-sleep/asus-sleep.sh
sudo install -Dm644 system/systemd/camera-toggle.service -t /etc/systemd/system/
sudo systemctl enable --now camera-toggle

# SDDM theme
sudo install -Dm644 system/sddm/theme.conf /usr/share/sddm/themes/sugar-candy/theme.conf
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
