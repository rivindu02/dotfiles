#!/usr/bin/env bash
# Round 6 (AUDIT.md §20): stop the SDDM re-login loop while user linger is on. Safe to re-run.
# Usage: sudo bash ~/dotfiles/system/apply-round6.sh
#
# With linger on, the user manager never stops, so a login finishes PAM at once and
# sddm switches VT while the X11 greeter is still exiting. The switch hangs, sddm logs
# "Session started false" after 30 s and kills the session 60 s later.
# A 1 s pause at the end of the sddm PAM session stack lets the greeter exit first
# (fresh logins already had ~250 ms of slack from starting the user manager).
# The pause runs only at session open, so logout is not delayed.
set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "Run with sudo." >&2; exit 1; }

step() { printf '\n\e[1;34m==> %s\e[0m\n' "$1"; }
ok()   { printf '\e[1;32m  ✔ %s\e[0m\n' "$1"; }

step "sddm PAM: wait 1 s before the session starts (not at logout)"
# type=open_session: without it pam_exec also runs at session close and adds 1 s to logout.
line='session     optional    pam_exec.so             type=open_session /usr/bin/sleep 1'
if grep -qF 'pam_exec.so             type=open_session /usr/bin/sleep 1' /etc/pam.d/sddm; then
    ok "Already present"
elif grep -qF 'pam_exec.so             /usr/bin/sleep 1' /etc/pam.d/sddm; then
    cp -a /etc/pam.d/sddm /etc/pam.d/sddm.bak
    sed -i 's|pam_exec.so             /usr/bin/sleep 1|pam_exec.so             type=open_session /usr/bin/sleep 1|' /etc/pam.d/sddm
    ok "Limited the sleep to login (backup: /etc/pam.d/sddm.bak)"
else
    cp -a /etc/pam.d/sddm /etc/pam.d/sddm.bak
    printf '%s\n' "$line" >> /etc/pam.d/sddm
    ok "Added (backup: /etc/pam.d/sddm.bak)"
fi
tail -3 /etc/pam.d/sddm | sed 's/^/    /'

printf '\n\e[1;32mDone.\e[0m Log out and back in quickly to test.\n'
