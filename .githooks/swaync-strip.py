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

for key, val in cfg.get("widget-config", {}).items():
    if (key.startswith("label#gcal-") or key == "label#weather") and isinstance(val, dict) and "text" in val:
        val["text"] = ""

json.dump(cfg, sys.stdout, indent=2, ensure_ascii=False)
sys.stdout.write("\n")
