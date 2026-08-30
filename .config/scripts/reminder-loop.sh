#!/bin/bash
END="$REM_END"; TAG="$REM_TAG"; MSG="$REM_MSG"

# Assets — only use files that actually exist
SOUND_ALERT="/usr/share/sounds/freedesktop/stereo/sms.oga"

play_sound() {
    if command -v paplay &>/dev/null; then
        paplay "$1" 2>/dev/null &
    elif command -v pw-play &>/dev/null; then
        pw-play "$1" 2>/dev/null &
    fi
}

while true; do
  NOW=$(date +%s)
  LEFT=$(( END - NOW ))
  if [ "$LEFT" -le 0 ]; then
    # Final alert — pops up AND plays a sound
    notify-send -a "remind-popup" -u critical -h "string:x-canonical-private-synchronous:$TAG" "⏰ Reminder" "$MSG"
    play_sound "$SOUND_ALERT"
    rm -f "${XDG_RUNTIME_DIR:-/tmp}/reminders/$TAG"
    exit 0
  fi
  MINS=$(( LEFT / 60 ))
  SECS=$(( LEFT % 60 ))
  NOW_FMT=$(date +%H:%M)
  END_FMT=$(date -d "@$END" +%H:%M)
  # Silent periodic update — no popup, no sound, only updates in swaync tray
  notify-send -a "remind-silent" -u low -h "string:x-canonical-private-synchronous:$TAG" -t 35000 "⏳ $MSG" "$(printf '%s → %s  (%d:%02d left)' "$NOW_FMT" "$END_FMT" "$MINS" "$SECS")"
  sleep 30
done
