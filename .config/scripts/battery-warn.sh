#!/usr/bin/env bash

# Thresholds
WARN_THRESHOLD=30
CRITICAL_THRESHOLD=15

# Assets
SOUND_WARN="/usr/share/sounds/freedesktop/stereo/dialog-warning.oga"
SOUND_CRITICAL="/usr/share/sounds/freedesktop/stereo/battery-caution.oga"

# State files (using files instead of variables to bypass subshell issues)
STATE_DIR="/tmp/battery_warn"
mkdir -p "$STATE_DIR"
echo "false" > "$STATE_DIR/warn_30"
echo "false" > "$STATE_DIR/warn_15"
echo "false" > "$STATE_DIR/dimmed"

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
    notify-send -u normal -i battery-low -t 10000 \
        -h string:x-dunst-stack-tag:battery \
        "🟡 Battery Low" "Battery is at ${1}% — consider charging soon."
    play_sound "$SOUND_WARN"
    echo "true" > "$STATE_DIR/warn_30"
}

notify_critical() {
    notify-send -u critical -i battery-caution -t 0 \
        -h string:x-dunst-stack-tag:battery \
        "🔴 Plug in your charger!" "Battery is at ${1}% — plug in now!"
    play_sound "$SOUND_CRITICAL"
    
    brightnessctl -s set 30% 2>/dev/null
    wlsunset -t 2500 -T 2501 2>/dev/null &
    echo "true" > "$STATE_DIR/dimmed"
    echo "true" > "$STATE_DIR/warn_15"
}

restore_screen() {
    if [ "$(cat "$STATE_DIR/dimmed")" = "true" ]; then
        brightnessctl -r 2>/dev/null
        pkill wlsunset 2>/dev/null
        echo "false" > "$STATE_DIR/dimmed"
    fi
    echo "false" > "$STATE_DIR/warn_30"
    echo "false" > "$STATE_DIR/warn_15"
}

BAT_PATH=$(get_battery)
[ -z "$BAT_PATH" ] && exit 1

# Main Loop: Poll every 60 seconds (lighter on resources than monitoring lines)
while true; do
    BATTERY=$(cat "$BAT_PATH/capacity")
    STATUS=$(cat "$BAT_PATH/status")

    WARNED_30=$(cat "$STATE_DIR/warn_30")
    WARNED_15=$(cat "$STATE_DIR/warn_15")

    if [[ "$STATUS" == "Charging" || "$STATUS" == "Full" ]]; then
        restore_screen
    else
        if [ "$BATTERY" -le "$CRITICAL_THRESHOLD" ] && [ "$WARNED_15" = "false" ]; then
            notify_critical "$BATTERY"
        elif [ "$BATTERY" -le "$WARN_THRESHOLD" ] && [ "$WARNED_30" = "false" ]; then
            notify_warn "$BATTERY"
        fi
    fi
    sleep 60
done
