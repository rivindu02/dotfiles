#!/bin/bash

# eventN numbering depends on probe order; by-path is stable across boots
DEVICE=/dev/input/by-path/platform-asus-nb-wmi-event
[ -e "$DEVICE" ] || DEVICE=/dev/input/event8

evtest "$DEVICE" | while read -r line; do
    if echo "$line" | grep -q "KEY_CAMERA.*value 1"; then
        if lsmod | grep -q uvcvideo; then
            echo -n "3-8" > /sys/bus/usb/drivers/usb/unbind 2>/dev/null
            modprobe -r uvcvideo 2>/dev/null
            echo 1 > /sys/class/leds/asus::camera/brightness
        else
            modprobe uvcvideo
            echo -n "3-8" > /sys/bus/usb/drivers/usb/bind 2>/dev/null
            echo 0 > /sys/class/leds/asus::camera/brightness
        fi
    fi
done
