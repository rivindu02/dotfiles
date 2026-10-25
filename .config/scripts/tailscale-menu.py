#!/usr/bin/env python3
"""Rofi Tailscale device menu, file sharing, and clickable Taildrop notifications."""

import html
import json
import os
from pathlib import Path
import socket
import subprocess
import sys
import tempfile

THEME = str(Path.home() / ".config/rofi/menus/tailscale.rasi")



def notify(message, path=None):
    command = ["notify-send", "-a", "Taildrop"]
    if path is not None:
        command += ["-h", f"string:filepath:{Path(path).resolve()}", "-A", "default=Show in Yazi"]
    subprocess.Popen(command + ["Taildrop", message], stdout=subprocess.DEVNULL,
                     stderr=subprocess.DEVNULL, start_new_session=True)


def tailscale_status():
    try:
        result = subprocess.run(["tailscale", "status", "--json"], capture_output=True,
                                text=True, timeout=3)
        return json.loads(result.stdout) if result.stdout else {}
    except (OSError, ValueError, subprocess.TimeoutExpired):
        return {}


def label(title, detail="", icon=""):
    title = "".join(c if c.isprintable() else " " for c in str(title))
    detail = html.escape("".join(c if c.isprintable() else " " for c in str(detail)))
    display = f"{icon}  {html.escape(title)}   <span size='small' foreground='#928374'>{detail}</span>"
    # Filter the name, keeping descriptive text out of fuzzy matching (e.g.
    # "ipad" otherwise matches the letters in "clipboard" on every device).
    return f"{title}\0display\x1f{display}"


def choose(rows, title, subtitle):
    first_action = next((i for i, (_, action) in enumerate(rows) if action is not None), 0)
    result = subprocess.run(
        ["rofi", "-dmenu", "-i", "-no-custom", "-no-auto-select",
         "-markup-rows", "-format", "i", "-selected-row", str(first_action), "-p", title, "-theme", THEME,
         "-mesg", html.escape(subtitle)],
        input="\n".join(row[0] for row in rows), text=True, capture_output=True,
    )
    try:
        index = int(result.stdout.strip())
        if result.returncode == 0 and 0 <= index < len(rows):
            return rows[index][1]
    except ValueError:
        pass
    return None


def peer_name(peer):
    return peer.get("DNSName", "").rstrip(".").split(".")[0] or peer.get("HostName") or "Unknown device"


def peer_ip(peer):
    return next(iter(peer.get("TailscaleIPs") or []), "")


def pick_file():
    with tempfile.TemporaryDirectory(prefix="sharing-", dir=os.environ.get("XDG_RUNTIME_DIR")) as directory:
        chooser = Path(directory) / "selection"
        subprocess.run(["ghostty", "--gtk-single-instance=false", "--class=yazi-picker",
                        "-e", "yazi", f"--chooser-file={chooser}"], check=False)
        if chooser.exists():
            paths = chooser.read_text().splitlines()
            if paths and Path(paths[0]).is_file():
                return Path(paths[0]).resolve()
    return None


def send_file(path, peer):
    target = peer_ip(peer)
    if not target:
        notify("This device has no Tailscale address.")
        return
    notify(f"Sending {path.name} to {peer_name(peer)}…")
    result = subprocess.run(["tailscale", "file", "cp", str(path), f"{target}:"],
                            capture_output=True, text=True)
    if result.returncode == 0:
        notify(f"Sent {path.name} to {peer_name(peer)}", path=path)
    else:
        notify("Transfer failed: " + (result.stderr.strip() or "Tailscale could not send the file.")[-700:])


def send_to_peer(peer):
    selected = choose([
        (label("Send a file", "Choose from your files", "󰈔"), "file"),
        (label("Send clipboard", "Text or an image", "󰅍"), "clipboard"),
        (label("Copy IP address", peer_ip(peer), "󰆏"), "copy"),
    ], peer_name(peer), "TAILSCALE  /  Choose what to share")
    if selected == "copy":
        copy_ip(peer)
    elif selected == "file":
        path = pick_file()
        if path:
            send_file(path, peer)
    elif selected == "clipboard":
        for mime, suffix in [("image/png", ".png"), ("text/plain", ".txt")]:
            result = subprocess.run(["wl-paste", "-t", mime], capture_output=True)
            if result.returncode == 0 and result.stdout:
                folder = Path.home() / "tailscale"
                folder.mkdir(mode=0o700, exist_ok=True)
                # Keep the sent item available when its notification is clicked.
                with tempfile.NamedTemporaryFile(prefix="Clipboard-", suffix=suffix,
                                                 dir=folder, delete=False) as saved:
                    saved.write(result.stdout)
                    path = Path(saved.name)
                send_file(path, peer)
                break
        else:
            notify("The clipboard has no text or image to share.")


def copy_ip(peer):
    address = peer_ip(peer)
    if address:
        subprocess.run(["wl-copy"], input=address, text=True, check=True)
        notify(f"Copied {peer_name(peer)}: {address}")


def build_rows(data):
    rows = []
    peers = list((data.get("Peer") or {}).values())
    online = sorted((p for p in peers if p.get("Online")), key=lambda p: peer_name(p).casefold())
    offline = sorted((p for p in peers if not p.get("Online")), key=lambda p: peer_name(p).casefold())
    for peer in online:
        detail = f"Online · {peer.get('OS', 'device')} · send files or clipboard"
        rows.append((label(peer_name(peer), detail, "󰖂"), ("peer", peer)))
    for peer in offline:
        rows.append((label(peer_name(peer), "Offline · copy IP address", "󰒎"), ("copy", peer)))
    return rows


def status():
    data = tailscale_status()
    peers = list((data.get("Peer") or {}).values())
    count = sum(bool(peer.get("Online")) for peer in peers)
    running = data.get("BackendState") == "Running"
    tooltip = f"Tailscale \n{count}/{len(peers)} devices online" if running else "Tailscale is unavailable "
    print(json.dumps({"text": "󰖂", "class": "connected" if running else "disconnected", "tooltip": tooltip}))


def menu():
    toggle = Path.home() / ".config/rofi/scripts/toggle.sh"
    if subprocess.run(["bash", str(toggle)], check=False).returncode != 0:
        return
    data = tailscale_status()
    rows = build_rows(data)
    if not rows:
        notify("No devices online" if data.get("BackendState") == "Running" else "Tailscale is unavailable")
        return
    online = sum(action[0] == "peer" for _, action in rows)
    subtitle = f"{socket.gethostname()} · {online} online · {len(rows) - online} offline"
    selected = choose(rows, "Tailscale", subtitle)
    if selected:
        action, peer = selected
        if action == "peer":
            send_to_peer(peer)
        elif action == "copy":
            copy_ip(peer)


if __name__ == "__main__":
    (status if len(sys.argv) > 1 and sys.argv[1] == "status" else menu)()
