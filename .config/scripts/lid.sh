#!/bin/bash
# ~/.config/scripts/lid.sh close|open
# Called by the Hyprland lid-switch binds. Acts only while stay-awake (toggle-idle.sh)
# holds the handle-lid-switch inhibitor; otherwise logind suspends on lid close as usual.
# Lid closed: lock, keyboard backlight off, laptop screen off. Everything else keeps running.
PIDFILE="${XDG_RUNTIME_DIR:-/tmp}/stay-awake.pid"
[ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null || exit 0

case "$1" in
    close)
        loginctl lock-session      # hypridle's lock_cmd starts hyprlock
        brightnessctl -sd asus::kbd_backlight set 0 >/dev/null
        sleep 0.5                  # let hyprlock map before the screen goes dark
        hyprctl dispatch dpms off eDP-1 >/dev/null
        ;;
    open)
        hyprctl dispatch dpms on eDP-1 >/dev/null
        brightnessctl -rd asus::kbd_backlight >/dev/null
        ;;
esac
