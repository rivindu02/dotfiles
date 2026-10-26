#!/usr/bin/env bash
# wl-paste --watch handler: text|image. Manual controls: pause|resume|status.
# Content is never put into shell variables or command arguments.
set -euo pipefail
umask 077

runtime=${XDG_RUNTIME_DIR:-}
if [[ -z "$runtime" || ! -d "$runtime" || -L "$runtime" || ! -O "$runtime" ]]; then
    printf '%s\n' 'cliphist: a private XDG_RUNTIME_DIR is required' >&2
    exit 1
fi
mode=$(stat -Lc '%a' -- "$runtime")
if (( (8#$mode & 077) != 0 )); then
    printf '%s\n' 'cliphist: XDG_RUNTIME_DIR must not be accessible by other users' >&2
    exit 1
fi

paused="$runtime/cliphist-paused"
case "${1:-text}" in
    pause)  : > "$paused"; exit 0 ;;
    resume) rm -f -- "$paused"; exit 0 ;;
    status) if [[ -e "$paused" ]]; then printf 'paused\n'; else printf 'recording\n'; fi; exit 0 ;;
    text|image) kind=${1:-text} ;;
    *) printf 'Usage: %s text|image|pause|resume|status\n' "$0" >&2; exit 2 ;;
esac

# These hints belong to the watched selection, unlike a later focus query.
case "${CLIPBOARD_STATE:-data}" in
    sensitive|nil|clear) exit 0 ;;
esac
[[ -e "$paused" ]] && exit 0

# Compatibility for an old picker/keybinding still running before reload.
# New callers use wl-copy --sensitive instead of this shared one-shot flag.
silent_flag="$runtime/cliphist-silent"
if [[ -f "$silent_flag" ]]; then
    rm -f -- "$silent_flag"
    exit 0
fi

password_manager_focused() {
    local focused_class
    # If focus cannot be checked, skip capture rather than assume it is safe.
    focused_class=$(hyprctl activewindow -j 2>/dev/null | jq -er '.class | select(type == "string" and length > 0)') || return 0
    [[ "${focused_class,,}" =~ (bitwarden|keepassxc|1password|lastpass|gnome-keyring) ]]
}
password_manager_focused && exit 0

payload=$(mktemp "$runtime/cliphist-selection.XXXXXX")
trap 'rm -f -- "$payload"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
cat > "$payload"
[[ -s "$payload" ]] || exit 0

if [[ "$kind" == text ]]; then
    matches_secret() {
        local result=0
        grep -aiqE -- "$1" "$payload" || result=$?
        case "$result" in
            0) return 0 ;;
            1) return 1 ;;
            *) printf 'cliphist: secret scan failed; capture skipped\n' >&2; exit "$result" ;;
        esac
    }
    patterns=(
        'BEGIN (OPENSSH|RSA|DSA|EC|ENCRYPTED)? ?PRIVATE KEY|ssh-|ecdsa-sha2'
        'eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]+'
        'gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|pat_[A-Za-z0-9]{20,}'
        'sk-[A-Za-z0-9_-]{16,}|gsk_[A-Za-z0-9_-]{16,}|AIza[0-9A-Za-z_-]{35}'
        '(AKIA|ASIA)[0-9A-Z]{16}|xox[abprs]-[0-9A-Za-z-]{10,}|hf_[A-Za-z0-9]{20,}'
        '^[0-9]{6}[[:space:]]*$|^[A-Fa-f0-9]{64,}[[:space:]]*$'
    )
    for pattern in "${patterns[@]}"; do
        if matches_secret "$pattern"; then exit 0; fi
    done
    assignments="(aws_secret_access_key|aws_session_token|aws_access_key_id|api[_-]?key|access[_-]?token|auth[_-]?token|client[_-]?secret|password|passwd)['\"]?[[:space:]]*[:=][[:space:]]*['\"]?[^[:space:]'\"]+"
    if matches_secret "$assignments"; then exit 0; fi
fi

# Focus is a supplemental check: browser extensions can look like a browser,
# and arbitrary passwords/screenshots cannot be recognized by token patterns.
# Pause capture explicitly for those workflows; images receive no OCR scan.
[[ -e "$paused" ]] && exit 0
password_manager_focused && exit 0
cliphist store < "$payload"
