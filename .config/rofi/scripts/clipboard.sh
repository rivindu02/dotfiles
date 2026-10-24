#!/usr/bin/env bash

source "$HOME/.config/rofi/scripts/toggle.sh"
rofi_toggle || exit 0
set -euo pipefail

target=$(hyprctl activewindow -j | jq -r '.address // empty')
selection=$(cliphist list | rofi -dmenu -i -no-custom -no-auto-select \
    -display-columns 2 -p "Clipboard" \
    -theme "$HOME/.config/rofi/menus/clipboard.rasi") || exit 0
[[ -n "$selection" ]] || exit 0

# Decode through a file so images and trailing newlines survive intact.
runtime=${XDG_RUNTIME_DIR:-/tmp}
payload=$(mktemp "$runtime/rofi-clipboard.XXXXXX")
trap 'rm -f "$payload"' EXIT
printf '%s\n' "$selection" | cliphist decode > "$payload"
[[ -s "$payload" ]] || exit 0
touch "$runtime/cliphist-silent"
if ! wl-copy < "$payload"; then
    rm -f "$runtime/cliphist-silent"
    exit 1
fi
bash "$HOME/.config/rofi/scripts/paste.sh" "$target"
