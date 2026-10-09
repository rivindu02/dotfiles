#!/usr/bin/env bash
# Round 7 (AUDIT.md §20): stop logind starting a getty on the session VT at logout. Safe to re-run.
# Usage: sudo bash ~/dotfiles/system/apply-round7.sh
set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "Run with sudo." >&2; exit 1; }
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

step() { printf '\n\e[1;34m==> %s\e[0m\n' "$1"; }
ok()   { printf '\e[1;32m  ✔ %s\e[0m\n' "$1"; }

step "logind: NAutoVTs=0"
install -Dm644 "$REPO/system/logind/20-no-autovt.conf" /etc/systemd/logind.conf.d/20-no-autovt.conf
systemctl reload systemd-logind
ok "Applied: $(systemd-analyze cat-config systemd/logind.conf | grep -m1 '^NAutoVTs')"

step "Stop stray gettys on tty1-5"
for n in 1 2 3 4 5; do
    if systemctl is-active --quiet "getty@tty$n.service"; then
        systemctl stop "getty@tty$n.service"
        ok "Stopped getty@tty$n"
    fi
done

printf '\n\e[1;32mDone.\e[0m Log out and back in quickly to test.\n'
