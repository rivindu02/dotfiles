#!/usr/bin/env bash
# Round 3 of system changes (AUDIT.md §14). Safe to re-run.
# Usage: sudo bash ~/dotfiles/system/apply-round3.sh
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Run with sudo." >&2; exit 1; }

step() { printf '\n\e[1;34m==> %s\e[0m\n' "$1"; }
ok()   { printf '\e[1;32m  ✔ %s\e[0m\n' "$1"; }

# ── 1. Dead low-battery udev rule (notify-send from udev never reaches the session) ──
step "udev: 98-lowbat-warn.rules"
if [[ -f /etc/udev/rules.d/98-lowbat-warn.rules ]]; then
    rm /etc/udev/rules.d/98-lowbat-warn.rules
    udevadm control --reload
    ok "Removed (99-lowbat suspend-at-5% and the 80% charge limit are untouched)"
else
    ok "Already gone"
fi

# ── 2. Docker engine off; docker/docker-compose CLIs stay (they talk to Podman) ──
step "Docker engine"
systemctl disable --now docker.socket docker.service >/dev/null 2>&1 || true
ok "docker.socket/docker.service disabled; 'docker' and 'docker-compose' still work via Podman"
if [[ -d /var/lib/docker ]]; then
    size=$(du -sh /var/lib/docker 2>/dev/null | cut -f1)
    imgs=$(find /var/lib/docker/image -name '*.json' -path '*imagedb/content*' 2>/dev/null | wc -l)
    ctrs=$(ls /var/lib/docker/containers 2>/dev/null | wc -l)
    echo "  Old Docker-engine data in /var/lib/docker: $size ($imgs image(s), $ctrs container(s))."
    echo "  Your devbox and postgres live in Podman and are NOT in this folder."
    if read -r -p "  Delete /var/lib/docker? [y/N] " ans && [[ "$ans" =~ ^[yY] ]]; then
        rm -rf /var/lib/docker
        ok "Deleted"
    else
        echo "  Kept"
    fi
fi

# ── 3. Unused packages ──
step "Remove unused packages"
pkgs=()
for p in foxglove-bin-debug qdirstat-debug rustdesk-debug vm-curator-debug voxtype-bin-debug \
         python312-debug python312 ollama; do
    pacman -Qq "$p" &>/dev/null && pkgs+=("$p")
done
if (( ${#pkgs[@]} )); then
    pacman -Rns --noconfirm "${pkgs[@]}" >/dev/null
    ok "Removed: ${pkgs[*]}"
else
    ok "Nothing to remove"
fi

printf '\n\e[1;32mDone.\e[0m\n'
