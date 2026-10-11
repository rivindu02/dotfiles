#!/usr/bin/env bash
# Turn ~/backup and ~/Downloads into nested btrfs subvolumes so snapper's
# `home` config stops snapshotting them (snapper never descends into nested
# subvolumes). Deleting files there then frees space immediately instead of
# waiting for timeline snapshots to rotate out.
#
# Run as your user, NOT with sudo: unprivileged `btrfs subvolume create` works
# in a directory you own, and the copy keeps your ownership.
# Close Telegram, browsers and anything else writing into these dirs first.
#
# Copy uses reflinks (cp --reflink=always), so it costs no extra disk space and
# finishes in seconds to minutes. The original folder is kept as
# <name>.pre-subvol; delete it yourself after checking (see AUDIT.md §5).
set -euo pipefail

if [[ $EUID -eq 0 ]]; then
    echo "Run as your user, not root." >&2
    exit 1
fi

for dir in "$HOME/backup" "$HOME/Downloads"; do
    old="$dir.pre-subvol"
    echo "== $dir"

    if btrfs subvolume show "$dir" &>/dev/null; then
        echo "   already a subvolume, skipping"
        continue
    fi
    if [[ -e $old ]]; then
        echo "   $old already exists, resolve it first" >&2
        exit 1
    fi
    if lsof +D "$dir" &>/dev/null; then
        echo "   files in $dir are open:" >&2
        lsof +D "$dir" 2>/dev/null | head >&2
        exit 1
    fi

    mv -- "$dir" "$old"
    btrfs subvolume create "$dir"
    chmod --reference="$old" "$dir"
    cp -a --reflink=always -- "$old/." "$dir/"

    n_old=$(find "$old" | wc -l)
    n_new=$(find "$dir" | wc -l)
    echo "   entries: old=$n_old new=$n_new"
    if [[ $n_old -ne $n_new ]]; then
        echo "   MISMATCH, investigate before deleting $old" >&2
        exit 1
    fi
done

echo
echo "Done. Verify, then remove the old copies:"
echo "  rm -rf ~/backup.pre-subvol ~/Downloads.pre-subvol"
echo "Their blocks stay pinned by home snapshot(s) until those rotate out."
