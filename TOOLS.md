# System Tools Guide

A reference for every tool on this machine (Arch Linux + Hyprland, ASUS Zenbook): what each one is for and how to use it for common tasks.

**Scope:** all 169 explicitly installed official packages, 49 AUR packages, global npm / uv / pip / cargo / go tools, the custom scripts in this repo, keybindings, and the services that run in the background. Libraries pulled in automatically as dependencies are not listed.

**Finding help for anything:** `tldr <cmd>` (short examples), `man <cmd>` (full manual), `<cmd> --help`.

---

## Contents

1. [Keybindings & gestures](#1-keybindings--gestures)
2. [Custom scripts (this repo)](#2-custom-scripts-this-repo)
3. [Shell aliases & functions](#3-shell-aliases--functions)
4. [Desktop environment (Hyprland stack)](#4-desktop-environment-hyprland-stack)
5. [Terminal, shell & multiplexer](#5-terminal-shell--multiplexer)
6. [Files, search & disk](#6-files-search--disk)
7. [Editors & IDEs](#7-editors--ides)
8. [Programming languages & build tools](#8-programming-languages--build-tools)
9. [Git & GitHub](#9-git--github)
10. [Containers & virtual machines](#10-containers--virtual-machines)
11. [Networking & remote access](#11-networking--remote-access)
12. [Security, secrets & passwords](#12-security-secrets--passwords)
13. [Backups, snapshots & recovery](#13-backups-snapshots--recovery)
14. [Package management & system maintenance](#14-package-management--system-maintenance)
15. [Hardware, power & ASUS](#15-hardware-power--asus)
16. [Audio & Bluetooth](#16-audio--bluetooth)
17. [Media, screenshots & graphics](#17-media-screenshots--graphics)
18. [Apps: browsers, office, notes, communication](#18-apps-browsers-office-notes-communication)
19. [AI & developer CLIs](#19-ai--developer-clis)
20. [Robotics & hardware development](#20-robotics--hardware-development)
21. [Boot, kernel, drivers & base system](#21-boot-kernel-drivers--base-system)
22. [Themes, icons, cursors & fonts](#22-themes-icons-cursors--fonts)
23. [Background services & timers](#23-background-services--timers)
24. [Task cookbook](#24-task-cookbook)

---

## 1. Keybindings & gestures

`SUPER` is the Windows key. Defined in `.config/hypr/hyprland.lua`.

### Apps & launchers
| Keys | Action |
|---|---|
| `SUPER + Q` | Terminal (Ghostty) |
| `SUPER + B` | Browser (Brave) |
| `SUPER + E` | File manager (yazi in Ghostty) |
| `SUPER + O` | Obsidian |
| `SUPER + T` | Todoist |
| `SUPER + Space` | App launcher (rofi) |
| `SUPER + SHIFT + Space` | Run any command (rofi "combi"; runs in Ghostty) |
| `SUPER + /` | Calculator (rofi-calc) |
| `SUPER + M` | Power menu (lock / suspend / logout / reboot / shutdown) |
| `SUPER + L` | Lock screen now |
| `SUPER + TAB` | Workspace overview (quickshell) |
| `XF86Launch1` (ASUS key) | btop system monitor |

### Windows & workspaces
| Keys | Action |
|---|---|
| `SUPER + C` | Close window |
| `SUPER + F` | Fullscreen toggle |
| `SUPER + SHIFT + F` | Float toggle |
| `SUPER + J` | Toggle split direction |
| `SUPER + ←/→/↑/↓` | Move focus |
| `SUPER + 1…0` | Go to workspace 1–10 |
| `SUPER + SHIFT + 1…0` | Move window to workspace 1–10 |
| `SUPER + CTRL + S` | Scratchpad ("magic" special workspace) |
| `SUPER + scroll` | Next / previous workspace |
| `SUPER + left-drag` / `right-drag` | Move / resize window |
| `SUPER + P` | Presentation / display mode menu (mirror, extend, single screen) |

### Clipboard, text & capture
| Keys | Action |
|---|---|
| `SUPER + V` | Clipboard history (secrets are filtered out automatically) |
| `SUPER + SHIFT + C` | Copy the current text selection to the clipboard |
| `SUPER + .` | Emoji picker (bemoji) |
| `SUPER + SHIFT + S` | Screenshot a region (saved + copied) |
| `Print` | Screenshot the whole screen (saved + copied) |
| `SUPER + SHIFT + T` | OCR: select a region, get its text |
| `SUPER + SHIFT + R` | Voice typing: start/stop voxtype recording (voxtype daemon must be running; start it from Waybar) |

### Utilities
| Keys | Action |
|---|---|
| `SUPER + N` | Notification center (swaync) |
| `SUPER + S` | Search Google / ChatGPT / Claude / YouTube |
| `SUPER + I` | Private (incognito) Brave search |
| `SUPER + W` | Open/create an Obsidian note ("writ") |
| `SUPER + SHIFT + B` | Brave bookmarks launcher (type a URL to add one) |
| `SUPER + R` | New reminder ("remind me in 10 min to…") |
| `SUPER + CTRL + R` | Cancel reminders |
| `SUPER + U` | Tailscale menu (send files/clipboard to your devices) |
| `SUPER + SHIFT + I` | Stay-awake toggle (blocks idle/sleep; closing the lid then only locks and turns the screen off) |
| `SUPER + SHIFT + N` | Night light toggle |

### Hardware keys & touchpad
- Volume, mute, mic mute, brightness and media keys work (also on the lock screen).
- **3-finger swipe left/right:** switch workspace.
- **3-finger swipe down:** app launcher.
- **4-finger swipe up/down:** volume up/down.

---

## 2. Custom scripts (this repo)

### CLI commands (`scripts/.local/bin` → `~/.local/bin`)
| Command | What it does | Common use |
|---|---|---|
| `sysclean` | Interactive monthly maintenance: pacman cache, orphans, `.pacnew`, `~/.cache`, journal, failed units, CVEs (arch-audit) | `sysclean` · `sysclean -u` (also upgrade) · `sysclean -a` (everything incl. mirrors, npm/pip/uv) |
| `backup-home` | Encrypted restic backups of `$HOME` | `backup-home init` · `backup-home dry-run` · `backup-home run --force` · `backup-home status` · restore: `backup-home restic restore latest --target ~/restore --include ~/Documents` |
| `apikey` | API keys stored in gnome-keyring | `apikey set openroute` · `apikey list` · `apikey get <name>` · `apikey rm <name>` |
| `secure-perms` | Re-applies 600/700 permissions to secret files | Run after cloning or restowing |
| `storage-monitor` | Disk usage overview (btrfs-aware, snapshots, biggest folders) | `storage-monitor` |
| `gwt` | Git worktrees next to the repo (copies `.env`, opens Ghostty) | `gwt new feature-x` · `gwt add existing-branch` · `gwt ls` · `gwt rm feature-x` |
| `tailscale-menu` | Rofi menu for Tailscale (`SUPER+U`) | Send a file or the clipboard to a device; copy an offline device's IP |
| `presentation` | Monitor layout menu (`SUPER+P`) | Mirror / extend / laptop only / external only |
| `power-toggle` | Power profile menu (Waybar) | Quiet / Balanced / Performance via asusctl |
| `powermenu` | Lock / suspend / logout / reboot / shutdown (`SUPER+M`) | |
| `screenshot` | Region screenshot to `~/Pictures/Screenshots` + clipboard | `SUPER+SHIFT+S` |
| `search`, `psearch` | Web search launchers (`SUPER+S`, `SUPER+I`) | |
| `bookmark` | Brave bookmark launcher/adder (`SUPER+SHIFT+B`) | Close Brave before adding, or Brave may overwrite the new entry |
| `writ` | Obsidian note picker/creator (`SUPER+W`) | Notes live in `~/Documents/Notes` |
| `bemoji-rofi` | Emoji picker (`SUPER+.`) | |
| `gcalcli` | Google Calendar CLI wrapper | `gcalcli --config-folder ~/.config/gcalcli/gcalcli-personal agenda` |

### Helper scripts (`.config/scripts`, called by Hyprland/Waybar/systemd)
| Script | Purpose |
|---|---|
| `battery-warn.sh` | Warnings at 30% / 15% (dims + warms screen) / 10% |
| `cliphist-secure-store.sh` | Keeps passwords, tokens, keys and OTPs out of clipboard history |
| `gcal-widget.sh` / `gcal-notify.sh` | Calendar events in swaync; reminders 30 and 10 min before events |
| `swaync-weather.sh` | Weather (feels-like) for Home and University in swaync |
| `remind.sh`, `remind-prompt.sh`, `remind-cancel.sh`, `reminder-loop.sh` | Reminder system (`SUPER+R`). CLI: `~/.config/scripts/remind.sh 45m "take a break"` |
| `tailscale-status.sh`, `tailscale-receive.sh` | Waybar Tailscale icon; auto-accept incoming Taildrop files into `~/tailscale` |
| `toggle-idle.sh`, `toggle-nightlight.sh` | Stay-awake and night-light toggles |
| `lid.sh` | Lid-switch handler. Stay-awake **on**: closing the lid locks (hyprlock) and turns the laptop screen off, and everything keeps running. Stay-awake **off**: the laptop suspends, even with an external monitor connected (logind ignores the lid when docked, so the script suspends instead). Opening the lid turns the screen back on to the lock screen. Ignores libinput's fake "lid open" events by checking `/proc/acpi/button/lid`. Log: `$XDG_RUNTIME_DIR/lid.log` |
| `get-wallpaper.sh`, `set-wallpaper.sh` | Current Waypaper wallpaper; syncs it to the lock screen |
| `asus-sleep.sh` | Keyboard backlight / asusd handling around suspend |

### Root-level setup scripts (`system/`)
`apply-system-fixes.sh`, `apply-round2.sh`, `apply-round3.sh`, `apply-round4.sh` are idempotent scripts, safe to re-run. They set up the firewall, TRIM, oomd, sysctl hardening, DNS-over-TLS, MAC randomization, reflector, etc. Run each with `sudo bash system/<script>`.

---

## 3. Shell aliases & functions

Defined in `zsh/.zshrc`.

| Alias / function | Does |
|---|---|
| `cd` → `z` (zoxide) | Jump to frequently used folders by partial name: `cd dots` → `~/dotfiles` |
| `y` | Open yazi; when you quit, the shell `cd`s to where you were |
| `cat` → `bat` | Syntax-highlighted file viewer (`command cat` for the original) |
| `ls` / `ll` | eza with icons / long list with git status |
| `g`, `gs`, `ga`, `gc`, `gco`, `gl` | git, status, add, commit, checkout, pretty log graph |
| `nv` | nvim |
| `inv` | Fuzzy-pick files (with preview) and open them in nvim |
| `python` | python3 |
| `openclaude` | OpenClaude via OpenRouter (key fetched from keyring on demand) |
| `oc-open`, `oc-open2` | Switch openclaude to OpenRouter key 1 / key 2 (the OpenRouter settings go to openclaude only, not to other programs) |
| `entc`, `jetson` | Mount the entc server (`/home/ravindu`) or the Jetson (`/home/jetson`) at `~/mnt/<host>` over sshfs if not already mounted, then open yazi there. `idmap=user` makes git work inside the mount. Unmount: `entc-umount`, `jetson-umount` |
| `sshmount <host> <dir>` | The helper behind `entc`/`jetson`; works with any host in `~/.ssh/config` |
| `ai-main` | Google's gemini CLI |
| `gz` | Gazebo forced onto XWayland (needed for rendering) |
| `cubeide` | STM32CubeIDE inside the `devbox` distrobox |
| `Ctrl+R` | atuin history search |
| `Ctrl+T` / `Alt+C` | fzf: insert file path / cd into folder |
| `Tab` | fzf-tab completion menu (fuzzy) |

A new Ghostty window auto-attaches to the tmux session `main` (IDE terminals such as VS Code or Neovide do not).

---

## 4. Desktop environment (Hyprland stack)

| Tool | Use case | How to use |
|---|---|---|
| **hyprland** | Tiling Wayland compositor: the desktop itself | Config `~/.config/hypr/hyprland.lua`; reload `hyprctl reload`; check errors `hyprctl configerrors`; inspect `hyprctl clients`, `hyprctl monitors` |
| **hyprlock** | Lock screen | `SUPER+L`, or `hyprlock` |
| **hypridle** | Idle actions: keyboard light off at 2 min, lock at 2.5 min, screen off at 5 min, suspend at 20 min | `~/.config/hypr/hypridle.conf` |
| **hyprsunset** | Night light / blue-light filter | `SUPER+SHIFT+N`; `hyprctl hyprsunset temperature 4000`; `hyprctl hyprsunset identity` |
| **hyprpolkitagent** | Password prompt when an app needs admin rights | Automatic |
| **xdg-desktop-portal-hyprland** | Screen sharing, screenshots and file pickers for apps (Brave, OBS, Zoom) | Automatic |
| **xdg-desktop-portal-termfilechooser** (AUR) | Terminal (yazi) file picker for "Open file" dialogs | Automatic |
| **hyprmod** (AUR) | GTK settings app for Hyprland (writes `hyprland-gui.lua`) | Launch "HyprMod" from rofi |
| **hyprmoncfg** (AUR) | Monitor profiles + auto-switching daemon | `hyprmoncfg` (TUI); profiles in `~/.config/hyprmoncfg/profiles` |
| **python-hyprland-{config,monitors,schema,socket,state}** (AUR) | Python libraries used by hyprmod | Nothing to run |
| **waybar** | Top bar (workspaces, clock, network, battery, Tailscale, voxtype…) | Config `~/.config/waybar/config`; restart `pkill waybar; waybar &` |
| **swaync** | Notifications + control center with calendar and weather | `SUPER+N`; `swaync-client -d` (Do Not Disturb toggle); `swaync-client -C` (clear all) |
| **rofi** + **rofi-calc** + **rofi-power-menu** (AUR) | Launcher, menus, calculator | `SUPER+Space`, `SUPER+/`; themes in `~/.config/rofi` |
| **quickshell-overview-git** (AUR) | Workspace overview with live previews | `SUPER+TAB` |
| **awww** | Wallpaper daemon | `awww img ~/Pictures/Wallpapers/x.jpg --transition-type grow` |
| **waypaper** (AUR) | GUI wallpaper picker (uses awww) | `waypaper` |
| **cliphist** + **wl-clipboard** + **wl-clip-persist** | Clipboard history; `wl-copy`/`wl-paste` in scripts; keeps the clipboard after the source app closes | `SUPER+V`; `echo hi \| wl-copy`; `wl-paste > file.txt`; wipe history `cliphist wipe` |
| **wlopm** | Turn screens on/off | `wlopm --off '*'` / `wlopm --on '*'` |
| **wev** | Show key/mouse event names (for writing binds) | `wev` then press keys |
| **wtype** | Type text into the focused window | `wtype "hello"` |
| **ydotool** | Low-level input automation via `/dev/uinput` | `ydotool type "text"` (needs `ydotoold` running) |
| **sddm** + **sddm-sugar-candy-git** (AUR) | Login screen (currently autologin) and its theme | `/etc/sddm.conf.d/` |
| **nwg-look** | GTK theme/font/cursor settings for Wayland | `nwg-look` |
| **qt5-wayland**, **qt6-wayland** | Let Qt apps run natively on Wayland | Nothing to run |
| **xorg-server** | XWayland support for X11-only apps (Gazebo, Wine…) | Nothing to run |
| **xdg-utils** | Open files/URLs with the default app | `xdg-open file.pdf`; defaults in `~/.config/mimeapps.list` |
| **gnome-keyring** + **seahorse** | Secret storage (Wi-Fi, app passwords, API keys); Seahorse is the GUI | `seahorse`; CLI `secret-tool` / `apikey` |
| **network-manager-applet** | Wi-Fi tray icon (`nm-applet`) | Click the tray icon; editor `nm-connection-editor` |
| **blueman** | Bluetooth tray icon + manager | `blueman-manager` |

---

## 5. Terminal, shell & multiplexer

| Tool | Use case | How to use |
|---|---|---|
| **ghostty** | Terminal emulator | `SUPER+Q`; splits: `Ctrl+A` then `\` (right) / `-` (down), `Ctrl+A h/j/k/l` move, `Ctrl+A z` zoom, `Ctrl+A c` new tab, `Ctrl+A r` reload config |
| **zsh** + **oh-my-zsh-git** + **zsh-theme-powerlevel10k-git** (AUR) | Shell, plugin framework, prompt theme | Loaded from `/usr/share`, so `yay` updates them. Plugins: git, autosuggestions (→ accepts a suggestion), syntax highlighting, fzf-tab; the last three are git clones in `~/.local/share/oh-my-zsh-custom/plugins` (update with `git -C <dir> pull`). Reconfigure the prompt: `p10k configure` |
| **tmux** | Sessions that survive closing the terminal; panes & windows | Prefix `Ctrl+Space`. `\|` / `-` split, `c` new window, `d` detach, `g` lazygit window, `r` reload, `[` copy mode (`v` select, `y` copy). Sessions auto-save every 5 min and auto-restore (resurrect + continuum). `tmux ls`, `tmux attach -t main` |
| **tmuxifier** (`~/.tmuxifier`) | Saved tmux layouts (windows, panes and commands per project) | `tmuxifier new-session name` to write a layout, `tmuxifier load-session name` to open it. No layouts saved yet |
| **atuin** | Searchable shell history in a SQLite database (local only, no sync) | `Ctrl+R` opens it under the prompt. Type to fuzzy-search, `Ctrl+R` again switches between global, host, session and folder filters, `Enter` puts the command on the prompt to edit, `Tab` too. The Up arrow is still normal zsh history. `atuin stats` shows your top commands. Commands starting with a space, or that set `token=`/`password=` inline, are not recorded. Config: `.config/atuin/config.toml` |
| **fzf** | Fuzzy finder for anything | `Ctrl+R` history, `Ctrl+T` files, `Alt+C` cd; `vim $(fzf)` |
| **zoxide** | Smarter `cd` | `z proj`, `zi` (interactive) |
| **bat** | `cat` with highlighting | `bat file.py`, `bat -A file` (show hidden chars) |
| **eza** | Modern `ls` | `ls`, `ll`, `eza --tree -L 2` |
| **tldr** | Short examples for commands | `tldr tar` |
| **man-db** | Manuals | `man rsync`; search `man -k keyword` |
| **tree** | Directory tree | `tree -L 2 -a` |
| **fastfetch** | System info banner | `fastfetch` |
| **inxi** | Detailed hardware/system report | `inxi -Fxz` (the `z` hides serials; good for forum posts) |
| **asciinema** | Record terminal sessions as text | `asciinema rec demo.cast`; play `asciinema play demo.cast` |
| **entr** | Re-run a command when files change | `ls *.py \| entr -r python main.py` |
| **w3m** | Text web browser / HTML pager | `w3m https://archlinux.org` |
| **nano** | Simple editor (fallback) | `nano file` (`Ctrl+O` save, `Ctrl+X` quit) |

---

## 6. Files, search & disk

| Tool | Use case | How to use |
|---|---|---|
| **yazi** | Terminal file manager with previews | `y` or `SUPER+E`. Keys: `h/j/k/l` move, `Enter` open, `Space` select, `y/x/p` copy/cut/paste, `d` trash, `a` new file (end with `/` for a folder), `r` rename, `/` search, `z` fzf jump. HTML and other web files open in Brave (`o` still offers nvim). Plugins: bunny (quick jumps: `b` then a key, e.g. `b d` → dotfiles), bookmarks, mount |
| **thunar** | GUI file manager | `thunar`; right-click "Open terminal here" |
| **fd** | Fast `find` | `fd pdf ~/Documents`; `fd -e py`; `fd -H .env` (include hidden) |
| **fzf** | Fuzzy find | See §5 |
| **dust** | Visual `du` (what's using space) | `dust ~`, `dust -d 2 /` |
| **duf** | Pretty `df` (free space per disk) | `duf` |
| **gdu** | Interactive disk usage browser | `gdu ~` (`d` delete, `q` quit) |
| **qdirstat** (AUR) | GUI disk usage treemap | `qdirstat ~` |
| **rsync** | Copy/sync folders efficiently, also over SSH | `rsync -avh --progress src/ dest/`; mirror (deletes extras) `rsync -avh --delete src/ dest/`; remote `rsync -avz dir/ host:~/dir/` |
| **7zip**, **zip**, **unzip**, **unp** | Archives | `7z x file.7z`; `7z a out.7z folder/`; `zip -r out.zip dir/`; `unzip file.zip -d dir`; `unp anything.tar.xz` (auto-detects the format) |
| **ntfsprogs** | NTFS (Windows disk) tools | `sudo ntfsfix /dev/sdX1` (fix "dirty" NTFS) |
| **inotify-tools** | React to file changes in scripts | `inotifywait -m -e close_write dir/` |
| **debtap** (AUR) | Convert `.deb` packages to Arch packages (last resort) | `sudo debtap -u` once, then `debtap pkg.deb` |
| **appimagelauncher** (AUR) | Integrates AppImages into the menu | Double-click an `.AppImage`; your AppImages live in `~/Applications` |
| **localsend-bin** (AUR) | AirDrop-style file sharing on the same Wi-Fi (phone ↔ laptop) | Open LocalSend on both devices (firewall port 53317 is open) |

---

## 7. Editors & IDEs

| Tool | Use case | How to use |
|---|---|---|
| **neovim** | Main terminal editor (Lua config, lazy.nvim) | `nv file`; config `~/.config/nvim`; plugins `:Lazy` (update: `:Lazy update`); LSP servers `:Mason`; health `:checkhealth` |
| **neovide** | GUI front-end for neovim (smooth animations) | `neovide file` |
| **tree-sitter-cli** | Builds syntax parsers for nvim | Used automatically by nvim-treesitter |
| **zed** | Fast GUI editor with collaboration | `zeditor .` |
| **visual-studio-code-bin** (AUR) | VS Code | `code .` |
| **antigravity-ide** (AUR) | Google's agent-first IDE | Launch from rofi |
| **blueprint-compiler** | GTK4 UI markup compiler (GTK app development) | `blueprint-compiler compile ui.blp` |
| **syntax-highlighting** | KDE highlighting library (used by other apps) | Nothing to run |

---

## 8. Programming languages & build tools

| Tool | Use case | How to use |
|---|---|---|
| **base-devel** | Compilers + make + makepkg; needed for AUR builds | Nothing to run |
| **clang** | C/C++ compiler + clangd (LSP) + clang-format | `clang++ -O2 main.cpp -o app`; format `clang-format -i file.cpp` |
| **cmake** | C/C++ build system | `cmake -B build && cmake --build build -j` |
| **go** | Go toolchain | `go run .`, `go build`, `go mod tidy`; `gopls` in `~/go/bin` is the language server |
| **rust** | Rust toolchain (cargo) | `cargo new app`, `cargo run`, `cargo build --release`; `~/.cargo/bin` has `flutter_rust_bridge_codegen` |
| **nodejs** + **npm** | JavaScript runtime + packages | `npm install`, `npm run dev`; global tools in `~/.npm-global` (see §19); update globals `npm update -g` or `sysclean -n` |
| **nvm** | Multiple Node versions (you have v24 besides the system v26) | `nvm ls`, `nvm use 24`, `nvm install --lts`; check which one is active: `which node` |
| **python** (+ **python-pip**, **python-pipx**, **python-build**, **python-installer**, **python-dbus**) | Python, installers, build frontend, D-Bus bindings | Project venv: `python -m venv .venv && source .venv/bin/activate`; isolated CLI apps: `pipx install <tool>` |
| **uv** (`~/.local/bin/uv`, `uvx`) | Very fast Python package/venv manager | `uv venv`, `uv pip install -r requirements.txt`, `uv run script.py`, `uvx ruff check .`; tools: `uv tool install x` |
| pip `--user` tools in `~/.local/bin` | jupyter, ipython, flask, dash, plotly, open3d, tqdm, rsa, pybabel… (from ML work) | `jupyter lab`, `ipython`, `flask run`, `open3d` |
| **lua51** + **luarocks** | Lua (nvim plugins, Hyprland Lua config tooling) | `luarocks install --local <rock>` |
| **jdk17-openjdk**, **jdk21-openjdk** | Java 17 (default) and 21 | `archlinux-java status`; switch `sudo archlinux-java set java-21-openjdk` |
| **maven** | Java builds | `mvn package`, `mvn spring-boot:run` |
| **dotnet-sdk** | .NET / C# | `dotnet new console`, `dotnet run` |
| **freeimage** (AUR) | Image library for some apps | Nothing to run |
| **python-dlib-git**, **python-imageio-ffmpeg**, **python-screeninfo** (AUR) | Face/ML library, ffmpeg for Python, screen info (dependencies of ocr4linux/other tools) | Nothing to run |
| **couchdb** | Document database, running on `localhost:5984` (e.g. Obsidian LiveSync) | Web UI http://127.0.0.1:5984/_utils; `systemctl status couchdb` |
| **neon** (npm) | Neon (serverless Postgres) CLI | `neon auth`, `neon projects list`, `neon connection-string` |

---

## 9. Git & GitHub

| Tool | Use case | How to use |
|---|---|---|
| **git** | Version control | Aliases `g`/`gs`/`ga`/`gc`/`gco`/`gl`; config `git/.gitconfig` (zdiff3 conflicts, fsckObjects, auto-setup remote on push) |
| **git-delta** | Pretty side-by-side diffs (git pager) | Automatic for `git diff`/`log -p`/`show`; `n`/`N` jump between files |
| **lazygit** | Terminal UI for git | `lazygit` or tmux prefix + `g`. `space` stage, `c` commit, `P` push, `p` pull, `b` branches, `?` help |
| **github-cli** (`gh`) | GitHub from the terminal | `gh repo clone x/y`, `gh pr create`, `gh pr checkout 12` (alias `gh co`), `gh issue list`, `gh run watch` |
| **gitleaks** | Finds secrets in git repos; also runs automatically in the dotfiles pre-commit hook | `gitleaks git -v` (whole history); `gitleaks dir .` (plain folder) |
| **gwt** (script) | Worktree per branch | See §2 |

---

## 10. Containers & virtual machines

| Tool | Use case | How to use |
|---|---|---|
| **podman** | Rootless containers (your real engine). The `docker` command talks to it through `DOCKER_HOST` | `podman ps -a`, `podman images`, `podman run -it --rm alpine sh`, `podman logs -f <name>`, `podman system prune` |
| **docker** + **docker-compose** | CLIs only (the Docker engine is disabled); they drive Podman | `docker ps`, `docker compose up -d`, `docker compose logs -f`; e.g. your `portfolio-postgres-1` |
| **lazydocker** | Terminal UI for containers (works with Podman via `DOCKER_HOST`) | `lazydocker` |
| **distrobox** | Other distros' userlands with your home folder shared (e.g. `devbox` for STM32CubeIDE) | `distrobox list`, `distrobox enter devbox`, `distrobox create -n ubuntu -i ubuntu:24.04` |
| **fuse-overlayfs** | Storage driver for rootless Podman | Nothing to run |
| **vm-curator** (AUR) | TUI to manage QEMU/KVM virtual machines | `vm-curator` |
| **wine** | Run Windows programs | `wine setup.exe`; config `winecfg`; prefix in `~/.wine` |

---

## 11. Networking & remote access

| Tool | Use case | How to use |
|---|---|---|
| **NetworkManager** (via `nm-applet`) | Wi-Fi/Ethernet. Random MAC per network is enabled | `nmcli dev wifi list`, `nmcli dev wifi connect "SSID" password "..."`, `nmtui` |
| **systemd-resolved** | DNS: Quad9 over TLS, Tailscale MagicDNS for `*.ts.net` | `resolvectl status`, `resolvectl query example.com`, flush cache `resolvectl flush-caches` |
| **nftables** | Firewall (default-deny inbound) | `sudo nft list table inet host_firewall`; open a port: edit `system/nftables/nftables.conf`, reinstall, then `sudo systemctl restart nftables` |
| **tailscale** | Private mesh VPN between your devices | `tailscale status`, `tailscale ip`, `tailscale ping elgin`, send a file `tailscale file cp f.pdf phone:` (or `SUPER+U`); SSH over the tailnet: `ssh user@elgin` |
| **openssh** | SSH client (no server running) | `ssh entc`, `ssh p1` (aliases in `~/.ssh/config`); copy files `scp`/`rsync`; keys `ssh-keygen -t ed25519` |
| **aws-cli** + **aws-session-manager-plugin** (AUR) | AWS from the terminal; SSM tunnels used by the `p*`/`dax*` SSH hosts | `aws sso login` / `aws configure`, `aws s3 ls`, `aws ssm start-session --target i-...` |
| **rustdesk** (AUR) | Remote desktop (the unattended service is disabled) | Open the app when you need it; share the ID + one-time password |
| **sshfs** | Mount a remote folder over SSH | `entc` / `jetson` (see §3), or `sshfs host:/dir ~/mnt/x -o idmap=user`; unmount `fusermount3 -u ~/mnt/x` |
| **wget** | Download files | `wget -c URL` (`-c` resumes) |
| **rclone** | Sync to cloud storage (Drive, B2, S3, OneDrive…) | `rclone config`, `rclone ls remote:`, `rclone copy dir remote:dir -P` |
| **parabolic** (AUR) | GUI video/audio downloader (yt-dlp) | From rofi ("Parabolic"); binary `org.nickvision.tubeconverter` |

---

## 12. Security, secrets & passwords

| Tool | Use case | How to use |
|---|---|---|
| **bitwarden** (+ `bw` CLI via npm) | Password manager | Desktop app; add the browser extension in Brave/Firefox. CLI: `bw login`, `bw unlock`, `bw get password github` |
| **gnome-keyring** / **seahorse** / `apikey` | Secret storage (API keys, Wi-Fi, app secrets) | `apikey set/get/list/rm`; GUI `seahorse` |
| **sbctl** | Secure Boot keys & signing (Secure Boot is enabled) | `sudo sbctl status`, `sudo sbctl verify` (all boot files signed?); pacman hooks re-sign kernels automatically |
| **arch-audit** | Known CVEs in installed packages | `arch-audit -u` (only ones with a fix available); also part of `sysclean` |
| **lynis** | Full security audit with hardening suggestions | `sudo lynis audit system`; report in `/var/log/lynis-report.dat` |
| **gitleaks** | Secret scanning | See §9 |
| **shellcheck** | Finds bugs in shell scripts | `shellcheck script.sh` |
| **sudo** | Run as root | `sudo cmd`; `sudo -k` forgets cached credentials |
| **nftables**, **sysctl hardening**, **LUKS**, **hyprlock** | Firewall, kernel hardening, disk encryption, screen lock | See §11, §21, `AUDIT.md` |

---

## 13. Backups, snapshots & recovery

| Tool | Use case | How to use |
|---|---|---|
| **snapper** + **snap-pac** | Automatic btrfs snapshots: hourly timeline + before/after every pacman transaction | `snapper -c root list`, `snapper -c home list`; compare `snapper -c root status 10..11`; undo files `snapper -c root undochange 10..11 /etc/file` |
| **btrfs-assistant** | GUI for snapshots/subvolumes (browse, restore, delete) | `btrfs-assistant` (asks for your password) |
| **grub-btrfs** | Boot directly into a snapshot from the GRUB menu | GRUB → "Arch Linux snapshots" |
| **btrfs-progs** | btrfs admin | `sudo btrfs filesystem usage /`, `sudo btrfs scrub start /` (integrity check), `sudo btrfs subvolume list /` |
| **restic** + **rclone** + `backup-home` | Off-machine encrypted backups (destination still to be chosen) | See §2 and §24 |
| **rsync** | Manual copies to a USB drive | `rsync -avh --progress ~/Documents /run/media/$USER/USB/` |
| **smartmontools** | SSD health | `sudo smartctl -a /dev/nvme0n1` (watch "Percentage Used", "Media and Data Integrity Errors") |

---

## 14. Package management & system maintenance

| Tool | Use case | How to use |
|---|---|---|
| **pacman** | Official packages | Update `sudo pacman -Syu`; install `sudo pacman -S pkg`; remove `sudo pacman -Rns pkg`; search `pacman -Ss word`; which package owns a file `pacman -Qo /usr/bin/x`; info `pacman -Qi pkg` |
| **yay** (AUR) | AUR helper (+ everything pacman does) | Update all `yay`; install `yay -S pkg`; AUR updates only `yay -Qua`; clean `yay -Yc` |
| **pacman-contrib** | `paccache`, `pacdiff`, `checkupdates` | `checkupdates` (safe check); `sudo pacdiff` (merge `.pacnew`); paccache runs weekly automatically |
| **reflector** | Picks the fastest up-to-date mirrors (weekly timer) | Run now: `sudo systemctl start reflector`; config `/etc/xdg/reflector/reflector.conf` |
| **kernel-modules-hook** | Keeps the running kernel's modules after an upgrade (no broken USB/firewall until reboot) | Automatic; reboot after kernel updates |
| **fwupd** | Firmware updates (BIOS, SSD, webcam) | `fwupdmgr refresh && fwupdmgr get-updates`; `fwupdmgr update` |
| **stow** | Symlinks this dotfiles repo into `$HOME` | `cd ~/dotfiles && stow zsh` (one package) / `stow -R .` (restow) |
| `sysclean` | All-in-one maintenance | See §2 |
| **pkglist.hook** | Keeps `pkglist.txt` / `aurlist.txt` in the repo in sync | Automatic after every pacman transaction |
| **zram-generator** | Compressed swap in RAM (15 GB) | `swapon --show`, `zramctl` |
| **systemd-oomd** | Kills the worst memory hog instead of freezing | `oomctl` |

---

## 15. Hardware, power & ASUS

| Tool | Use case | How to use |
|---|---|---|
| **asusctl** | ASUS controls: fan/power profiles, charge limit, keyboard backlight | `asusctl profile next` / `asusctl profile set Quiet` / `asusctl profile get`; charge limit `asusctl battery limit 80` (`asusctl battery info`); keyboard light `asusctl leds set low` (`off/low/med/high`) |
| **power-profiles-daemon** | Power profiles over D-Bus (used by asusctl/Waybar) | `powerprofilesctl`, `powerprofilesctl set power-saver` |
| **acpid** | ACPI events (lid, power button) | Background service |
| **brightnessctl** | Screen and keyboard brightness | `brightnessctl set 50%`; keyboard `brightnessctl -d asus::kbd_backlight set 2` |
| **camera-toggle** (service) | ASUS camera key: turns the webcam on/off at driver level | Press the camera key; the LED shows the state |
| **piper** | Gaming mouse configuration (DPI, buttons, LEDs) | `piper` |
| **libinput-tools** | Touchpad/mouse debugging | `sudo libinput debug-events`, `libinput list-devices` |
| **evtest** | Raw input device events | `sudo evtest` |
| **usbutils** / **lshw** | List USB devices / full hardware | `lsusb`, `sudo lshw -short` |
| **efibootmgr** | UEFI boot entries | `efibootmgr -v` |
| **smartmontools** | Disk health | See §13 |
| **droidcam** + **v4l2loopback-dc-dkms** (AUR) | Use your phone as a webcam | Start DroidCam on the phone, then `droidcam` (GUI) or `droidcam-cli <phone-ip> 4747` on the laptop |

---

## 16. Audio & Bluetooth

| Tool | Use case | How to use |
|---|---|---|
| **pipewire** + **wireplumber** (+ **pipewire-pulse/-alsa/-jack**, **gst-plugin-pipewire**, **libpulse**) | The whole audio/video stack (replaces PulseAudio/JACK) | `wpctl status` (devices), `wpctl set-default <id>`, `wpctl set-volume @DEFAULT_AUDIO_SINK@ 50%`; restart `systemctl --user restart pipewire wireplumber` |
| **pavucontrol** | GUI mixer: per-app volume, choose input/output devices | `pavucontrol` |
| **pamixer** | CLI volume | `pamixer -i 5`, `pamixer --toggle-mute` |
| **sof-firmware** | Laptop sound card firmware | Nothing to run |
| **bluez** + **bluez-utils** + **blueman** | Bluetooth | GUI `blueman-manager`; CLI `bluetoothctl` → `power on`, `scan on`, `pair XX:..`, `connect XX:..` |
| **voxtype-bin** (AUR) | Local push-to-talk speech-to-text (Whisper) | Start the daemon from Waybar, then `SUPER+SHIFT+R` to record/stop; text is typed and copied to the clipboard |
| **spotify** (AUR) | Music | `spotify`; media keys work |

---

## 17. Media, screenshots & graphics

| Tool | Use case | How to use |
|---|---|---|
| **mpv** (+ uosc UI) | Video/audio player | `mpv file.mkv`; `space` pause, `←/→` seek, `f` fullscreen, `j` subtitles; resumes where you left off |
| **swayimg** | Image viewer | `swayimg pic.jpg` (arrows = next/previous) |
| **grim** + **slurp** + **grimblast-git** (AUR) | Screenshots | `SUPER+SHIFT+S` / `Print`; `grimblast copy area`; `grim -g "$(slurp)" out.png` |
| **ocr4linux-git** (AUR) | Copy text out of any part of the screen | `SUPER+SHIFT+T` |
| **obs-studio** | Screen recording / streaming | `obs`; add source "Screen Capture (PipeWire)" |
| **imagemagick** | Image conversion/editing from the CLI | `magick in.png out.jpg`; resize `magick in.jpg -resize 50% out.jpg`; PDF → images `magick -density 150 doc.pdf page-%02d.png` |
| **masterpdfeditor-free** (AUR) | Edit PDFs (text, pages, forms, signing) | `masterpdfeditor4` / from rofi |
| **intel-media-driver**, **libva-intel-driver**, **vulkan-intel** | GPU video decoding + Vulkan (mpv, Brave, OBS use them) | Check `vainfo` (libva-utils) |
| **plymouth** + **plymouth-theme-archlinux** (AUR) | Boot splash | Nothing to run |

---

## 18. Apps: browsers, office, notes, communication

| Tool | Use case | How to use |
|---|---|---|
| **brave-bin** (AUR) | Main browser (default for links/PDFs) | `SUPER+B`; install sites as apps: menu → "Install page as app" |
| **firefox** | Second browser | `firefox` |
| **obsidian** | Markdown notes vault `~/Documents/Notes` | `SUPER+O`; quick note `SUPER+W` |
| **onlyoffice-bin** (AUR) | Word / Excel / PowerPoint compatible office suite | `onlyoffice-desktopeditors file.docx` (or `desktopeditors`) |
| **p3x-onenote** (AUR) | OneNote (web wrapper) | From rofi |
| **todoist-appimage** (AUR) | Tasks | `SUPER+T` |
| **gcalcli** (script wrapper) | Google Calendar in the terminal | `gcalcli --config-folder ~/.config/gcalcli/gcalcli-personal agenda`, `... quick "Meeting tomorrow 3pm"` |
| **localsend-bin**, **tailscale** | File sharing with phone/devices | See §6, §11 |

---

## 19. AI & developer CLIs

| Tool | Use case | How to use |
|---|---|---|
| **claude** (`~/.local/bin/claude`) | Claude Code (this assistant) | `claude` in a project folder |
| **openclaude** (npm `@gitlawb/openclaude`) | Claude-Code-style agent via OpenRouter | `openclaude` (key from keyring); switch key `oc-open2` |
| **gemini-cli** (npm `@google/gemini-cli`) | Google's AI CLI | `ai-main` or `gemini` |
| **fabric-ai** (AUR) | Prompt "patterns" for summarizing, extracting, etc. | `fabric-ai --setup`; `cat article.txt \| fabric-ai -p summarize` |
| **graphify** (uv tool) | Builds a knowledge graph from a codebase/docs (also an MCP server) | `graphify <folder>`; in Claude Code: `/graphify` |
| **@bitwarden/cli** (npm) | Bitwarden from the terminal | See §12 |
| **neovim** (npm) | Node provider for nvim plugins | Nothing to run |

---

## 20. Robotics & hardware development

| Tool | Use case | How to use |
|---|---|---|
| **ROS 2 Jazzy** (`/opt/ros/jazzy`, sourced in `.zshrc`) | Robotics middleware | `ros2 topic list`, `ros2 run pkg node`, `colcon build` |
| **Gazebo** (`gz` alias) | Robot simulation | `gz sim world.sdf` |
| **foxglove-bin** (AUR) | Visualize ROS topics, logs and bags | `foxglove-studio`; connect to a rosbridge / open `.mcap` files |
| **arduino-ide-bin** (AUR) | Arduino programming | `arduino-ide` |
| **STM32CubeIDE** (in the `devbox` distrobox) | STM32 microcontrollers | `cubeide` |
| **Isaac Sim WebRTC client** (AppImage in `~/Applications`) | Stream NVIDIA Isaac Sim from a remote GPU machine | Run the AppImage; connect to the sim host |

---

## 21. Boot, kernel, drivers & base system

| Tool | Use case | How to use |
|---|---|---|
| **base** | Minimal Arch system | Nothing to run |
| **linux** + **linux-headers** + **linux-firmware** | Kernel, headers for DKMS modules (v4l2loopback), device firmware | Reboot after kernel updates; version `uname -r` |
| **intel-ucode** | CPU microcode security fixes | Loaded at boot automatically |
| **grub** | Bootloader (with snapshot entries) | Regenerate after config changes: `sudo grub-mkconfig -o /boot/grub/grub.cfg` |
| **sbctl** | Secure Boot | See §12 |
| **efibootmgr** | UEFI entries | See §15 |
| LUKS (`cryptsetup`) | Full-disk encryption (TRIM allowed) | Status `sudo cryptsetup status cryptroot`; **back up the header**: `sudo cryptsetup luksHeaderBackup /dev/nvme0n1p3 --header-backup-file luks-header.img` and keep it off-laptop |
| **mkinitcpio** | Builds the initramfs (hooks include `encrypt`, `plymouth`) | `sudo mkinitcpio -P`; **don't** adopt `mkinitcpio.conf.pacnew` blindly |
| **sudo**, **zsh**, **openssh**, **man-db** | Core tools | See the relevant sections |

---

## 22. Themes, icons, cursors & fonts

| Package | Role |
|---|---|
| **adw-gtk-theme**, **gruvbox-material-gtk-theme-git** (AUR) | GTK themes (apply with `nwg-look`) |
| **papirus-icon-theme** + **papirus-folders** (AUR), **breeze-icons** | Icon themes; recolor folders: `papirus-folders -C yellow` |
| **bibata-cursor-theme**, **breezex-cursor-theme** (AUR) | Cursors (Bibata-Modern-Classic 24 active) |
| **ttf-cascadia-mono-nerd**, **ttf-jetbrains-mono-nerd** | Terminal/editor fonts with icons |
| **noto-fonts-cjk**, **noto-fonts-emoji**, **ttf-dejavu** | Asian scripts, color emoji, fallback font |
| **plymouth-theme-archlinux**, **sddm-sugar-candy-git** (AUR) | Boot splash, login theme |

List installed fonts: `fc-list : family | sort -u`.

---

## 23. Background services & timers

### System
| Unit | Purpose |
|---|---|
| `NetworkManager`, `wpa_supplicant`, `systemd-resolved` | Networking, Wi-Fi auth, DNS (DoT) |
| `tailscaled` | Tailscale VPN |
| `nftables` | Firewall (loads rules at boot, then shows "inactive"; that's normal) |
| `bluetooth` | Bluetooth |
| `sddm` | Login manager |
| `acpid` | ACPI events |
| `camera-toggle` | ASUS camera key |
| `couchdb` | Local database on 127.0.0.1:5984 |
| `systemd-oomd` | Out-of-memory protection |
| `systemd-timesyncd` | Clock sync |
| `linux-modules-cleanup` | Removes old kernels' modules after reboot |
| Timers: `snapper-timeline`, `snapper-cleanup`, `fstrim`, `paccache`, `reflector` | Hourly snapshots + cleanup, weekly SSD TRIM, cache trim, mirror refresh |

### User
| Unit | Purpose |
|---|---|
| `pipewire`, `pipewire-pulse`, `wireplumber` | Audio |
| `gnome-keyring-daemon`, `p11-kit-server` | Secrets |
| `hyprpolkitagent` | Admin password prompts |
| `podman.socket` | Podman API (used by `docker`, lazydocker) |
| `tailscale-receive` | Auto-accept Taildrop files |
| `appimagelauncherd` | AppImage integration |
| `waybar`, `voxtype` | Enabled, but they don't auto-start via systemd (Waybar starts from Hyprland; voxtype from its Waybar button) |
| Timers: `gcal-widget` (every minute), `swaync-weather` (30 min), `backup-home` (once enabled) | Calendar, weather, backups |

Inspect anything: `systemctl status <unit>` / `systemctl --user status <unit>`; logs `journalctl -u <unit> -b`; failures `systemctl --failed`.

---

## 24. Task cookbook

### Update everything
```bash
yay                        # official + AUR packages (snapper takes a snapshot before/after)
npm update -g              # global npm tools (or: sysclean -n)
fwupdmgr get-updates       # firmware
# after a kernel update, reboot soon
```

### Monthly maintenance
```bash
sysclean -a                # caches, orphans, .pacnew, journal, CVEs, mirrors, npm/pip/uv
arch-audit -u              # anything vulnerable with a fix available?
sudo smartctl -a /dev/nvme0n1 | grep -E "Percentage Used|Media and Data"
```

### An update broke something: roll back
```bash
snapper -c root list                     # find the "pre" snapshot of that pacman run
sudo snapper -c root undochange 120..121 # revert the changes between pre (120) and post (121)
# or: reboot → GRUB → "Arch Linux snapshots" → boot the old one, then fix from there
# or: btrfs-assistant (GUI) → Snapper → restore
```
Downgrade a single package: `sudo pacman -U /var/cache/pacman/pkg/<pkg>-<oldver>.pkg.tar.zst`.

### Restore a deleted/changed file from a snapshot
```bash
snapper -c home list
sudo cp /home/.snapshots/<N>/snapshot/rivindu02/path/to/file ~/path/to/file
```

### Free up disk space
```bash
duf                        # which disk is full
dust -d 2 ~                # what's big
gdu ~                      # browse and delete interactively
sysclean                   # caches, orphans, old packages
podman system prune        # unused container images
```

### Screenshots, recording, OCR
- Region: `SUPER+SHIFT+S`. Full screen: `Print`. Both are saved to `~/Pictures/Screenshots` and copied.
- Text from the screen: `SUPER+SHIFT+T`.
- Record the screen: OBS → "Screen Capture (PipeWire)".

### Send a file to your phone or another device
- Same Wi-Fi: **LocalSend** on both devices.
- Anywhere: `SUPER+U` → pick a device → "Send File" (Tailscale), or `tailscale file cp file.pdf iphone:`.
- Received Taildrop files land in `~/tailscale`.

### Connect an external monitor / present
- `SUPER+P`: mirror / extend / single screen.
- Saved layouts: `hyprmoncfg`; GUI settings: HyprMod.

### Add or rotate an API key
```bash
apikey set openroute       # paste the key (hidden)
apikey list
```

### Back up and restore (once a destination is configured)
```bash
backup-home run --force
backup-home status
backup-home restic restore latest --target ~/restore --include ~/Documents/FYP
```

### Work in a Git repo
```bash
lazygit                    # stage/commit/push visually
gwt new feature-x          # parallel checkout of a branch
gh pr create               # open a PR
```

### Run a project's database / services
```bash
docker compose up -d       # uses Podman underneath
lazydocker                 # watch logs, restart containers
```

### Python project
```bash
uv venv && source .venv/bin/activate
uv pip install -r requirements.txt
jupyter lab
```

### Check security posture
```bash
arch-audit -u
sudo lynis audit system
sudo sbctl verify
sudo nft list table inet host_firewall
resolvectl status | grep -i DNSOverTLS
```

### Clipboard privacy
- History: `SUPER+V`. Passwords, tokens, keys and 6-digit OTPs are never stored.
- Wipe everything: `cliphist wipe`.

### Keep the laptop awake (downloads, presentations)
- `SUPER+SHIFT+I` toggles stay-awake. The Waybar icon shows the state. While it is on, you can close the lid: the laptop locks and the screen turns off, but downloads, Wi-Fi and running jobs continue (it still suspends at 5% battery). With it off, closing the lid always suspends, even with an external monitor plugged in. Keep the vents clear under heavy load.

### Something isn't working
```bash
systemctl --failed; systemctl --user --failed
journalctl -b -p err          # errors since boot
hyprctl configerrors          # Hyprland config problems
```
