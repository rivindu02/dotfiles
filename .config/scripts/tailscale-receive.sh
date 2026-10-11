#!/usr/bin/env bash
# tailscale-receive — auto-accept incoming Taildrop files
# Runs as a systemd user service, sends swaync notifications on receipt.

DOWNLOAD_DIR="$HOME/tailscale"
mkdir -p "$DOWNLOAD_DIR"

# "<mtime> <name>" per entry, one per line; the name keeps any spaces intact
snapshot() {
    find "$DOWNLOAD_DIR" -mindepth 1 -maxdepth 1 -printf '%T@ %f\n' 2>/dev/null | sort
}

while true; do
    before=$(snapshot)

    # Block until files arrive, then download them
    if tailscale file get --wait --conflict=rename "$DOWNLOAD_DIR" 2>/dev/null; then
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
    fi
done
