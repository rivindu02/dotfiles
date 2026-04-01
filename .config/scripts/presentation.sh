#!/bin/bash
LAPTOP="eDP-1"
EXTERNAL=$(hyprctl monitors all -j | jq -r '.[].name' | grep -v "$LAPTOP" | head -1)

if [[ -z "$EXTERNAL" ]]; then
    notify-send "Presentation" "No external display detected" -i display -t 2000
    exit 0
fi

CHOICE=$(printf "󰍺  Mirror\n󰖲  Extend (external up)\n  Laptop only\n󰹑  External only\n󰕍  Restore defaults" | \
    rofi -dmenu -p "Display" \
    -theme ~/.config/rofi/powermenu/type-1/style-1.rasi \
    -theme-str 'listview { lines: 5; } inputbar { enabled: false; }' \
    -no-custom -no-fixed-num-lines)

[[ -z "$CHOICE" ]] && exit 0

case "$CHOICE" in
    *Mirror*)
        # Match actual refresh rates to avoid the "incorrect setup" warning
        hyprctl keyword monitor "$LAPTOP,1920x1080@60,0x1080,1.0"
        hyprctl keyword monitor "$EXTERNAL,1920x1080@60,0x0,1.0,mirror,$LAPTOP"
        notify-send "Display" "Mirroring on $EXTERNAL" -i display -t 2000
        ;;

    *Extend*)
        # HDMI-A-1 on top (y=0), eDP-1 below (y=1080) — matches your nwg layout
        hyprctl keyword monitor "$EXTERNAL,1920x1080@60,0x0,1.0"
        hyprctl keyword monitor "$LAPTOP,1920x1080@60,0x1080,1.0"
        notify-send "Display" "Extended: $EXTERNAL above, $LAPTOP below" -i display -t 2000
        ;;

    *Laptop*)
        # Move all workspaces off external before disabling it
        for ws in $(hyprctl workspaces -j | jq -r ".[] | select(.monitor==\"$EXTERNAL\") | .id"); do
            hyprctl dispatch moveworkspacetomonitor "$ws $LAPTOP"
        done
        hyprctl keyword monitor "$LAPTOP,1920x1080@60,0x0,1.0"
        hyprctl keyword monitor "$EXTERNAL,disable"
        notify-send "Display" "Laptop screen only" -i display -t 2000
        ;;

    *External*)
		for ws in $(hyprctl workspaces -j | jq -r ".[] | select(.monitor==\"$LAPTOP\") | .id"); do
        hyprctl dispatch moveworkspacetomonitor "$ws $EXTERNAL"
		done
		# Move external to 0x0 FIRST, then disable laptop
		hyprctl keyword monitor "$EXTERNAL,1920x1080@60,0x0,1.0"
		sleep 0.3
		hyprctl keyword monitor "$LAPTOP,disable"
		notify-send "Display" "External screen only" -i display -t 2000
		;;
    *Restore*)
        # Re-apply nwg-displays active profile
        hyprctl keyword source /home/rivindu02/.config/nwg-displays/hyprland.conf
		notify-send "Display" "Restored nwg-displays layout" -i display -t 2000
		;;
esac
