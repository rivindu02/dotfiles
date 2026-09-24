#!/usr/bin/env bash
# Applies the root-level fixes from AUDIT.md §6. Safe to re-run.
# Usage: sudo bash ~/dotfiles/system/apply-system-fixes.sh
set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "Run with sudo." >&2; exit 1; }
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STAMP=$(date +%Y%m%d-%H%M%S)

step() { printf '\n\e[1;34m==> %s\e[0m\n' "$1"; }
ok()   { printf '\e[1;32m  ✔ %s\e[0m\n' "$1"; }

# ── 1. Firewall ────────────────────────────────────────────────
step "Firewall (nftables)"
# After a kernel upgrade without reboot, the running kernel's modules are gone
# and nft_ct (needed for `ct state`) can't load: the check fails with ENOENT
if [[ ! -d "/lib/modules/$(uname -r)" ]]; then
    echo "  ✖ Running kernel $(uname -r) has no modules installed (upgraded to" \
         "$(ls /lib/modules | tr '\n' ' ')without reboot). Reboot, then re-run." >&2
    exit 1
fi
nft -c -f "$REPO/system/nftables/nftables.conf"
ok "Ruleset syntax valid"

if [[ -f /etc/nftables.conf ]] && ! cmp -s "$REPO/system/nftables/nftables.conf" /etc/nftables.conf; then
    cp -a /etc/nftables.conf "/etc/nftables.conf.bak-$STAMP"
    ok "Backed up old config → /etc/nftables.conf.bak-$STAMP"
fi
install -Dm644 "$REPO/system/nftables/nftables.conf" /etc/nftables.conf

# Arch's default config used `table inet filter` (ssh-only); drop it if loaded
if nft list table inet filter &>/dev/null; then
    nft delete table inet filter
    ok "Removed stale 'inet filter' table from Arch default config"
fi

systemctl enable nftables.service >/dev/null 2>&1
nft -f /etc/nftables.conf
ok "Firewall active and enabled at boot"

# Auto-rollback if connectivity broke and nobody answers
echo
echo "  Check that networking still works (browser, tailscale ping, etc.)."
if read -r -t 60 -p "  Keep the firewall? [y/N] (auto-rollback in 60s) " ans && [[ "$ans" =~ ^[yY] ]]; then
    ok "Firewall kept"
else
    echo
    nft delete table inet host_firewall
    systemctl disable nftables.service >/dev/null 2>&1
    echo "  ↺ Rolled back: firewall removed and disabled"
fi

# ── 2. Camera toggle daemon ────────────────────────────────────
step "Camera toggle daemon"
if ! cmp -s "$REPO/system/systemd/camera-toggle-daemon.sh" /usr/local/bin/camera-toggle-daemon.sh; then
    install -Dm755 "$REPO/system/systemd/camera-toggle-daemon.sh" /usr/local/bin/camera-toggle-daemon.sh
    systemctl restart camera-toggle.service
    ok "Updated and restarted (now uses stable by-path device)"
else
    ok "Already up to date"
fi

# ── 3. gitleaks for the pre-commit hook ────────────────────────
step "gitleaks"
pacman -S --needed --noconfirm gitleaks >/dev/null
ok "Installed ($(gitleaks version 2>/dev/null))"

# ── 4. Keep running kernel's modules across upgrades ───────────
step "kernel-modules-hook"
pacman -S --needed --noconfirm kernel-modules-hook >/dev/null
systemctl enable linux-modules-cleanup.service >/dev/null 2>&1
ok "Installed: modules survive kernel upgrades until next reboot"

# ── 5. Snapper 'home' config is missing its snapshot subvolume ──
step "Snapper (home)"
if [[ -f /etc/snapper/configs/home && ! -e /home/.snapshots ]]; then
    btrfs subvolume create /home/.snapshots >/dev/null
    chmod 750 /home/.snapshots
    ok "Created /home/.snapshots subvolume"
else
    ok "Nothing to do"
fi
systemctl reset-failed snapper-timeline.service snapper-cleanup.service 2>/dev/null || true
if systemctl start snapper-timeline.service; then
    ok "snapper-timeline runs cleanly ($(snapper -c home list | tail -n +3 | wc -l) home snapshot(s))"
else
    echo "  ✖ snapper-timeline still failing: journalctl -u snapper-timeline -b" >&2
fi

# ── 6. arch-audit (CVE check for installed packages) ───────────
step "arch-audit"
pacman -S --needed --noconfirm arch-audit >/dev/null
ok "Installed; vulnerable packages with fixes available:"
arch-audit -u | sed 's/^/    /' || true

# ── Summary ────────────────────────────────────────────────────
step "Current firewall"
nft list table inet host_firewall 2>/dev/null || echo "  (not active)"
printf '\n\e[1;32mDone.\e[0m\n'
