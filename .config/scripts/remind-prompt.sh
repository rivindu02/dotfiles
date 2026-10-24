#!/usr/bin/env bash

source "$HOME/.config/rofi/scripts/toggle.sh"
rofi_toggle || exit 0
# --- Config ---
ROFI_THEME="$HOME/.config/rofi/menus/remind.rasi"
TIMES=(
    "5 min"
    "10 min"
    "15 min"
    "30 min"
    "1 hour"
)

# First rofi: pick a preset OR type a custom duration (e.g. 45m, 2h)
# Enter selects a preset; Ctrl+Enter accepts a custom duration.
result=$(printf '%s\n' "${TIMES[@]}" | rofi \
    -dmenu -i \
    -p "Remind in" \
    -theme "$ROFI_THEME")
[ -z "$result" ] && exit 0

matched_time=""
for t in "${TIMES[@]}"; do
    if [ "$result" = "$t" ]; then
        matched_time="$t"
        break
    fi
done

if [ -n "$matched_time" ]; then
    case "$matched_time" in
        "5 min")  DURATION="5m" ;;
        "10 min") DURATION="10m" ;;
        "15 min") DURATION="15m" ;;
        "30 min") DURATION="30m" ;;
        "1 hour") DURATION="1h" ;;
    esac
else
    # user typed a custom duration directly
    DURATION="$result"
fi

# Second rofi: the reminder text
task=$(rofi \
    -dmenu -i \
    -p "Remind me to" \
    -theme-str 'mainbox { children: [ "inputbar", "message" ]; } entry { placeholder: "Reminder text…"; }' \
    -theme "$ROFI_THEME")
[ -z "$task" ] && exit 0

~/.config/scripts/remind.sh "$DURATION" "$task"
