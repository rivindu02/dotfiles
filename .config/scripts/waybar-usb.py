#!/usr/bin/env python3
"""Waybar USB storage status and safe ejection via UDisks."""
import fcntl
import html
import json
import os
from pathlib import Path
import subprocess
import sys


LOCK = Path(os.environ.get('XDG_RUNTIME_DIR', f'/run/user/{os.getuid()}')) / 'backup-usb.lock'


def run(*args):
    return subprocess.run(args, capture_output=True, text=True, timeout=60)


def nodes(device):
    yield device
    for child in device.get('children', []):
        yield from nodes(child)


def mounts(device):
    return [m for m in device.get('mountpoints', []) if m]


def drives():
    result = run('lsblk', '--json', '--paths', '--output', 'NAME,TYPE,TRAN,LABEL,MOUNTPOINTS,SIZE')
    if result.returncode:
        raise RuntimeError(result.stderr.strip() or 'Unable to list USB drives')
    return [d for d in json.loads(result.stdout)['blockdevices']
            if d.get('tran') == 'usb' and d['type'] == 'disk'
            and not any(m == '[SWAP]' or m in ('/', '/home', '/boot', '/boot/efi')
                        for n in nodes(d) for m in mounts(n))]


def busy():
    # Includes manual restic operations, as well as the entire HDD service startup.
    service = run('systemctl', '--user', 'show', 'backup-hdd.service', '--property=ActiveState', '--value')
    if service.returncode:
        raise RuntimeError('Unable to check backup service status')
    process = run('pgrep', '-x', 'restic')
    if process.returncode not in (0, 1):
        raise RuntimeError('Unable to check running restic operations')
    return service.stdout.strip() in ('active', 'activating', 'deactivating', 'reloading') or process.returncode == 0


def notify(title, body, urgency='normal'):
    run('notify-send', '-a', 'USB storage', '-u', urgency, title, body)


def label(device):
    return next((n['label'] for n in nodes(device) if n.get('label')), device['name'])


def status():
    devices = drives()
    if not devices:
        return {'text': '', 'tooltip': '', 'class': 'disconnected'}
    state = 'ready'
    with LOCK.open('a+') as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            lock.seek(0)
            state = 'ejecting' if lock.read().strip() == 'ejecting' else 'busy'
        else:
            if busy():
                state = 'busy'
    lines = []
    for device in devices:
        points = [m for n in nodes(device) for m in mounts(n)]
        lines.append(f"{label(device)} ({device['size']})\n" + ('Mounted: ' + ', '.join(points) if points else 'Unmounted'))
    lines.append({'busy': 'Backup/restic operation in progress — ejection blocked',
                  'ejecting': 'Ejecting — wait for confirmation',
                  'ready': 'Click to safely eject' if len(devices) == 1 else 'Multiple USB drives connected — connect one at a time to eject'}[state])
    return {'text': '󰕓', 'class': state, 'tooltip': html.escape('\n\n'.join(lines))}


def eject():
    with LOCK.open('a+') as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            notify('USB drive is busy', 'Backup or ejection in progress — wait before ejecting.')
            return
        if busy():
            notify('Backup in progress', 'Wait for backup and cleanup to finish before ejecting.')
            return
        devices = drives()
        if len(devices) != 1:
            notify('USB ejection', 'Connect exactly one USB storage drive to eject it.')
            return
        device = devices[0]
        # Encrypted/mapped volumes require a separate unlock/lock workflow.
        if any(n['type'] not in ('disk', 'part') for n in nodes(device)):
            raise RuntimeError('This drive has mapped volumes. Close them with your disk manager before ejecting.')
        lock.seek(0)
        lock.truncate()
        lock.write('ejecting\n')
        lock.flush()
        for node in reversed(list(nodes(device))):
            if mounts(node):
                result = run('udisksctl', 'unmount', '--block-device', node['name'], '--no-user-interaction')
                if result.returncode:
                    raise RuntimeError(result.stderr.strip() or result.stdout.strip() or 'Unmount failed; close files on the drive and try again.')
        result = run('udisksctl', 'power-off', '--block-device', device['name'], '--no-user-interaction')
        if result.returncode:
            raise RuntimeError(result.stderr.strip() or result.stdout.strip() or 'Unable to power off USB drive')
        notify('Safe to unplug', f'{label(device)} has been unmounted and powered off.')


def main():
    action = sys.argv[1] if len(sys.argv) > 1 else 'status'
    try:
        if action == 'eject':
            eject()
        elif action == 'status':
            print(json.dumps(status()))
        else:
            raise RuntimeError('Usage: waybar-usb.py [status|eject]')
    except (OSError, ValueError, RuntimeError, subprocess.SubprocessError) as error:
        if action == 'status':
            print(json.dumps({'text': '󰕓', 'class': 'error', 'tooltip': html.escape(str(error))}))
        else:
            notify('Could not eject USB drive', str(error), 'critical')
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
