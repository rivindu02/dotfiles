#!/bin/bash

FILE=~/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png

if grim -g "$(slurp)" "$FILE"; then
    wl-copy < "$FILE"
    notify-send "Screenshot" "Selected area saved & copied to clipboard" -i "$FILE" -t 2000
else
    rm -f "$FILE"
    exit 0
fi
