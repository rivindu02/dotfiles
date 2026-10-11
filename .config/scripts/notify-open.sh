#!/bin/bash
# notify-open — run by swaync (config.json "scripts", run-on: action) when a
# Screenshot or Taildrop notification is clicked, in the popup or the panel.
# The sender passes the file with: notify-send -h string:filepath:<path> -A default=...
# swaync hands it over as SWAYNC_HINT_FILEPATH, wrapped in single quotes.

path=${SWAYNC_HINT_FILEPATH#\'}
path=${path%\'}
[[ -n "$path" && -e "$path" ]] || exit 0

case "$SWAYNC_APP_NAME" in
    Screenshot) setsid -f swayimg "$path" >/dev/null 2>&1 ;;
    Taildrop)   setsid -f ghostty -e yazi "$path" >/dev/null 2>&1 ;;
esac
