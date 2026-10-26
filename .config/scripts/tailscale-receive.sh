#!/usr/bin/env bash
# tailscale-receive — auto-accept incoming Taildrop files
# Runs as a systemd user service, sends swaync notifications on receipt.

DOWNLOAD_DIR="$HOME/tailscale"
if ! mkdir -p "$DOWNLOAD_DIR"; then
    echo "tailscale-receive: cannot prepare the download directory; exiting." >&2
    exit 1
fi

retry_delay=5
max_retry_delay=60

# "<mtime> <name>" per entry, one per line; the name keeps any spaces intact
snapshot() {
    find "$DOWNLOAD_DIR" -mindepth 1 -maxdepth 1 -printf '%T@ %f\n' 2>/dev/null | sort
}

while true; do
    before=$(snapshot)

    # Block until files arrive, then download them
    # Keep command errors visible in the service journal.
    if tailscale file get --wait --conflict=rename "$DOWNLOAD_DIR"; then
        if (( retry_delay > 5 )); then
            echo "tailscale-receive: receive recovered; resetting retry delay." >&2
        fi
        retry_delay=5
        after=$(snapshot)

        # Newly added/modified entries; strip the leading "<mtime> " field
        mapfile -t new_files < <(comm -13 <(echo "$before") <(echo "$after") | cut -d' ' -f2-)
        count=${#new_files[@]}

        if [[ $count -eq 1 ]]; then
            # Click opens yazi with the file selected (swaync runs notify-open.sh)
            notify-send -a "Taildrop" -h "string:filepath:$DOWNLOAD_DIR/${new_files[0]}" \
                -A "default=Show in yazi" "󰒋 Taildrop" "Received: ${new_files[0]}" >/dev/null 2>&1 &
        elif [[ $count -gt 1 ]]; then
            notify-send -a "Taildrop" -h "string:filepath:$DOWNLOAD_DIR" \
                -A "default=Open folder" "󰒋 Taildrop" "Received $count files" >/dev/null 2>&1 &
        fi
    else
        status=$?
        printf 'tailscale-receive: receive failed (exit %d); retrying in %d seconds.\n' \
            "$status" "$retry_delay" >&2
        sleep "$retry_delay" || exit "$?"
        retry_delay=$(( retry_delay * 2 ))
        if (( retry_delay > max_retry_delay )); then
            retry_delay=$max_retry_delay
        fi
    fi
done
