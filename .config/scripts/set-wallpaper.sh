#!/bin/bash
WP=$(~/.config/scripts/get-wallpaper.sh)
ln -sf "$WP" ~/.cache/current-wallpaper.jpg
sed -i "s|path = .*|path = $WP|" ~/.config/hypr/hyprlock.conf
