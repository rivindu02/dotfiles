#!/usr/bin/env bash
# ~/.config/scripts/gcal-notify.sh

NOTIFIED_FILE="/tmp/gcal-notified"
touch "$NOTIFIED_FILE"

GCAL_PERSONAL="gcalcli --config-folder ~/.config/gcalcli/gcalcli-personal"
GCAL_WORK="gcalcli --config-folder ~/.config/gcalcli/gcalcli-work"

send_notification() {
  local title="$1"
  local message="$2"
  local urgency="$3"

  notify-send \
    --app-name="Google Calendar" \
    --urgency="$urgency" \
    --icon="x-office-calendar" \
    "󰃭  $title" "$message"
}

fetch_events() {
  local from="$1"
  local to="$2"

  $GCAL_PERSONAL agenda --nocolor --nodeclined --tsv "$from" "$to" 2>/dev/null
  $GCAL_WORK     agenda --nocolor --nodeclined --tsv "$from" "$to" 2>/dev/null
}

check_events() {
  local now
  now=$(date +%s)

  fetch_events \
    "$(date '+%Y-%m-%d %H:%M')" \
    "$(date -d '+12 hours' '+%Y-%m-%d %H:%M')" \
  | while IFS=$'\t' read -r start_date start_time end_date end_time title; do

    [[ -z "$title" ]] && continue

    event_epoch=$(date -d "$start_date $start_time" +%s 2>/dev/null)
    [[ -z "$event_epoch" ]] && continue

    local diff=$(( event_epoch - now ))
    local notify_key_30="${event_epoch}_${title}_30"
    local notify_key_10="${event_epoch}_${title}_10"
    local display_time
    display_time=$(date -d "$start_date $start_time" '+%I:%M %p')

    # 30 min warning
    if (( diff >= 1740 && diff <= 1860 )); then
      if ! grep -qF "$notify_key_30" "$NOTIFIED_FILE"; then
        send_notification "$title" "Starting at $display_time — in 30 minutes" "normal"
        echo "$notify_key_30" >> "$NOTIFIED_FILE"
      fi
    fi

    # 10 min warning
    if (( diff >= 540 && diff <= 660 )); then
      if ! grep -qF "$notify_key_10" "$NOTIFIED_FILE"; then
        send_notification "$title" "Starting at $display_time — in 10 minutes!" "critical"
        echo "$notify_key_10" >> "$NOTIFIED_FILE"
      fi
    fi

  done

  tail -100 "$NOTIFIED_FILE" > "${NOTIFIED_FILE}.tmp" \
    && mv "${NOTIFIED_FILE}.tmp" "$NOTIFIED_FILE"
}

startup_summary() {
  local agenda
  agenda=$(
    $GCAL_PERSONAL agenda --nocolor --nodeclined \
      "$(date '+%Y-%m-%d')" "$(date -d '+1 day' '+%Y-%m-%d')" 2>/dev/null
    $GCAL_WORK agenda --nocolor --nodeclined \
      "$(date '+%Y-%m-%d')" "$(date -d '+1 day' '+%Y-%m-%d')" 2>/dev/null
  )

  agenda=$(echo "$agenda" | grep -v "^No events" | head -8)

  if [[ -n "$agenda" ]]; then
    notify-send \
      --app-name="Google Calendar" \
      --urgency="low" \
      --icon="x-office-calendar" \
      "󰃭  Today's Agenda" "$agenda"
  fi
}

startup_summary

while true; do
  check_events
  sleep 60
done
