#!/bin/bash
# location /usr/lib/systemd/system-sleep/asus-sleep.sh
case "$1" in
    pre)
        # kill keyboard backlight
        echo 0 > /sys/class/leds/asus::kbd_backlight/brightness
        # stop asusd before sleep
        systemctl stop asusd
        ;;
    post)
        # restart asusd on wake
        systemctl start asusd
        ;;
esac
