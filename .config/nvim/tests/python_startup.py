#!/usr/bin/env python3
"""Check actual Neovim startup for project, standalone, and new Python files.

Requires the configured plugins, tools, and parsers to already be installed.
Uses temporary files/editor state; disables Supermaven and registry refreshes.
"""
import os
from pathlib import Path
import subprocess
import tempfile


CONFIG = Path(__file__).resolve().parents[1]
DATA = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local/share")) / "nvim"
SOURCE = "import os\n\ndef add(a: int, b: int) -> int:\n    return a + b\n\nanswer = add(1, 2)\n"


def main():
    # /tmp has a synthetic parent .git in the execution environment. Use /var/tmp
    # so the standalone case really exercises a file without project markers.
    with tempfile.TemporaryDirectory(prefix="nvim-python-startup-", dir="/var/tmp") as temporary:
        root = Path(temporary)
        data = root / "data/nvim"
        data.mkdir(parents=True)
        for name in ("lazy", "mason", "treesitter"):
            (data / name).symlink_to(DATA / name, target_is_directory=True)
        preinit = root / "preinit.lua"
        preinit.write_text(
            'vim.opt.rtp:append(vim.fn.stdpath("data") .. "/lazy/mason.nvim")\n'
            'require("mason-registry").refresh = function(cb) if cb then cb(true, {}) end end\n'
            'package.loaded["supermaven-nvim"] = { setup = function() end }\n'
        )
        for case in ("project", "standalone", "new"):
            directory = root / case
            directory.mkdir()
            path = directory / "example.py"
            if case != "new":
                path.write_text(SOURCE)
            if case == "project":
                (directory / "pyproject.toml").write_text('[tool.pyright]\ntypeCheckingMode = "basic"\n')
            env = dict(os.environ, XDG_DATA_HOME=str(root / "data"),
                       XDG_STATE_HOME=str(root / "state"), XDG_CACHE_HOME=str(root / "cache"),
                       NVIM_LOG_FILE=str(root / "nvim.log"), PYTHON_STARTUP_NEW=str(int(case == "new")))
            env.pop("VIRTUAL_ENV", None)
            env.pop("CONDA_PREFIX", None)
            print(f"Checking {case} Python startup", flush=True)
            subprocess.run([
                "nvim", "--headless", "-i", "NONE", "--cmd", f"luafile {preinit}",
                "-u", str(CONFIG / "init.lua"), str(path),
                "-c", f"luafile {CONFIG / 'tests/python_startup.lua'}",
            ], cwd=directory, env=env, check=True, timeout=75)


if __name__ == "__main__":
    main()
