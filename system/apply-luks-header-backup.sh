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

mnt=$(findmnt -rno TARGET "$(blkid -L "$LABEL")" | head -1)
mnt=$(printf '%b' "$mnt")
[[ -n "$mnt" ]] || { echo "HDD \"$LABEL\" is not mounted." >&2; exit 1; }

out="$mnt/luks-header-$(hostname)-$(date +%Y-%m-%d).img"
cryptsetup luksHeaderBackup "$DEV" --header-backup-file "$out"
chown "${SUDO_UID:-0}:${SUDO_GID:-0}" "$out"
chmod 600 "$out"
echo "Saved: $out"
