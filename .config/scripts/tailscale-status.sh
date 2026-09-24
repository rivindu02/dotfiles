#!/usr/bin/env bash
# Waybar module — Tailscale status
# Outputs JSON for waybar custom module consumption

status_json=$(tailscale status --json 2>/dev/null)

if [[ -z "$status_json" ]] || ! echo "$status_json" | jq -e '.Self' &>/dev/null; then
    echo '{"text": "󰖂", "tooltip": "Tailscale: not running", "class": "disconnected"}'
    exit 0
fi

hostname=$(echo "$status_json" | jq -r '.Self.DNSName | split(".")[0]')
ip=$(echo "$status_json" | jq -r '.Self.TailscaleIPs[0]')
online_count=$(echo "$status_json" | jq '[.Peer[] | select(.Online == true)] | length')
total_count=$(echo "$status_json" | jq '[.Peer[]] | length')

tooltip="$hostname  $ip  $online_count/$total_count online"
jq -cn --arg tooltip "$tooltip" '{text: "󰖂", tooltip: $tooltip, class: "connected"}'
