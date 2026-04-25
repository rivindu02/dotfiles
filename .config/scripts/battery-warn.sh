#!/usr/bin/env bash
# ~/.config/hypr/scripts/battery-warn.sh

WARN_THRESHOLD=30
CRITICAL_THRESHOLD=15

SOUND_WARN="/usr/share/sounds/freedesktop/stereo/dialog-warning.oga"
SOUND_CRITICAL="/usr/share/sounds/freedesktop/stereo/battery-caution.oga"

WARNED_30=false
WARNED_15=false
DIMMED=false

play_sound() {
    if command -v paplay &>/dev/null; then
        paplay "$1" 2>/dev/null &
    elif command -v pw-play &>/dev/null; then
        pw-play "$1" 2>/dev/null &
    fi
}

get_battery() {
    for bat in /sys/class/power_supply/BAT{0,1,2}; do
        [ -f "$bat/capacity" ] && echo "$bat" && return
    done
}

notify_warn() {
    notify-send \
        -u normal \
        -i battery-low \
        -t 10000 \
        -h string:x-dunst-stack-tag:battery \
        "🟡 Battery Low" \
        "Battery is at ${1}% — consider charging soon."
    play_sound "$SOUND_WARN"
}

notify_critical() {
    notify-send \
        -u critical \
        -i battery-caution \
        -t 0 \
        -h string:x-dunst-stack-tag:battery \
        "🔴 Plug in your charger!" \
        "Battery is at ${1}% — plug in now!"
    play_sound "$SOUND_CRITICAL"

    # Dim screen
    brightnessctl -s set 30% 2>/dev/null
    wlsunset -t 2500 -T 2501 2>/dev/null &
    DIMMED=true
}

restore_screen() {
    if [ "$DIMMED" = true ]; then
        brightnessctl -r 2>/dev/null
        pkill wlsunset 2>/dev/null
        DIMMED=false
    fi
}

BAT_PATH=$(get_battery)

if [ -z "$BAT_PATH" ]; then
    notify-send -u critical "Battery Warning Script" "No battery found, exiting."
    exit 1
fi

upower --monitor 2>/dev/null | while read -r _line; do
    BATTERY=$(cat "$BAT_PATH/capacity" 2>/dev/null)
    STATUS=$(cat "$BAT_PATH/status" 2>/dev/null)

    [ -z "$BATTERY" ] && continue

    if [ "$STATUS" = "Charging" ] || [ "$STATUS" = "Full" ]; then
        WARNED_30=false
        WARNED_15=false
        restore_screen
        continue
    fi

    if [ "$STATUS" = "Discharging" ]; then
        if [ "$BATTERY" -le "$CRITICAL_THRESHOLD" ] && [ "$WARNED_15" = false ]; then
            notify_critical "$BATTERY"
            WARNED_15=true
            WARNED_30=true

        elif [ "$BATTERY" -le "$WARN_THRESHOLD" ] && [ "$WARNED_30" = false ]; then
            notify_warn "$BATTERY"
            WARNED_30=true
        fi
    fi
done
