#!/usr/bin/env bash
# Round 5 of system changes (AUDIT.md §20): logout/login loop fix, persistent journal. Safe to re-run.
# Usage: sudo bash ~/dotfiles/system/apply-round5.sh
set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "Run with sudo." >&2; exit 1; }
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

step() { printf '\n\e[1;34m==> %s\e[0m\n' "$1"; }
ok()   { printf '\e[1;32m  ✔ %s\e[0m\n' "$1"; }

# ── 1. Persistent journal ──────────────────────────────────────
# systemd-journal-flush.service was masked, so journald never moved from
# /run/log/journal to /var/log/journal and every boot's logs died with the reboot.
step "Persistent journal (unmask systemd-journal-flush)"
systemctl unmask systemd-journal-flush.service >/dev/null
systemctl start systemd-journal-flush.service
ok "Journal now at /var/log/journal (current boot flushed)"
journalctl --header --no-pager 2>/dev/null | grep -m3 'File path' | sed 's/^/    /'

# ── 2. Stop the user manager at logout ────────────────────────
step "logind: UserStopDelaySec=0"
install -Dm644 "$REPO/system/logind/10-user-stop-delay.conf" /etc/systemd/logind.conf.d/10-user-stop-delay.conf
systemctl reload systemd-logind
ok "Applied: $(systemd-analyze cat-config systemd/logind.conf | grep -m1 '^UserStopDelaySec')"

printf '\n\e[1;32mDone.\e[0m\n'
