#!/usr/bin/env bash

# Silent copy flag check
SILENT_FLAG="${XDG_RUNTIME_DIR:-/tmp}/cliphist-silent"
if [ -f "$SILENT_FLAG" ]; then
    rm "$SILENT_FLAG"
    exit 0
fi

PM_APPS_REGEX='(Bitwarden|bitwarden|KeePassXC|keepassxc|1Password|lastpass|gnome-keyring)'
KEY_MARKERS_REGEX='(BEGIN (OPENSSH|RSA|DSA|EC|ENCRYPTED)? ?PRIVATE KEY|ssh-|ecdsa-sha2)'
JWT_REGEX='eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]+'
GIT_TOKEN_REGEX='(gh[pous]_[A-Za-z0-9]{20,}|pat_[A-Za-z0-9]{20,})'
OTP_REGEX='^[0-9]{6}$'
HEX64_REGEX='^[A-Fa-f0-9]{64,}$'

# Skip if focused app is a password manager
focused_class="$(hyprctl activewindow -j 2>/dev/null | jq -r '.class // ""')"
[[ "$focused_class" =~ $PM_APPS_REGEX ]] && exit 0

# Read clipboard content
data="$(cat)"
[ -z "$data" ] && exit 0

# Skip sensitive patterns
echo "$data" | grep -qiE "$KEY_MARKERS_REGEX" && exit 0
echo "$data" | grep -qE "$JWT_REGEX"          && exit 0
echo "$data" | grep -qE "$GIT_TOKEN_REGEX"    && exit 0
echo "$data" | grep -qE "$OTP_REGEX"          && exit 0
echo "$data" | grep -qE "$HEX64_REGEX"        && exit 0

# Store if clean
echo "$data" | cliphist store
