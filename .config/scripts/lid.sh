#!/bin/bash
# ~/.config/scripts/lid.sh close|open
# Called by the Hyprland lid-switch binds on every lid event.
#   stay-awake on  → lock + laptop screen off; everything keeps running
#                    (toggle-idle.sh holds the handle-lid-switch inhibitor, so logind ignores the lid)
#   stay-awake off → suspend, even with an external monitor connected
#                    (logind suspends by itself when undocked; when docked it ignores the lid,
#                    so this script suspends instead)
LOG="${XDG_RUNTIME_DIR:-/tmp}/lid.log"
PIDFILE="${XDG_RUNTIME_DIR:-/tmp}/stay-awake.pid"

# libinput sends a fake "lid open" when it sees a keyboard event while the lid is
# closed, so trust the ACPI state, not the event.
lid_closed() { grep -q closed /proc/acpi/button/lid/*/state 2>/dev/null; }
log() { echo "$(date '+%F %T') $*" >> "$LOG"; }
stay_awake() { [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; }
docked() {
    busctl get-property org.freedesktop.login1 /org/freedesktop/login1 \
        org.freedesktop.login1.Manager Docked 2>/dev/null | grep -q true
}

case "$1" in
    close)
        log "close"
        loginctl lock-session      # hypridle's lock_cmd starts hyprlock
        sleep 0.3                  # let hyprlock map before the screen goes dark
        lid_closed || { log "close: lid reopened, screen left on"; exit 0; }
        hyprctl dispatch 'hl.dsp.dpms({ action = "off", monitor = "eDP-1" })' >/dev/null
        if ! stay_awake && docked; then
            log "close: docked without stay-awake, suspending"
            systemctl suspend
        fi
        ;;
    open)
        if lid_closed; then
            log "open ignored: ACPI says lid is still closed"
            exit 0
        fi
        log "open"
        hyprctl dispatch 'hl.dsp.dpms({ action = "on", monitor = "eDP-1" })' >/dev/null
        ;;
esac
