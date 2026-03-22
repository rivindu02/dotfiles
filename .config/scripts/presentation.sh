#!/bin/bash

LAPTOP="eDP-1"
EXTERNAL=$(hyprctl monitors all | grep "Monitor" | awk '{print $2}' | grep -v "$LAPTOP" | head -1)

if [[ -z "$EXTERNAL" ]]; then
    notify-send "Presentation" "No external display detected" -i display -t 2000
    exit 0
fi

CHOICE=$(printf "󰍺  Mirror\n󰖲  Extend (external right)\n  Laptop only\n󰹑  External only\n󰕍  Restore defaults" | \
    rofi -dmenu -p "Display" \
    -theme ~/.config/rofi/powermenu/type-1/style-1.rasi \
    -theme-str 'listview { lines: 5; } inputbar { enabled: false; }' \
    -no-custom -no-fixed-num-lines)

[[ -z "$CHOICE" ]] && exit 0

case "$CHOICE" in
    *Mirror*)
        hyprctl keyword monitor "$LAPTOP,1920x1080@120,0x0,1.0"
        hyprctl keyword monitor "$EXTERNAL,1920x1080@60,0x0,1.0,mirror,$LAPTOP"
        notify-send "Display" "Mirroring on $EXTERNAL" -i display -t 2000
        ;;
    *Extend*)
        hyprctl keyword monitor "$LAPTOP,1920x1080@120,0x0,1.0"
        hyprctl keyword monitor "$EXTERNAL,preferred,1920x0,1.0"
        notify-send "Display" "Extended to $EXTERNAL" -i display -t 2000
        ;;
    *Laptop*)
        hyprctl keyword monitor "$LAPTOP,1920x1080@120,0x0,1.0"
        hyprctl keyword monitor "$EXTERNAL,disable"
        notify-send "Display" "Laptop screen only" -i display -t 2000
        ;;
    *External*)
        hyprctl keyword monitor "$LAPTOP,disable"
        hyprctl keyword monitor "$EXTERNAL,preferred,0x0,1.0"
        notify-send "Display" "External screen only" -i display -t 2000
        ;;
    *Restore*)
        hyprctl keyword source ~/.config/hypr/monitors.conf
        notify-send "Display" "Restored default layout" -i display -t 2000
        ;;
esac
