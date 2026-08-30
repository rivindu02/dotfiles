#!/usr/bin/env bash
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
# Enter always returns what you typed; Ctrl+Enter picks highlighted preset
result=$(printf '%s\n' "${TIMES[@]}" | rofi \
    -dmenu \
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
    -dmenu \
    -p "Remind me to" \
    -theme "$ROFI_THEME")
[ -z "$task" ] && exit 0

~/.config/scripts/remind.sh "$DURATION" "$task"
