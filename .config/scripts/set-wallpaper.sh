#!/bin/bash
WP=$(~/.config/scripts/get-wallpaper.sh)
ln -sf "$WP" ~/.cache/current-wallpaper.jpg
WP_ESC=$(printf '%s' "$WP" | sed 's/[\\|&]/\\&/g')
sed -i "/^background/,/^}/ s|path = .*|path = $WP_ESC|" ~/.config/hypr/hyprlock.conf
