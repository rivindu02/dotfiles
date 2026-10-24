#!/usr/bin/env bash
# Paste the clipboard after the picker closes and the original app regains focus.
set -euo pipefail

target=${1:-}
[[ -n "$target" && "$target" != null ]] || exit 0
ready=false
for ((attempt = 0; attempt < 30; attempt++)); do
    window=$(hyprctl activewindow -j 2>/dev/null) || break
    if [[ $(jq -r '.address // empty' <<< "$window") == "$target" ]]; then
        ready=true
        break
    fi
    sleep 0.05
done

if [[ "$ready" != true ]]; then
    notify-send "Picker" "Selection copied. Original window is no longer focused."
    exit 0
fi

# Let the Enter key from Rofi finish releasing before sending a paste shortcut.
sleep 0.15
window=$(hyprctl activewindow -j)
[[ $(jq -r '.address // empty' <<< "$window") == "$target" ]] || exit 0
app=$(jq -r '.class // "" | ascii_downcase' <<< "$window")
terminal=false
case "$app" in
    *ghostty*|*kitty*|*alacritty*|*foot*|*wezterm*|*org.gnome.terminal*|*konsole*|*xterm*|*tilix*|*terminator*) terminal=true ;;
esac

# Clipboard paste preserves emoji, newlines, and non-text clipboard MIME types.
# Prefer the virtual keyboard; fall back to ydotool/uinput when unavailable.
if command -v wtype >/dev/null; then
    if [[ "$terminal" == true ]]; then
        wtype -M ctrl -M shift -k v -m shift -m ctrl 2>/dev/null && exit 0
    else
        wtype -M ctrl -k v -m ctrl 2>/dev/null && exit 0
    fi
fi
if command -v ydotool >/dev/null; then
    if [[ "$terminal" == true ]]; then
        ydotool key 29:1 42:1 47:1 47:0 42:0 29:0 && exit 0
    else
        ydotool key 29:1 47:1 47:0 29:0 && exit 0
    fi
fi
notify-send "Picker" "Selection copied. Automatic paste failed; check ydotool.service."
