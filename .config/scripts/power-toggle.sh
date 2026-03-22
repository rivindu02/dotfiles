#!/bin/bash

# ── Setup ────────────────────────────────────────────────────
# Define helper once at the top
dot() { [ "$current" = "$1" ] && echo "●" || echo "○"; }

is_asus() {
    local vendor=$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null | tr '[:upper:]' '[:lower:]')
    [[ "$vendor" == *"asus"* ]] && which asusctl &>/dev/null
}

# ── Logic ────────────────────────────────────────────────────
if is_asus; then
    current=$(asusctl profile get | grep "Active profile" | awk '{print tolower($NF)}')

    quiet="󰾆  Quiet         $(dot quiet)"
    balanced="󰾅  Balanced      $(dot balanced)"
    performance="󰾇  Performance   $(dot performance)"

    options=$(printf '%s\n' "$quiet" "$balanced" "$performance")
else
    # Check governor without sudo
    current=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)
    
    # Check if a 'force' file exists to determine if we are in Auto mode 
    # (auto-cpufreq usually clears this file when in --edit or --reset mode)
    if [ -f /var/lib/auto-cpufreq/force_state ]; then
        auto_tick="☐"
    else
        auto_tick="☑"
    fi

    powersaver="󰾆  Power Saver   $(dot powersave)"
    performance="󰾇  Performance   $(dot performance)"
    auto_mode="󰾅  Auto (daemon)  ${auto_tick}"

    options=$(printf '%s\n' "$powersaver" "$performance" "$auto_mode")
fi

# ── UI ───────────────────────────────────────────────────────
chosen=$(echo -e "$options" | rofi -dmenu -p "Power" -no-custom -no-fixed-num-lines \
            -theme ~/.config/rofi/powermenu/type-1/style-1.rasi \
            -theme-str 'listview { lines: 3; } inputbar { enabled: false; }' \
            -no-auto-select)

[[ -z "$chosen" ]] && exit 0

# ── Action ───────────────────────────────────────────────────
if is_asus; then
    case "$chosen" in
        *Quiet*)       asusctl profile set Quiet ;;
        *Balanced*)    asusctl profile set Balanced ;;
        *Performance*) asusctl profile set Performance ;;
    esac
    notify-send "Power Profile" "Switched to ${chosen%% *}" -t 2000
else
    case "$chosen" in
        *Power\ Saver*) pkexec auto-cpufreq --force=powersave ;;
        *Performance*)  pkexec auto-cpufreq --force=performance ;;
        *Auto*)         pkexec auto-cpufreq --force=reset ;;
    esac
    notify-send "Power Profile" "Applied ${chosen%% *}" -t 2000
fi
