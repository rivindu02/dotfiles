#!/bin/sh
# Arguments identify the active pane, including the tmux server to avoid collisions.
set -eu
[ "$#" -eq 3 ] || exit 1

proc=$(ps -t "$1" -o comm= 2>/dev/null | tail -n 1)
if [ "$proc" = ssh ]; then
    label=$(ps -t "$1" -o args= 2>/dev/null | tail -n 1 | awk '{print $NF}')
    color=d3869b
else
    label=$(cat "$HOME/.cache/tmux/pane-context/$2-${3#%}" 2>/dev/null || :)
    if [ -n "$label" ]; then
        color=d8a657
    else
        label=$(uname -n)
        color=7daea3
    fi
fi

label=$(printf '%s' "$label" | tr '[:lower:]' '[:upper:]' | tr -c '[:alnum:]_.:@-' '_')
printf '#[bg=#%s fg=#282828 bold] 󰒋 %s ' "$color" "$label"
