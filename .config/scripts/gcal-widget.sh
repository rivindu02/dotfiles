#!/bin/bash
# ~/.config/scripts/gcal-widget.sh
# ── Config ───────────────────────────────────────────────────
set -euo pipefail
export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
SCRIPT_DIR=$(dirname -- "$(realpath -- "${BASH_SOURCE[0]}")")
# This is an argument file, not a config directory. The agenda's explicit
# wildcard includes every calendar, overriding the file's personal-only filter.
GCAL_PERSONAL=(gcalcli "@$HOME/.config/gcalcli/gcalcli-personal")
SWAYNC_CONFIG="${SWAYNC_CONFIG:-$HOME/.config/swaync/config.json}"
TODAY=$(date '+%Y-%m-%d')
TOMORROW=$(date -d '+1 day' '+%Y-%m-%d')
DAY3=$(date -d '+2 days' '+%Y-%m-%d')
END=$(date -d '+3 days' '+%Y-%m-%d')

# ── Fetch events ─────────────────────────────────────────────
if ! RAW_EVENTS=$("${GCAL_PERSONAL[@]}" --refresh agenda --calendar '.*' \
    --nocolor --nodeclined --tsv "$TODAY" "$END"); then
  echo "Calendar fetch failed; keeping the last displayed agenda." >&2
  exit 1
fi

GCAL_STATE="${XDG_RUNTIME_DIR:-/tmp}"

# ── Buckets ───────────────────────────────────────────────────
today_allday=()
today_timed=()
tomorrow_allday=()
tomorrow_timed=()
day3_allday=()
day3_timed=()

while IFS=$'\037' read -r start_date start_time _end_date end_time title; do
  [[ "$start_date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || continue

  if [[ -z "$start_time" || "$start_time" == "00:00" ]] && \
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

# A non-whitespace separator preserves empty TSV fields for all-day events.
done < <(printf '%s\n' "$RAW_EVENTS" | sort -u | tr '\t' '\037')

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
  PYTHONDONTWRITEBYTECODE=1 PYTHONPATH="$SCRIPT_DIR${PYTHONPATH:+:$PYTHONPATH}" python3 - "$SWAYNC_CONFIG" "$DAY3_LABEL" "$total" << 'PYEOF'
import sys, os
from swaync_config import edit_config

config_path = sys.argv[1]
day3_label  = sys.argv[2]
total       = int(sys.argv[3])
gcal_state  = os.environ.get("XDG_RUNTIME_DIR") or "/tmp"

def read(path):
    try:
        with open(path) as f: return f.read().strip()
    except FileNotFoundError: return ""

today_allday    = read(f"{gcal_state}/gcal-today-allday.txt")
today_timed     = read(f"{gcal_state}/gcal-today-timed.txt")
tomorrow_allday = read(f"{gcal_state}/gcal-tomorrow-allday.txt")
tomorrow_timed  = read(f"{gcal_state}/gcal-tomorrow-timed.txt")
day3_allday     = read(f"{gcal_state}/gcal-day3-allday.txt")
day3_timed      = read(f"{gcal_state}/gcal-day3-timed.txt")

with edit_config(config_path) as cfg:
    wc = cfg.setdefault("widget-config", {})
    widgets = ["title"]
    if wc.get("label#weather", {}).get("text", "").strip():
        widgets.append("label#weather")
    widgets.append("label#gcal-header")
    wc.setdefault("label#gcal-header", {})["text"] = (
        "󰃭  Upcoming Events" if total else "󰃭  No upcoming events"
    )

    for day, header, allday, timed in [
        ("today",    " Today",         today_allday,    today_timed),
        ("tomorrow", " Tomorrow",      tomorrow_allday, tomorrow_timed),
        ("day3",     f" {day3_label}", day3_allday,     day3_timed),
    ]:
        # Clear hidden rows so stale tasks cannot reappear after a checkout.
        for part, text in [("header", header if allday or timed else ""),
                           ("allday", allday), ("timed", timed)]:
            name = f"label#gcal-{day}-{part}"
            row = wc.setdefault(name, {})
            row["text"] = text
            row["max-lines"] = 30
            if text:
                widgets.append(name)

    widgets += ["mpris", "notifications", "dnd"]
    cfg["widgets"] = widgets
PYEOF

  swaync-client --reload-config
fi
