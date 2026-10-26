#!/bin/sh
# Keep desktop/file-manager activation consistent with Hyprland launches.
set -eu
set -a
# shellcheck source=.config/environment.d/20-desktop-theme.conf
. "$HOME/.config/environment.d/20-desktop-theme.conf"
set +a

gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME"
gsettings set org.gnome.desktop.interface icon-theme Papirus-Dark
gsettings set org.gnome.desktop.interface cursor-theme "$XCURSOR_THEME"
gsettings set org.gnome.desktop.interface cursor-size "$XCURSOR_SIZE"
gsettings set org.gnome.desktop.interface font-name 'CaskaydiaMono Nerd Font Mono 10'
gsettings set org.gnome.desktop.interface color-scheme prefer-dark

dbus-update-activation-environment --systemd \
    GTK_THEME GDK_WAYLAND_DISABLE XCURSOR_THEME XCURSOR_SIZE HYPRCURSOR_SIZE \
    QT_QPA_PLATFORMTHEME QT_QPA_PLATFORM QT_WAYLAND_DISABLE_WINDOWDECORATION \
    QT_SCALE_FACTOR_ROUNDING_POLICY ELECTRON_OZONE_PLATFORM_HINT
