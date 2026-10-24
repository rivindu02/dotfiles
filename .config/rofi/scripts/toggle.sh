#!/usr/bin/env bash
# Source before opening a workflow; repeating any menu shortcut dismisses Rofi.
rofi_toggle() {
    if pgrep -u "$UID" -x rofi >/dev/null; then
        pkill -u "$UID" -x rofi || true
        return 1
    fi
    return 0
}

# Python menus use the same check before fetching their data.
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    rofi_toggle
fi
