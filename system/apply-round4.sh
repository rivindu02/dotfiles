#!/usr/bin/env bash
# Round 4 of system changes (AUDIT.md §16): hardening, privacy, maintenance. Safe to re-run.
# Usage: sudo bash ~/dotfiles/system/apply-round4.sh
set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "Run with sudo." >&2; exit 1; }
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
USER_NAME="${SUDO_USER:?run via sudo from your user account}"

step() { printf '\n\e[1;34m==> %s\e[0m\n' "$1"; }
ok()   { printf '\e[1;32m  ✔ %s\e[0m\n' "$1"; }
warn() { printf '\e[1;33m  ⚠ %s\e[0m\n' "$1"; }

# ── 1. Kernel hardening sysctls ────────────────────────────────
step "Kernel hardening (sysctl)"
install -Dm644 "$REPO/system/sysctl/99-hardening.conf" /etc/sysctl.d/99-hardening.conf
sysctl -q -p /etc/sysctl.d/99-hardening.conf
ok "Applied: kptr_restrict=$(sysctl -n kernel.kptr_restrict) kexec_load_disabled=$(sysctl -n kernel.kexec_load_disabled) accept_redirects=$(sysctl -n net.ipv4.conf.all.accept_redirects) rp_filter=$(sysctl -n net.ipv4.conf.all.rp_filter)"

# ── 2. Core dumps off ──────────────────────────────────────────
step "Core dumps"
install -Dm644 "$REPO/system/coredump/10-disable.conf" /etc/systemd/coredump.conf.d/10-disable.conf
n=$(find /var/lib/systemd/coredump -type f 2>/dev/null | wc -l)
rm -f /var/lib/systemd/coredump/*
ok "Storage disabled; deleted $n stored dump(s)"

# ── 3. DNS: LLMNR off, DNS-over-TLS (auto-revert if DNS breaks) ─
step "DNS (systemd-resolved)"
install -Dm644 "$REPO/system/resolved/10-no-llmnr.conf" /etc/systemd/resolved.conf.d/10-no-llmnr.conf
install -Dm644 "$REPO/system/resolved/20-dns-over-tls.conf" /etc/systemd/resolved.conf.d/20-dns-over-tls.conf
systemctl restart systemd-resolved
sleep 2
if resolvectl query --cache=no archlinux.org >/dev/null 2>&1 && resolvectl query --cache=no github.com >/dev/null 2>&1; then
    ok "LLMNR off; lookups go to Quad9 over TLS (Tailscale *.ts.net still via MagicDNS)"
    resolvectl status | grep -m1 -E "DNSOverTLS" | sed 's/^ */    /'
else
    rm -f /etc/systemd/resolved.conf.d/20-dns-over-tls.conf
    systemctl restart systemd-resolved
    warn "DNS lookups failed with DNS-over-TLS; reverted that part (LLMNR stays off)"
fi

# ── 4. Wi-Fi MAC randomization ─────────────────────────────────
step "MAC address randomization (NetworkManager)"
install -Dm644 "$REPO/system/NetworkManager/00-mac-randomize.conf" /etc/NetworkManager/conf.d/00-mac-randomize.conf
systemctl reload NetworkManager
ok "Random MAC while scanning; stable per-network random MAC from the next (re)connect"

# ── 5. uinput gets its own group; leave the keystroke-reading `input` group ──
step "uinput group (replaces membership in 'input')"
# udev only supports device ownership by *system* groups (GID < 1000)
if getent group uinput >/dev/null && (( $(getent group uinput | cut -d: -f3) >= 1000 )); then groupdel uinput; fi
groupadd -f -r uinput
install -Dm644 "$REPO/system/udev/99-uinput.rules" /etc/udev/rules.d/99-uinput.rules
udevadm control --reload
udevadm trigger --sysname-match=uinput
gpasswd -a "$USER_NAME" uinput >/dev/null
if id -nG "$USER_NAME" | tr ' ' '\n' | grep -qx input; then
    gpasswd -d "$USER_NAME" input >/dev/null
fi
ok "/dev/uinput is $(stat -c '%U:%G %a' /dev/uinput); $USER_NAME: +uinput -input (takes effect at next login)"

# ── 6. .pacnew files: keep current configs ─────────────────────
step ".pacnew files"
# mkinitcpio.conf.pacnew switches to systemd/sd-vconsole hooks without `encrypt` -> would break LUKS boot.
# bluetooth/main.conf, locale.gen, tpm2 profiles: current files hold your customisations.
# mirrorlist.pacnew: reflector (below) rewrites the mirrorlist.
for f in /etc/mkinitcpio.conf.pacnew /etc/bluetooth/main.conf.pacnew /etc/locale.gen.pacnew \
         /etc/pacman.d/mirrorlist.pacnew \
         /etc/tpm2-tss/fapi-profiles/P_ECCP384SHA384.json.pacnew \
         /etc/tpm2-tss/fapi-profiles/P_RSA3072SHA384.json.pacnew; do
    [[ -f "$f" ]] && rm "$f" && echo "    kept current, removed ${f}"
done
ok "Done"

# ── 7. Orphaned packages ───────────────────────────────────────
step "Orphaned packages"
mapfile -t orphans < <(pacman -Qtdq || true)
if (( ${#orphans[@]} )); then
    pacman -Rns --noconfirm "${orphans[@]}" >/dev/null
    ok "Removed: ${orphans[*]}"
else
    ok "None"
fi

# ── 8. New packages ────────────────────────────────────────────
step "Install reflector, lynis, bitwarden"
pacman -S --needed --noconfirm reflector lynis bitwarden >/dev/null
ok "Installed"

# ── 9. Mirrors ─────────────────────────────────────────────────
step "Mirrors (reflector)"
install -Dm644 "$REPO/system/reflector/reflector.conf" /etc/xdg/reflector/reflector.conf
cp -a /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
if systemctl start reflector.service; then
    ok "Mirrorlist refreshed (old copy: /etc/pacman.d/mirrorlist.bak)"
    grep -m3 '^Server' /etc/pacman.d/mirrorlist | sed 's/^/    /'
else
    cp -a /etc/pacman.d/mirrorlist.bak /etc/pacman.d/mirrorlist
    warn "reflector failed; kept the old mirrorlist"
fi
systemctl enable --now reflector.timer >/dev/null 2>&1
ok "reflector.timer enabled (weekly)"

printf '\n\e[1;32mDone.\e[0m Reboot soon: new kernel (%s) + group changes apply at next login.\n' "$(pacman -Q linux | cut -d' ' -f2)"
