#!/usr/bin/env bash
ROFI_THEME="$HOME/.config/rofi/launchers/type-1/style.rasi"

shopt -s nullglob
entries=("${XDG_RUNTIME_DIR:-/tmp}/reminders"/*)
if [ ${#entries[@]} -eq 0 ]; then
    notify-send -u low "Reminders" "No active reminders"
    exit 0
fi

declare -A label_to_file
labels=()
for f in "${entries[@]}"; do
    label=$(head -n1 "$f")
    labels+=("$label")
    label_to_file["$label"]="$f"
done

choice=$(printf '%s\n' "${labels[@]}" "── Cancel All ──" | rofi \
    -dmenu \
    -p "Cancel reminder" \
    -theme "$ROFI_THEME")
[ -z "$choice" ] && exit 0

cancel_one() {
    local file="$1" tag pid
    tag=$(basename "$file")
    pid=$(sed -n '2p' "$file")
    # Validate PID belongs to current user before killing
    if [ -n "$pid" ] && [ -d "/proc/$pid" ] && [ "$(stat -c %u "/proc/$pid")" = "$(id -u)" ]; then
        kill -- -"$pid" 2>/dev/null
    fi
    notify-send -a "remind-popup" -u low -h "string:x-canonical-private-synchronous:$tag" "⏰ Reminder" "Cancelled"
    rm -f "$file"
}

if [ "$choice" = "── Cancel All ──" ]; then
    for f in "${entries[@]}"; do cancel_one "$f"; done
else
    cancel_one "${label_to_file[$choice]}"
fi
