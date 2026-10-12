#!/usr/bin/env bash
# Copy the LUKS header of the laptop disk to the USB HDD. If the header on
# nvme0n1p3 is ever damaged, this file plus your passphrase is the only way back in:
#   sudo cryptsetup luksHeaderRestore /dev/nvme0n1p3 --header-backup-file <file>
# The file is useless without the passphrase, but keep it off-laptop only.
#
# Run: sudo ~/dotfiles/system/apply-luks-header-backup.sh
set -euo pipefail

DEV=/dev/nvme0n1p3
LABEL="Rivindu's HDD"

if [[ $EUID -ne 0 ]]; then
    echo "Run with sudo." >&2
    exit 1
fi

# Check each step: findmnt with an empty argument prints "/"
dev=$(blkid -L "$LABEL" || true)
[[ -n "$dev" ]] || { echo "HDD \"$LABEL\" is not plugged in." >&2; exit 1; }
mnt=$(printf '%b' "$(findmnt -rno TARGET "$dev" | head -1)")
[[ -n "$mnt" && "$mnt" != / ]] || { echo "HDD \"$LABEL\" is not mounted (udisksctl mount -b $dev)." >&2; exit 1; }

out="$mnt/luks-header-$(cat /etc/hostname)-$(date +%Y-%m-%d_%H-%M).img"
cryptsetup luksHeaderBackup "$DEV" --header-backup-file "$out"
sync -f "$out"
# A drive that drops off mid-write leaves an empty or short file behind
size=$(stat -c %s "$out")
if (( size < 1048576 )); then
    echo "Header file is only $size bytes; the HDD probably disconnected. Replug it and run again." >&2
    exit 1
fi
chown "${SUDO_UID:-0}:${SUDO_GID:-0}" "$out"
chmod 600 "$out"
echo "Saved: $out"
