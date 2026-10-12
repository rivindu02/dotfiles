#!/usr/bin/env bash
# Stop the Seagate Expansion HDD from using UAS (see system/modprobe/usb-storage-quirks.conf).
# Applies now (for the next plug-in) and on every boot. Unplug and replug the HDD afterwards.
#
# Run: sudo ~/dotfiles/system/apply-hdd-no-uas.sh
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Run with sudo." >&2
    exit 1
fi

here=$(dirname "$(readlink -f "$0")")
install -Dm644 "$here/modprobe/usb-storage-quirks.conf" /etc/modprobe.d/usb-storage-quirks.conf

# usb-storage is built as a module and already loaded; set the quirk live too
echo "0bc2:231a:u" > /sys/module/usb_storage/parameters/quirks

# The module option is read in early boot only if the initramfs has usb-storage
mkinitcpio -P >/dev/null

echo "Done. Unplug the HDD, wait 5 s, plug it into a USB 3 port, then check:"
echo "  lsusb -t | grep -i storage    # should say Driver=usb-storage, 5000M"
