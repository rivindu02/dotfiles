#!/bin/bash
STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/nightlight-state"
ON_TEMP=4000

if ! pgrep -x hyprsunset >/dev/null; then
    hyprsunset &
    sleep 1
fi

if [ -f "$STATE_FILE" ]; then
    hyprctl hyprsunset identity
    rm -f "$STATE_FILE"
    notify-send -u low "󰖨 Night light off"
else
    hyprctl hyprsunset temperature $ON_TEMP
    touch "$STATE_FILE"
    notify-send -u low "󰌵 Night light on"
fi

pkill -RTMIN+9 waybar
