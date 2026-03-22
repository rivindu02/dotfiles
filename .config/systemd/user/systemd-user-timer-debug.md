# systemd User Timer — Debug Guide

> Reference for `gcal-widget.timer` and any future `--user` timer issues on Arch Linux.

---

## File Locations

| File | Path |
|------|------|
| Timer unit | `~/.config/systemd/user/gcal-widget.timer` |
| Service unit | `~/.config/systemd/user/gcal-widget.service` |
| Script | `~/.config/scripts/gcal-widget.sh` |
| Persistent journal | `/var/log/journal/<machine-id>/` |

---

## Correct Unit File Structure

### `gcal-widget.timer`
```ini
[Unit]
Description=Refresh gcal events in swaync every 1 minute

[Timer]
OnBootSec=30
OnCalendar=*:0/1
Persistent=true

[Install]
WantedBy=timers.target
```

### `gcal-widget.service`
```ini
[Unit]
Description=Update gcal events in swaync

[Service]
Type=oneshot
Environment=DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1001/bus
Environment=XDG_RUNTIME_DIR=/run/user/1001
Environment=HOME=/home/rivindu02
ExecStart=/home/rivindu02/.config/scripts/gcal-widget.sh
```

> **Critical rule:** Never mix `[Timer]` and `[Service]` sections in the same file.  
> `WantedBy=timers.target` goes in the `.timer` file, not the `.service` file.

---

## Essential Commands

### Status & Monitoring
```bash
# Check timer status
systemctl --user status gcal-widget.timer

# Check service status
systemctl --user status gcal-widget.service

# List all timers — verify NEXT has a real timestamp
systemctl --user list-timers --all | grep gcal

# Watch logs live
journalctl --user -u gcal-widget.service -f

# Last 50 log lines
journalctl --user -u gcal-widget.service --no-pager -n 50
```

### Control
```bash
# After editing any unit file — always run this first
systemctl --user daemon-reload

# Enable timer to start on login
systemctl --user enable gcal-widget.timer

# Start/stop/restart timer
systemctl --user start gcal-widget.timer
systemctl --user stop gcal-widget.timer
systemctl --user restart gcal-widget.timer

# Manually trigger the service (for testing)
systemctl --user start gcal-widget.service
```

---

## Diagnosing Common Failures

### Timer shows `Trigger: n/a` or `active (elapsed)`

The timer fired once and stopped scheduling the next run.

**Check 1:** Did the service fail?
```bash
systemctl --user status gcal-widget.service
```
If it shows `failed` or a non-zero exit code, fix the service first, then restart the timer.

**Check 2:** Wait 10s and check again — `n/a` right after a restart is normal:
```bash
sleep 10 && systemctl --user list-timers --all | grep gcal
```
If `NEXT` still shows `-`, the timer is genuinely broken.

**Fix:** Restart the timer after fixing the underlying issue:
```bash
systemctl --user restart gcal-widget.timer
```

---

### Journal shows `-- No entries --`

Persistent journal was not enabled. All logs were lost on reboot.

**Fix (one-time setup):**
```bash
sudo mkdir -p /etc/systemd/journald.conf.d/
echo -e "[Journal]\nStorage=persistent" | sudo tee /etc/systemd/journald.conf.d/persistent.conf
sudo systemctl restart systemd-journald
```

**Verify:**
```bash
ls /var/log/journal/   # Should show a machine-ID directory
```

---

### Service exits with non-zero status / script errors

**Test the script manually with the exact same environment:**
```bash
DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1001/bus \
XDG_RUNTIME_DIR=/run/user/1001 \
HOME=/home/rivindu02 \
bash ~/.config/scripts/gcal-widget.sh
```

**Common cause — missing PATH inside systemd environment:**

Tools available in your terminal may not exist in the systemd env. Add this to the `[Service]` block:
```ini
Environment=PATH=/usr/local/bin:/usr/bin:/bin:/home/rivindu02/.local/bin
```

**Check script is executable:**
```bash
chmod +x ~/.config/scripts/gcal-widget.sh
```

---

### `OnUnitActiveSec` stops repeating

`OnUnitActiveSec` counts from when the service was last active and can stop if the service fails or timing drifts. Prefer `OnCalendar` for reliable repeating timers.

| Use case | Recommended directive |
|----------|----------------------|
| Every N minutes forever | `OnCalendar=*:0/N` |
| Every hour | `OnCalendar=hourly` |
| Every day at midnight | `OnCalendar=daily` |
| Every 5 minutes | `OnCalendar=*:0/5` |
| Relative repeat (fragile) | `OnUnitActiveSec=Nmin` |

---

## Full Reset Procedure

If everything is broken and you want to start clean:

```bash
systemctl --user stop gcal-widget.timer
systemctl --user disable gcal-widget.timer
systemctl --user daemon-reload

# Re-edit unit files as needed, then:
systemctl --user daemon-reload
systemctl --user enable --now gcal-widget.timer

# Verify
systemctl --user list-timers --all | grep gcal
```

---

## Quick Health Check (run this any time something feels off)

```bash
echo "=== Timer ===" && systemctl --user status gcal-widget.timer
echo "=== Service ===" && systemctl --user status gcal-widget.service
echo "=== Next trigger ===" && systemctl --user list-timers --all | grep gcal
echo "=== Last 10 log lines ===" && journalctl --user -u gcal-widget.service --no-pager -n 10
```

---

*Last updated: 2026-03-14 | Arch Linux, systemd user session, UID 1001*
