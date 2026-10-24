#!/usr/bin/env bash
# Paste Unicode, then restore the previous clipboard without touching primary.
set -euo pipefail

target=${1:-}
[[ -n "$target" && "$target" != null ]] || exit 0
emoji=$(cat)
[[ -n "$emoji" ]] || exit 0

ready=false
for ((attempt = 0; attempt < 30; attempt++)); do
    window=$(hyprctl activewindow -j) || exit 0
    if [[ $(jq -r '.address // empty' <<< "$window") == "$target" ]]; then
        ready=true
        break
    fi
    sleep 0.05
done
[[ "$ready" == true ]] || exit 0

runtime=${XDG_RUNTIME_DIR:-/tmp}
backup=$(mktemp -d "$runtime/rofi-emoji.XXXXXX")
restore=false
had_clipboard=false
mime=""
sensitive=false

cleanup() {
    # Do not overwrite anything the user copied while the paste was running.
    if [[ "$restore" == true ]] &&
        wl-paste --list-types 2>/dev/null | grep -qx 'x-kde-passwordManagerHint' &&
        [[ $(wl-paste --no-newline --type text/plain 2>/dev/null) == "$emoji" ]]; then
        if [[ "$had_clipboard" == true ]]; then
            if [[ "$sensitive" == true ]]; then
                wl-copy --sensitive --type "$mime" < "$backup/content"
            else
                wl-copy --type "$mime" < "$backup/content"
            fi
        else
            wl-copy --clear
        fi
    fi
    rm -rf -- "$backup"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

if wl-paste --list-types > "$backup/types" 2> "$backup/error"; then
    had_clipboard=true
    if grep -qx 'x-kde-passwordManagerHint' "$backup/types"; then
        sensitive=true
    fi
    # Keep the original bytes, preferring images over their textual fallbacks.
    mime=$(awk '/^image\// { print; exit }' "$backup/types")
    if [[ -z "$mime" ]]; then
        mime=$(awk '/^text\/plain(;charset=utf-8)?$/ { print; exit }' "$backup/types")
    fi
    if [[ -z "$mime" ]]; then
        mime=$(awk '/\// && $0 != "x-kde-passwordManagerHint" { print; exit }' "$backup/types")
    fi
    if [[ -z "$mime" ]] || ! wl-paste --no-newline --type "$mime" > "$backup/content"; then
        notify-send "Emoji" "Could not save the clipboard; nothing was changed."
        exit 1
    fi
elif ! grep -qi 'nothing is copied' "$backup/error"; then
    notify-send "Emoji" "Could not read the clipboard; nothing was changed."
    exit 1
fi

# The sensitive hint keeps the temporary selection out of clipboard history.
restore=true
printf '%s' "$emoji" | wl-copy --sensitive --type text/plain
bash "$HOME/.config/rofi/scripts/paste.sh" "$target"
# Give the receiving app time to request the selection before restoring it.
sleep 0.5
