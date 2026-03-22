#!/bin/bash
# ~/.config/scripts/gcal-widgets.sh

# ── Config ───────────────────────────────────────────────────
export PATH="/home/rivindu02/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
HOME=/home/rivindu02
GCAL_BIN=$(which gcalcli)
GCAL_PERSONAL="gcalcli --config-folder $HOME/.config/gcalcli/gcalcli-personal"
GCAL_WORK="gcalcli --config-folder $HOME/.config/gcalcli/gcalcli-work"
SWAYNC_CONFIG="$HOME/.config/swaync/config.json"
TODAY=$(date '+%Y-%m-%d')
TOMORROW=$(date -d '+1 day' '+%Y-%m-%d')
END=$(date -d '+3 days' '+%Y-%m-%d')

# ── Fetch events ─────────────────────────────────────────────
RAW_EVENTS=$(
  {
    $GCAL_PERSONAL agenda --nocolor --nodeclined --tsv "$TODAY" "$END" 2>&1
    $GCAL_WORK     agenda --nocolor --nodeclined --tsv "$TODAY" "$END" 2>&1
  } | grep -v '^start_date' | sort | uniq
)
echo "RAW: $RAW_EVENTS" > /tmp/gcal-debug.log

# ── Format events ─────────────────────────────────────────────
format_events() {
  local lines=()
  while IFS=$'\t' read -r start_date start_time end_date end_time title; do
    [[ -z "$title" ]] && continue

    if [[ "$start_time" == "00:00" && "$end_time" == "00:00" ]]; then
      time_display="All day"
    else
      time_display=$(date -d "${start_date} ${start_time}" '+%H:%M' 2>/dev/null || echo "$start_time")
    fi

    if [[ "$start_date" == "$TODAY" ]]; then
      day_label="Today"
    elif [[ "$start_date" == "$TOMORROW" ]]; then
      day_label="Tomorrow"
    else
      day_label="$(date -d "$start_date" '+%a %b %d' 2>/dev/null || echo "$start_date")"
    fi

    [[ ${#title} -gt 30 ]] && title="${title:0:28}…"
    lines+=("${day_label} ${time_display}  •  ${title}")
    [[ ${#lines[@]} -ge 5 ]] && break
  done <<< "$RAW_EVENTS"

  if [[ ${#lines[@]} -eq 0 ]]; then
    echo "No upcoming events"
  else
    printf '%s\n' "${lines[@]}"
  fi
}

# ── Write to tmp file ─────────────────────────────────────────
FORMATTED_TEXT=$(format_events)
echo "$FORMATTED_TEXT" > /tmp/gcal-events.txt


# ── Patch swaync config and reload ───────────────────────────
if command -v python3 &>/dev/null && [[ -f "$SWAYNC_CONFIG" ]]; then
  python3 - "$SWAYNC_CONFIG" << PYEOF
import json, sys

config_path = sys.argv[1]

# Read formatted text from the tmp file (preserves real newlines)
with open('/tmp/gcal-events.txt', 'r') as f:
    text_raw = f.read().strip()

with open(config_path, 'r') as f:
    cfg = json.load(f)

widget = cfg['widget-config']['label#gcal-events']
widget['text'] = text_raw   # real \n characters — swaync renders these as newlines
widget['markup'] = False     # plain text mode, no pango needed
widget.pop('exec', None)
widget.pop('interval', None)

with open(config_path, 'w') as f:
    json.dump(cfg, f, indent=2, ensure_ascii=False)
PYEOF

  swaync-client --reload-config
fi
