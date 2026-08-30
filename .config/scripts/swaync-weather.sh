#!/bin/bash
# ~/.config/scripts/swaync-weather.sh
# Updates the weather label in swaync config and reloads.
# Run once at startup and on a timer (e.g. every 30 min via systemd or cron).
#
# Adds a "label#weather" widget to swaync showing:
#   🌦️  27°C  Colombo  ·  Feels 31°C  💧 78%  💨 12 km/h

export PATH="/home/rivindu02/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
SWAYNC_CONFIG="$HOME/.config/swaync/config.json"

# ── Fetch weather for Home and University ─────────────────────────
WEATHER_HOME_JSON=$(curl -sf --max-time 8 "wttr.in/Veyangoda?format=j1" 2>/dev/null)
WEATHER_UNI_JSON=$(curl -sf --max-time 8 "wttr.in/Katubedda?format=j1" 2>/dev/null)

if [[ -z "$WEATHER_HOME_JSON" ]] && [[ -z "$WEATHER_UNI_JSON" ]]; then
    WEATHER_TEXT="󰖑  Weather unavailable"
else
    # Parse with python3 (already installed)
    WEATHER_TEXT=$(python3 - <<PYEOF
import json, sys

def parse_weather(json_str, label_name):
    if not json_str.strip():
        return f"󰖑  {label_name} unavailable"
    try:
        data = json.loads(json_str)
        current = data["current_condition"][0]
        
        temp_c = current["temp_C"]
        desc = current["weatherDesc"][0]["value"]
        
        # Map weather description to emoji
        desc_lower = desc.lower()
        if "thunder" in desc_lower:
            icon = "⛈️"
        elif "snow" in desc_lower or "blizzard" in desc_lower:
            icon = "❄️"
        elif "heavy rain" in desc_lower or "torrential" in desc_lower:
            icon = "🌧️"
        elif "rain" in desc_lower or "drizzle" in desc_lower or "shower" in desc_lower:
            icon = "🌦️"
        elif "overcast" in desc_lower or "cloudy" in desc_lower:
            icon = "☁️"
        elif "mist" in desc_lower or "fog" in desc_lower or "haze" in desc_lower:
            icon = "🌫️"
        elif "partly" in desc_lower or "partly cloudy" in desc_lower:
            icon = "⛅"
        elif "sunny" in desc_lower or "clear" in desc_lower:
            icon = "☀️"
        else:
            icon = "🌡️"
            
        return f"{icon}  {temp_c}°C  {label_name}"
    except Exception:
        return f"󰖑  {label_name} error"

home_json = """$WEATHER_HOME_JSON"""
uni_json = """$WEATHER_UNI_JSON"""

home_text = parse_weather(home_json, "Home")
uni_text = parse_weather(uni_json, "University")

print(f"{home_text}  ·  {uni_text}")
PYEOF
    )
fi

# Fallback if python failed
[[ -z "$WEATHER_TEXT" ]] && WEATHER_TEXT="󰖑  Weather unavailable"

# ── Patch swaync config ──────────────────────────────────────────
python3 - "$SWAYNC_CONFIG" "$WEATHER_TEXT" <<'PYEOF'
import json, sys

config_path  = sys.argv[1]
weather_text = sys.argv[2]

with open(config_path) as f:
    cfg = json.load(f)

# Ensure weather widget-config entry exists
wc = cfg.setdefault("widget-config", {})
wc["label#weather"] = {
    "text":   weather_text,
    "markup": False
}

# Inject "label#weather" right after "title" if not already present
widgets = cfg.get("widgets", [])
if "label#weather" not in widgets:
    title_idx = widgets.index("title") if "title" in widgets else -1
    widgets.insert(title_idx + 1, "label#weather")
    cfg["widgets"] = widgets

with open(config_path, "w") as f:
    json.dump(cfg, f, indent=2, ensure_ascii=False)
PYEOF

# ── Reload swaync ────────────────────────────────────────────────
swaync-client --reload-config
