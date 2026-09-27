#!/usr/bin/env python3
# git clean filter: blank the generated calendar/weather labels in swaync's
# config.json so personal schedule data never gets committed.
import json, sys

raw = sys.stdin.read()
try:
    cfg = json.loads(raw)
except json.JSONDecodeError:
    sys.stdout.write(raw)
    sys.exit(0)

def dynamic(name):
    return name.startswith("label#gcal-") or name == "label#weather"

for key, val in cfg.get("widget-config", {}).items():
    if dynamic(key) and isinstance(val, dict) and "text" in val:
        val["text"] = ""

# gcal-widget.sh only lists the day sections that currently have events; store
# the full fixed list instead so the committed file doesn't change with the calendar.
if isinstance(cfg.get("widgets"), list):
    canonical = ["label#weather", "label#gcal-header"] + [
        f"label#gcal-{day}-{part}"
        for day in ("today", "tomorrow", "day3")
        for part in ("header", "allday", "timed")
    ]
    canonical = [w for w in canonical if w in cfg.get("widget-config", {})]
    static = [w for w in cfg["widgets"] if not dynamic(w)]
    at = static.index("title") + 1 if "title" in static else 0
    cfg["widgets"] = static[:at] + canonical + static[at:]

json.dump(cfg, sys.stdout, indent=2, ensure_ascii=False)
sys.stdout.write("\n")
