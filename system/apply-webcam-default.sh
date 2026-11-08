#!/usr/bin/env bash
# Reserve /dev/video10 for Droidcam so browsers default to a physical webcam.
set -euo pipefail

if (( EUID != 0 )); then
    printf 'Run with sudo: sudo bash %q\n' "$0" >&2
    exit 1
fi

here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
current=$(cat /sys/module/v4l2loopback_dc/parameters/video_nr 2>/dev/null || true)
if [[ -e /dev/video10 && "$current" != 10 ]]; then
    printf '/dev/video10 is already in use; no configuration changed.\n' >&2
    exit 1
fi
install -Dm644 "$here/modprobe/droidcam.conf" /etc/modprobe.d/droidcam.conf
if [[ -d /sys/module/v4l2loopback_dc && "$current" != 10 ]]; then
    if ! modprobe -r v4l2loopback_dc; then
        printf 'Configuration installed. Droidcam is busy; reboot to apply it.\n'
        exit 0
    fi
fi
modprobe v4l2loopback_dc
printf 'Droidcam uses /dev/video10. Reload camera sites or restart the browser.\n'
