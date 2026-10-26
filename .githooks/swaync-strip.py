#!/usr/bin/env python3
# git clean filter: blank the generated calendar/weather labels in swaync's
# config.json so personal schedule data never gets committed.
import json
import sys


def reject_constant(_value):
    # Python accepts NaN/Infinity by default, but they are not valid JSON.
    raise ValueError("Non-JSON constant")


def refuse_input():
    # Never include input or exception details: either can contain private text.
    print(
        "swaync-strip: invalid JSON or widget structure; "
        "refusing to output unfiltered content.",
        file=sys.stderr,
    )
    sys.exit(1)


def dynamic(name):
    return name.startswith("label#gcal-") or name == "label#weather"


try:
    raw = sys.stdin.buffer.read().decode("utf-8")
    cfg = json.loads(raw, parse_constant=reject_constant)
    if not isinstance(cfg, dict):
        raise ValueError("Expected an object")
    widget_config = cfg.get("widget-config", {})
    if not isinstance(widget_config, dict):
        raise ValueError("Expected widget-config to be an object")
    if "widgets" in cfg and (
        not isinstance(cfg["widgets"], list)
        or any(not isinstance(name, str) for name in cfg["widgets"])
    ):
        raise ValueError("Expected a list of widget names")
    for name, value in widget_config.items():
        if dynamic(name) and not isinstance(value, dict):
            raise ValueError("Expected generated widget settings to be an object")
except (ValueError, RecursionError):
    refuse_input()

for key, val in widget_config.items():
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

# Finish serialization before emitting anything, so failures cannot leave a
# partially filtered document on stdout.
try:
    rendered = json.dumps(cfg, indent=2, ensure_ascii=False, allow_nan=False) + "\n"
    output = rendered.encode("utf-8")
except (ValueError, RecursionError):
    refuse_input()
sys.stdout.buffer.write(output)
