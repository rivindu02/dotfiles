#!/usr/bin/env bash
# Round 2 of system changes (AUDIT.md §10). Safe to re-run.
# Usage: sudo bash ~/dotfiles/system/apply-round2.sh
set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "Run with sudo." >&2; exit 1; }
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

step() { printf '\n\e[1;34m==> %s\e[0m\n' "$1"; }
ok()   { printf '\e[1;32m  ✔ %s\e[0m\n' "$1"; }
warn() { printf '\e[1;33m  ⚠ %s\e[0m\n' "$1"; }

# ── 1. powertop (redundant with asusctl + power-profiles-daemon) ──
step "Remove powertop.service"
systemctl disable --now powertop.service 2>/dev/null || true
rm -f /etc/systemd/system/powertop.service
systemctl daemon-reload
systemctl reset-failed powertop.service 2>/dev/null || true
ok "Disabled and unit file removed"

# ── 2. RustDesk unattended access ─────────────────────────────
step "Disable rustdesk.service (app stays installed)"
systemctl disable --now rustdesk.service 2>/dev/null || true
ok "Unattended remote access off; start RustDesk from the app menu when needed"

# ── 3. Package removals / additions ───────────────────────────
step "Packages"
for p in polkit-gnome iwd; do
    if pacman -Qq "$p" &>/dev/null; then pacman -Rns --noconfirm "$p" >/dev/null && ok "Removed $p"; fi
done
pacman -S --needed --noconfirm fwupd shellcheck restic rclone >/dev/null
ok "Installed fwupd, shellcheck, restic, rclone"

# ── 4. SSD TRIM through LUKS + fstrim.timer ───────────────────
step "SSD TRIM"
LUKS_DEV=$(cryptsetup status cryptroot | awk '/device:/ {print $2}')
if [[ -n "$LUKS_DEV" ]]; then
    DUMP=$(cryptsetup luksDump "$LUKS_DEV")
    VER=$(awk '/^Version:/ {print $2}' <<< "$DUMP")
    if grep -q '^Flags:.*allow-discards' <<< "$DUMP"; then
        ok "LUKS already allows discards"
    elif [[ "$VER" == 2 ]]; then
        echo "  Enabling discards on LUKS2 (stored in the header, applies now and at every boot)."
        echo "  Enter your disk (LUKS) passphrase:"
        cryptsetup refresh --allow-discards --persistent cryptroot
        ok "Discards enabled on cryptroot"
    else
        warn "LUKS1: add ':allow-discards' to cryptdevice= in /etc/default/grub, then grub-mkconfig -o /boot/grub/grub.cfg"
    fi
fi
systemctl enable --now fstrim.timer >/dev/null 2>&1
ok "fstrim.timer enabled (weekly)"
if [[ "$(lsblk -dno DISC-GRAN /dev/mapper/cryptroot | tr -d ' ')" != "0B" ]]; then
    fstrim -v / || true
fi

# ── 5. paccache.timer ─────────────────────────────────────────
step "paccache.timer"
systemctl enable --now paccache.timer >/dev/null 2>&1
ok "Weekly pacman cache trim enabled (keeps last 3 versions)"

# ── 6. systemd-oomd ───────────────────────────────────────────
step "systemd-oomd"
install -Dm644 "$REPO/system/systemd/oomd/10-oomd-root-slice.conf" "/etc/systemd/system/-.slice.d/10-oomd-root-slice.conf"
install -Dm644 "$REPO/system/systemd/oomd/10-oomd-user-service.conf" "/etc/systemd/system/user@.service.d/10-oomd-user-service.conf"
systemctl daemon-reload
systemctl enable --now systemd-oomd.service >/dev/null 2>&1
ok "Enabled; monitoring: $(oomctl 2>/dev/null | grep -c 'Path:' || true) cgroup(s)"

# ── 7. Firmware check (does not install anything) ─────────────
step "Firmware updates (fwupd)"
fwupdmgr refresh --force >/dev/null 2>&1 || true
fwupdmgr get-updates 2>/dev/null | sed 's/^/    /' || echo "    No updates / device not supported"
echo "  Install any listed updates with: fwupdmgr update"

printf '\n\e[1;32mDone.\e[0m\n'
