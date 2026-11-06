#!/usr/bin/env python3
"""Install the editor runtime inside Ubuntu devbox; run as root in the container.

Neovim config stays shared. A wrapper gives this container its own editor data,
cache, and state, avoiding host-built parsers and Python virtual environments.
"""
import gzip
import hashlib
import json
import os
from pathlib import Path
import platform
import re
import shutil
import subprocess
import tempfile
from urllib.request import Request, urlopen


ROOT = Path("/opt/devbox-editor")
NVIM_VERSION = "0.12.6"
TREESITTER_VERSION = "0.26.9"
WRAPPER = """#!/bin/sh
# Managed by dotfiles/system/distrobox/install-neovim.py
if [ "${DEVBOX_NVIM_ISOLATED:-}" != "1" ]; then
    export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/distrobox-editor/devbox"
    export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}/distrobox-editor/devbox"
    export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}/distrobox-editor/devbox"
    export DEVBOX_NVIM_ISOLATED=1
fi
export PATH="/opt/devbox-editor/node/bin:/opt/devbox-editor/bin:$PATH"
if [ -f "$HOME/.gitconfig" ]; then
    mkdir -p "$XDG_CACHE_HOME/nvim"
    sed 's/zdiff3/diff3/g' "$HOME/.gitconfig" > "$XDG_CACHE_HOME/nvim/gitconfig"
    export GIT_CONFIG_GLOBAL="$XDG_CACHE_HOME/nvim/gitconfig"
fi
exec /opt/devbox-editor/neovim/bin/nvim "$@"
"""


def fetch(url):
    request = Request(url, headers={"User-Agent": "dotfiles-devbox-editor"})
    with urlopen(request, timeout=120) as response:
        return response.read()


def download(url, expected, destination):
    print("Downloading " + url, flush=True)
    data = fetch(url)
    if hashlib.sha256(data).hexdigest() != expected:
        raise RuntimeError("SHA256 verification failed: " + url)
    destination.write_bytes(data)


def github_asset(repository, tag, name, destination):
    release = json.loads(fetch(f"https://api.github.com/repos/{repository}/releases/tags/{tag}"))
    asset = next(item for item in release["assets"] if item["name"] == name)
    digest = asset.get("digest", "")
    if not re.fullmatch(r"sha256:[0-9a-f]{64}", digest):
        raise RuntimeError("Release asset has no SHA256 digest: " + name)
    url = asset["browser_download_url"]
    if not url.startswith(f"https://github.com/{repository}/releases/download/"):
        raise RuntimeError("Unexpected release download URL")
    download(url, digest.split(":", 1)[1], destination)


def activate(name, destination):
    link = ROOT / name
    if link.exists() and not link.is_symlink():
        raise RuntimeError("Refusing to replace an unmanaged directory: " + str(link))
    temporary = ROOT / (name + ".new-" + str(os.getpid()))
    temporary.symlink_to(destination)
    temporary.replace(link)


def build_treesitter(staging):
    """Build against the container's libc when upstream binaries need a newer one."""
    native = ROOT / ("tree-sitter-native-" + TREESITTER_VERSION)
    if (native / "bin/tree-sitter").is_file():
        return native / "bin/tree-sitter"
    rustup = staging / "rustup-init"
    url = "https://static.rust-lang.org/rustup/dist/x86_64-unknown-linux-gnu/rustup-init"
    digest = fetch(url + ".sha256").decode().split()[0]
    download(url, digest, rustup)
    rustup.chmod(0o755)
    cargo_home, rustup_home = staging / "cargo", staging / "rustup"
    env = dict(os.environ, CARGO_HOME=str(cargo_home), RUSTUP_HOME=str(rustup_home),
               CARGO_TARGET_DIR=str(staging / "target"),
               PATH=str(cargo_home / "bin") + ":" + os.environ["PATH"])
    print("Installing a temporary Rust compiler for the native Tree-sitter build", flush=True)
    subprocess.run([str(rustup), "-y", "--profile", "minimal", "--default-toolchain", "stable", "--no-modify-path"],
                   env=env, check=True)
    log_path = ROOT / "tree-sitter-build.log"
    print("Building Tree-sitter CLI against Ubuntu's libc; log: " + str(log_path), flush=True)
    with log_path.open("w") as log:
        result = subprocess.run([
            str(cargo_home / "bin/cargo"), "install", "--locked", "tree-sitter-cli",
            "--version", TREESITTER_VERSION, "--jobs", "2", "--root", str(native),
        ], env=env, stdout=log, stderr=subprocess.STDOUT)
    if result.returncode:
        print("\n".join(log_path.read_text().splitlines()[-40:]), flush=True)
        result.check_returncode()
    return native / "bin/tree-sitter"


def main():
    if os.geteuid() != 0 or platform.machine() != "x86_64":
        raise RuntimeError("Run as root inside the x86_64 devbox container")
    if not Path("/run/.containerenv").exists() and not Path("/.dockerenv").exists():
        raise RuntimeError("This installer must run inside a container")
    wrapper = Path("/usr/local/bin/nvim")
    if wrapper.exists() and "Managed by dotfiles/system/distrobox/install-neovim.py" not in wrapper.read_text(errors="replace"):
        raise RuntimeError("Refusing to replace an existing /usr/local/bin/nvim")

    subprocess.run([
        "apt-get", "install", "-y", "--no-install-recommends", "git", "curl", "ca-certificates",
        "tar", "xz-utils", "gzip", "unzip", "build-essential", "pkg-config", "libssl-dev", "libclang-dev",
        "python3-pip", "python3-venv", "ripgrep",
    ], env=dict(os.environ, DEBIAN_FRONTEND="noninteractive"), check=True)
    ROOT.mkdir(parents=True, exist_ok=True)
    (ROOT / "bin").mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="devbox-editor-", dir="/var/tmp") as temporary:
        staging = Path(temporary)
        neovim = ROOT / ("neovim-" + NVIM_VERSION)
        if not neovim.exists():
            archive = staging / "neovim.tar.gz"
            github_asset("neovim/neovim", "v" + NVIM_VERSION, "nvim-linux-x86_64.tar.gz", archive)
            subprocess.run(["tar", "-xf", str(archive), "-C", str(staging)], check=True)
            unpacked = staging / "nvim-linux-x86_64"
            subprocess.run([str(unpacked / "bin/nvim"), "--version"], check=True)
            shutil.move(str(unpacked), str(neovim))
        activate("neovim", neovim)

        # Node's official Linux builds run on Ubuntu 22.04. Keep it private to the editor.
        sums = fetch("https://nodejs.org/dist/latest-v24.x/SHASUMS256.txt").decode()
        match = re.search(r"^([0-9a-f]{64})\s+(node-v24\.\d+\.\d+-linux-x64\.tar\.xz)$", sums, re.M)
        if not match:
            raise RuntimeError("Node 24 Linux checksum was not found")
        digest, filename = match.groups()
        node = ROOT / filename.removesuffix(".tar.xz")
        if not node.exists():
            archive = staging / filename
            download("https://nodejs.org/dist/latest-v24.x/" + filename, digest, archive)
            subprocess.run(["tar", "-xf", str(archive), "-C", str(staging)], check=True)
            unpacked = staging / filename.removesuffix(".tar.xz")
            subprocess.run([str(unpacked / "bin/node"), "--version"], check=True)
            shutil.move(str(unpacked), str(node))
        activate("node", node)

        treesitter = ROOT / "bin/tree-sitter"
        archive = staging / "tree-sitter.gz"
        github_asset("tree-sitter/tree-sitter", "v" + TREESITTER_VERSION, "tree-sitter-linux-x64.gz", archive)
        binary = staging / "tree-sitter"
        binary.write_bytes(gzip.decompress(archive.read_bytes()))
        binary.chmod(0o755)
        result = subprocess.run([str(binary), "--version"], capture_output=True, text=True)
        if result.returncode:
            print("Prebuilt Tree-sitter is incompatible with this container; compiling a native CLI.", flush=True)
            binary = build_treesitter(staging)
        subprocess.run([str(binary), "--version"], check=True)
        shutil.copy2(binary, treesitter)

    wrapper.write_text(WRAPPER)
    wrapper.chmod(0o755)
    print("Installed container-local Neovim, Node, and Tree-sitter CLI", flush=True)
    subprocess.run([str(wrapper), "--version"], check=True)
    print("Next: initialize plugins and Mason tools as the regular container user.", flush=True)


if __name__ == "__main__":
    main()
