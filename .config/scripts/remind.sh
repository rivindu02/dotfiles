#!/bin/bash
# usage: remind.sh 10m "check the laundry"
DURATION=$1; shift; MSG="$*"

case "$DURATION" in
  *h) TOTAL=$(( ${DURATION%h} * 3600 )) ;;
  *m) TOTAL=$(( ${DURATION%m} * 60 )) ;;
  *s) TOTAL=$(( ${DURATION%s} )) ;;
  *)  TOTAL=$DURATION ;;
esac

TAG="reminder-$$"
END=$(( $(date +%s) + TOTAL ))
mkdir -p "${XDG_RUNTIME_DIR:-/tmp}/reminders"

# Notify that the reminder has been set (silent slot — same tag as loop updates)
notify-send -a "remind-silent" -u low -h "string:x-canonical-private-synchronous:$TAG" -t 35000 "⏳ $MSG" "$(date +%H:%M) → $(date -d @$END +%H:%M)"

export REM_END="$END" REM_TAG="$TAG" REM_MSG="$MSG"
setsid ~/.config/scripts/reminder-loop.sh &
PID=$!
disown

printf '%s\n%s\n' "$MSG (ends $(date -d @$END +%H:%M))" "$PID" > "${XDG_RUNTIME_DIR:-/tmp}/reminders/$TAG"
