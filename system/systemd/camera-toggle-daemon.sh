#!/bin/bash

evtest /dev/input/event8 | while read line; do
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
