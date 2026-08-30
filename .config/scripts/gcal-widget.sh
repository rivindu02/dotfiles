#!/bin/bash
# ~/.config/scripts/gcal-widget.sh
# ── Config ───────────────────────────────────────────────────
export PATH="/home/rivindu02/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
HOME=/home/rivindu02
GCAL_PERSONAL="gcalcli --config-folder $HOME/.config/gcalcli/gcalcli-personal"
SWAYNC_CONFIG="$HOME/.config/swaync/config.json"
TODAY=$(date '+%Y-%m-%d')
TOMORROW=$(date -d '+1 day' '+%Y-%m-%d')
DAY3=$(date -d '+2 days' '+%Y-%m-%d')
END=$(date -d '+3 days' '+%Y-%m-%d')

# ── Fetch events ─────────────────────────────────────────────
RAW_EVENTS=$(
  {
    $GCAL_PERSONAL agenda --nocolor --nodeclined --tsv "$TODAY" "$END" 2>&1
  } | grep -v '^start_date' | sort | uniq
)

GCAL_STATE="${XDG_RUNTIME_DIR:-/tmp}"

# ── Buckets ───────────────────────────────────────────────────
today_allday=()
today_timed=()
tomorrow_allday=()
tomorrow_timed=()
day3_allday=()
day3_timed=()

while IFS=$'\t' read -r start_date start_time end_date end_time title; do

  if [[ "$start_time" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    title="$end_date"
    time_display="All day"
  elif [[ -z "$start_time" || "$start_time" == "00:00" ]] && \
       [[ -z "$end_time"   || "$end_time"   == "00:00" ]]; then
    time_display="All day"
  else
    time_display=$(date -d "${start_date} ${start_time}" '+%H:%M' 2>/dev/null || echo "$start_time")
  fi

  [[ -z "$title" ]] && continue
  [[ ${#title} -gt 70 ]] && title="${title:0:68}…"

  if [[ "$time_display" == "All day" ]]; then
    entry="󰃰 ${title}"
  else
    entry="${time_display}  •  ${title}"
  fi

  case "$start_date" in
    "$TODAY")
      [[ "$time_display" == "All day" ]] && today_allday+=("$entry") || today_timed+=("$entry") ;;
    "$TOMORROW")
      [[ "$time_display" == "All day" ]] && tomorrow_allday+=("$entry") || tomorrow_timed+=("$entry") ;;
    "$DAY3")
      [[ "$time_display" == "All day" ]] && day3_allday+=("$entry") || day3_timed+=("$entry") ;;
  esac

done <<< "$RAW_EVENTS"

# ── Helper ────────────────────────────────────────────────────
join_or_none() {
  local -n _arr=$1
  printf '%s\n' "${_arr[@]}"
}

# ── Write tmp files FIRST (python reads these) ────────────────
join_or_none today_allday    > "$GCAL_STATE/gcal-today-allday.txt"
join_or_none today_timed     > "$GCAL_STATE/gcal-today-timed.txt"
join_or_none tomorrow_allday > "$GCAL_STATE/gcal-tomorrow-allday.txt"
join_or_none tomorrow_timed  > "$GCAL_STATE/gcal-tomorrow-timed.txt"
join_or_none day3_allday     > "$GCAL_STATE/gcal-day3-allday.txt"
join_or_none day3_timed      > "$GCAL_STATE/gcal-day3-timed.txt"

# ── Total event count ─────────────────────────────────────────
total=$(( ${#today_allday[@]} + ${#today_timed[@]} + \
          ${#tomorrow_allday[@]} + ${#tomorrow_timed[@]} + \
          ${#day3_allday[@]} + ${#day3_timed[@]} ))

DAY3_LABEL="$(date -d "$DAY3" '+%a %b %d')"

# ── Patch swaync config ───────────────────────────────────────
if command -v python3 &>/dev/null && [[ -f "$SWAYNC_CONFIG" ]]; then
  python3 - "$SWAYNC_CONFIG" "$DAY3_LABEL" "$total" << 'PYEOF'
import json, sys, os

config_path = sys.argv[1]
day3_label  = sys.argv[2]
total       = int(sys.argv[3])
gcal_state  = os.environ.get("XDG_RUNTIME_DIR", "/tmp")

def read(path):
    try:
        with open(path) as f: return f.read().strip()
    except: return "None"

today_allday    = read(f"{gcal_state}/gcal-today-allday.txt")
today_timed     = read(f"{gcal_state}/gcal-today-timed.txt")
tomorrow_allday = read(f"{gcal_state}/gcal-tomorrow-allday.txt")
tomorrow_timed  = read(f"{gcal_state}/gcal-tomorrow-timed.txt")
day3_allday     = read(f"{gcal_state}/gcal-day3-allday.txt")
day3_timed      = read(f"{gcal_state}/gcal-day3-timed.txt")

with open(config_path) as f:
    cfg = json.load(f)

wc = cfg.setdefault("widget-config", {})

has_weather = "label#weather" in wc

widgets = ["title"]
if has_weather:
    widgets.append("label#weather")
widgets.append("label#gcal-header")

if total == 0:
    wc["label#gcal-header"]["text"] = "󰃭  No upcoming events"
else:
    wc["label#gcal-header"]["text"] = "󰃭  Upcoming Events"

    for day, header, allday, timed in [
        ("today",    " Today",         today_allday,    today_timed),
        ("tomorrow", " Tomorrow",      tomorrow_allday, tomorrow_timed),
        ("day3",     f" {day3_label}", day3_allday,     day3_timed),
    ]:
        if not allday and not timed:
            continue
        widgets.append(f"label#gcal-{day}-header")
        wc[f"label#gcal-{day}-header"]["text"] = header
        if allday:
            widgets.append(f"label#gcal-{day}-allday")
            wc[f"label#gcal-{day}-allday"]["text"] = allday
        if timed:
            widgets.append(f"label#gcal-{day}-timed")
            wc[f"label#gcal-{day}-timed"]["text"] = timed

widgets += ["mpris", "notifications", "dnd"]
cfg["widgets"] = widgets

with open(config_path, "w") as f:
    json.dump(cfg, f, indent=2, ensure_ascii=False)
PYEOF

  swaync-client --reload-config
fi
