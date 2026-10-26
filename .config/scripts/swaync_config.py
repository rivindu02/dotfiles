"""Serialize generated widget updates and keep SwayNC's JSON readable."""

from contextlib import contextmanager
import fcntl
import json
import os
from pathlib import Path
import tempfile


@contextmanager
def edit_config(path):
    # Resolve the stow symlink before replacing the file.
    target = Path(path).resolve(strict=True)
    runtime = os.environ.get("XDG_RUNTIME_DIR") or tempfile.gettempdir()
    lock_path = Path(runtime) / f"swaync-config-{os.getuid()}.lock"
    with lock_path.open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        original = target.read_text()
        config = json.loads(original)
        yield config
        rendered = json.dumps(config, indent=2, ensure_ascii=False) + "\n"
        if rendered == original:
            return
        temporary = None
        try:
            with tempfile.NamedTemporaryFile(
                mode="w", encoding="utf-8", dir=target.parent, delete=False
            ) as output:
                temporary = Path(output.name)
                os.fchmod(output.fileno(), target.stat().st_mode & 0o777)
                output.write(rendered)
            os.replace(temporary, target)
        finally:
            if temporary is not None:
                temporary.unlink(missing_ok=True)
