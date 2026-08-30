#!/bin/bash
# ~/.config/scripts/toggle-idle.sh
PIDFILE="${XDG_RUNTIME_DIR:-/tmp}/stay-awake.pid"
if [ -f "$PIDFILE" ]; then
    kill "$(cat "$PIDFILE")" 2>/dev/null
    rm -f "$PIDFILE"
    notify-send "Stay awake" "Off"
else
    systemd-inhibit --what=idle:sleep --who="stay-awake-toggle" --why="manual toggle" sleep infinity &
    echo $! > "$PIDFILE"
    notify-send "Stay awake" "On"
fi
pkill -RTMIN+8 waybar
