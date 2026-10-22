#!/usr/bin/env bash
# Downgrade gtk4 to 4.22.5 and libadwaita to 1.9.4, and hold them with IgnorePkg.
# Hyprland 0.56.2 skips backdrop blur for GTK 4.24 clients (swaync, ghostty, ...):
# https://github.com/hyprwm/Hyprland/issues/16508
#
# Run: sudo ~/dotfiles/system/apply-gtk4-downgrade.sh
# Undo once Hyprland is fixed: remove gtk4 and libadwaita from IgnorePkg in
# /etc/pacman.conf, then run: sudo pacman -Syu
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Run with sudo." >&2
    exit 1
fi

ala=https://archive.archlinux.org/packages
pacman -U --noconfirm \
    "$ala/g/gtk4/gtk4-1:4.22.5-1-x86_64.pkg.tar.zst" \
    "$ala/l/libadwaita/libadwaita-1:1.9.4-1-x86_64.pkg.tar.zst"

# Hold both so the next -Syu does not bring 4.24 back
conf=/etc/pacman.conf
if grep -qE '^IgnorePkg' "$conf"; then
    for p in gtk4 libadwaita; do
        grep -qE "^IgnorePkg.*[[:space:]=]$p([[:space:]]|$)" "$conf" || sed -i -E "s/^(IgnorePkg.*)$/\1 $p/" "$conf"
    done
else
    sed -i -E 's/^#IgnorePkg[[:space:]]*=.*$/IgnorePkg   = gtk4 libadwaita/' "$conf"
fi
grep -E '^IgnorePkg' "$conf"

pacman -Q gtk4 libadwaita
echo "Done. Restart swaync as your user: systemctl --user restart swaync"
