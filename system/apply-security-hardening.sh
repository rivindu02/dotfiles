#!/usr/bin/env bash
# Security hardening from AUDIT.md §21 (idempotent, safe to re-run):
#   1. CouchDB local.ini -> 600 (it holds the [admins] password hash)
#   2. AppArmor: install, enable the LSM on the kernel cmdline, enable the service
#   3. Optional: drop your user from the docker group (root-equivalent); asks first
#   4. Block auto-loading of dccp/sctp/rds/tipc/firewire kernel modules
#   5. Re-install system/sysctl/99-hardening.conf and apply it
#
# Run: sudo ~/dotfiles/system/apply-security-hardening.sh
# Then: yay -S apparmor.d   (desktop app profiles; Arch ships very few)
# Then reboot and check: aa-status
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Run with sudo." >&2
    exit 1
fi

USER_NAME="${SUDO_USER:-}"

echo "== 1. CouchDB config permissions"
if [[ -f /etc/couchdb/local.ini ]]; then
    chmod 600 /etc/couchdb/local.ini
    stat -c '%a %U:%G %n' /etc/couchdb/local.ini
else
    echo "skip: /etc/couchdb/local.ini not found"
fi

echo "== 2. AppArmor"
pacman -S --needed --noconfirm apparmor

# Cache compiled profiles so boot doesn't re-parse ~1500 apparmor.d profiles each time
parser=/etc/apparmor/parser.conf
grep -qxF 'write-cache' "$parser" || echo 'write-cache' >> "$parser"
grep -qxF 'Optimize=compress-fast' "$parser" || echo 'Optimize=compress-fast' >> "$parser"

LSM='lsm=landlock,lockdown,yama,integrity,apparmor,bpf'
if grep -q '^GRUB_CMDLINE_LINUX_DEFAULT=.*apparmor' /etc/default/grub; then
    echo "kernel cmdline already has apparmor"
else
    cp /etc/default/grub "/etc/default/grub.bak-$(date +%Y%m%d-%H%M%S)"
    sed -i -E "s/^(GRUB_CMDLINE_LINUX_DEFAULT=\"[^\"]*)\"/\1 $LSM\"/" /etc/default/grub
    grep '^GRUB_CMDLINE_LINUX_DEFAULT=' /etc/default/grub
    # grub.cfg isn't signature-checked; the kernel and grubx64.efi stay signed by sbctl
    grub-mkconfig -o /boot/grub/grub.cfg
fi
systemctl enable apparmor.service

echo "== 3. docker group"
if [[ -n "$USER_NAME" ]] && id -nG "$USER_NAME" | grep -qw docker; then
    echo "$USER_NAME is in 'docker': any process running as you can become root while dockerd runs."
    echo "Rootless podman (podman.socket) is already enabled for your user."
    read -rp "Remove $USER_NAME from the docker group? [y/N] " ans
    if [[ "$ans" == [yY] ]]; then
        gpasswd -d "$USER_NAME" docker
        echo "Removed. Takes effect at next login. Undo: sudo gpasswd -a $USER_NAME docker"
    else
        echo "Kept."
    fi
else
    echo "skip: not in docker group"
fi

echo "== 4. Disable rare network protocols and FireWire (Lynis NETW-3200, STRG-1846)"
install -m 644 "$(dirname "$(readlink -f "$0")")/modprobe/disable-rare-protocols.conf" /etc/modprobe.d/
echo "installed /etc/modprobe.d/disable-rare-protocols.conf"

echo "== 5. sysctl hardening (adds fs.protected_fifos = 2, Lynis KRNL-6000)"
install -m 644 "$(dirname "$(readlink -f "$0")")/sysctl/99-hardening.conf" /etc/sysctl.d/
sysctl -q --system
echo "fs.protected_fifos = $(sysctl -n fs.protected_fifos)"

echo
echo "Done. Next:"
echo "  yay -S apparmor.d"
echo "  reboot, then: aa-status   (should list apparmor as enabled with profiles loaded)"
echo "  If an app breaks: sudo aa-complain /etc/apparmor.d/<profile>, and check journalctl -k | grep apparmor"
echo "  Rollback: restore the newest /etc/default/grub.bak-*, run grub-mkconfig -o /boot/grub/grub.cfg"
