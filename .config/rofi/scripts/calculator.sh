#!/usr/bin/env bash
source "$HOME/.config/rofi/scripts/toggle.sh"
rofi_toggle || exit 0
exec rofi -show calc -modi calc -no-show-match -no-sort \
    -theme "$HOME/.config/rofi/launchers/type-1/style.rasi"
