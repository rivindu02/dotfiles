#!/usr/bin/env bash
# Remove only the GTK4/libadwaita holds, then perform a full Arch upgrade.
# Blur compatibility is provided by GDK_WAYLAND_DISABLE in the desktop config.
# Usage: sudo bash system/restore-gtk-upgrades.sh [--dry-run]
set -euo pipefail

dry_run=0
case "${1:-}" in
    --dry-run) dry_run=1 ;;
    '') ;;
    *) printf 'Usage: %s [--dry-run]\n' "$0" >&2; exit 2 ;;
esac
if [[ $EUID -ne 0 && $dry_run == 0 ]]; then
    printf 'Run with sudo, or use --dry-run to preview.\n' >&2
    exit 1
fi

python3 - /etc/pacman.conf "$dry_run" <<'PY'
from pathlib import Path
import datetime
import difflib
import os
import re
import shutil
import stat
import sys
import tempfile

path = Path(sys.argv[1])
original = path.read_text()
lines = []
section = ''
for line in original.splitlines(keepends=True):
    if line.strip().startswith('['):
        section = line.strip()
    match = re.match(r'^(\s*IgnorePkg\s*=)([^#\n]*)(.*?)(\n?)$', line)
    if section == '[options]' and match:
        kept = [p for p in match[2].split() if p not in {'gtk4', 'libadwaita'}]
        if kept:
            line = match[1] + ' ' + ' '.join(kept) + (' ' + match[3] if match[3] else '') + match[4]
        else:
            line = '# GTK4/libadwaita holds removed; use current repository packages.\n'
            if match[3]:
                line += match[3] + match[4]
    lines.append(line)
updated = ''.join(lines)
if sys.argv[2] == '1':
    print(''.join(difflib.unified_diff(original.splitlines(True), updated.splitlines(True), fromfile=str(path), tofile='proposed')), end='')
    print('Next step: pacman -Syu --needed (full system upgrade).')
elif updated != original:
    backup = path.with_name(path.name + '.before-gtk-upgrade-' + datetime.datetime.now().strftime('%Y%m%d-%H%M%S-%f'))
    shutil.copy2(path, backup)
    fd, temporary = tempfile.mkstemp(prefix='.pacman.conf-', dir=path.parent)
    try:
        with os.fdopen(fd, 'w') as f:
            os.fchmod(f.fileno(), stat.S_IMODE(path.stat().st_mode))
            f.write(updated)
            f.flush()
            os.fsync(f.fileno())
        if path.read_text() != original:
            raise SystemExit('pacman.conf changed during review; refusing to overwrite it.')
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)
    print('Removed GTK holds. Original saved at:', backup)
else:
    print('No GTK4/libadwaita holds remain.')
PY

if (( dry_run )); then exit 0; fi
pacman -Syu --needed
pacman -Q gtk4 libadwaita
printf '\nLog out/in and restart GTK apps to apply the updated libraries and blur environment.\n'
