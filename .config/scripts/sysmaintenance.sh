#!/usr/bin/env bash
# ------------------------------------------------------------
# Arch "Spring-Clean" Maintenance Script
# (interactive, abort-safe, log-to-file)
# ------------------------------------------------------------
#  • Designed for periodic housekeeping (monthly-ish)
#  • Optionally run with --upgrade to include a full system upgrade.
#  • Automatically detects paru or yay and uses whichever is found.
#  • Requires: pacman-contrib (paccache), pacdiff, plus the detected AUR helper.
#
#  Usage: ./spring-clean.sh [OPTIONS]
#    -u | --upgrade      Full system upgrade before cleaning
#    -m | --mirrors      Refresh mirrorlist via reflector
#    -d | --docker       Prune Docker images/containers/volumes
#    -n | --node         Clean npm global cache
#    -p | --python       Clean pip cache
#    -a | --all          Enable all optional steps
#    -h | --help         Show this help
# ------------------------------------------------------------

set -euo pipefail
trap 'echo -e "\n[!] Aborted by user (line $LINENO)"; exit 1' INT TERM

# ---------- Detect AUR helper ---------------------------------------------
if command -v paru &>/dev/null; then
  AUR=paru
elif command -v yay &>/dev/null; then
  AUR=yay
else
  echo "Error: neither paru nor yay found in PATH." >&2
  exit 1
fi

# ---------- Config --------------------------------------------------------
LOG_DIR="$HOME/.local/var/log"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/spring-clean-$(date +%F_%H-%M-%S).log"

PACCACHE_RETAIN=2   # keep N most recent package versions
CACHE_DAYS=30       # prune ~/.cache entries older than N days
JOURNAL_RETAIN="7d" # journald vacuum threshold (e.g. 500M or 7d)

# ---------- Redirect all output to log + terminal -------------------------
exec > >(tee -a "$LOG_FILE") 2>&1

# ---------- Helpers -------------------------------------------------------
confirm() {
  read -r -p "${1:-Are you sure? [y/N]} " ans
  [[ "$ans" =~ ^([yY][eE][sS]|[yY])$ ]]
}

announce() {
  printf "\n\e[1;34m==> %s\e[0m\n" "$1"
}

success() {
  printf "\e[1;32m  ✔ %s\e[0m\n" "$1"
}

warn() {
  printf "\e[1;33m  ⚠ %s\e[0m\n" "$1"
}

skip() {
  printf "\e[2m  — Skipped\e[0m\n"
}

bytes_to_human() {
  numfmt --to=iec-i --suffix=B "$1" 2>/dev/null || echo "${1}B"
}

# Returns size of a path in bytes (0 if missing)
# Pass second arg "sudo" to run with elevated privileges (e.g. /var/cache/pacman)
path_bytes() {
  local target="$1"
  local use_sudo="${2:-}"
  if [[ "$use_sudo" == "sudo" ]]; then
    sudo du -sb "$target" 2>/dev/null | cut -f1 || echo 0
  else
    du -sb "$target" 2>/dev/null | cut -f1 || echo 0
  fi
}

# ---------- CLI Switches --------------------------------------------------
DO_UPGRADE=false
DO_MIRRORS=false
DO_DOCKER=false
DO_NODE=false
DO_PYTHON=false

while [[ $# -gt 0 ]]; do
  case $1 in
    -u|--upgrade) DO_UPGRADE=true ; shift ;;
    -m|--mirrors) DO_MIRRORS=true ; shift ;;
    -d|--docker)  DO_DOCKER=true  ; shift ;;
    -n|--node)    DO_NODE=true    ; shift ;;
    -p|--python)  DO_PYTHON=true  ; shift ;;
    -a|--all)
      DO_UPGRADE=true
      DO_MIRRORS=true
      DO_DOCKER=true
      DO_NODE=true
      DO_PYTHON=true
      shift ;;
    -h|--help)
      grep '^#  ' "$0" | sed 's/^#  //'
      exit 0 ;;
    *) echo "Unknown option: $1" ; exit 2 ;;
  esac
done

# ---------- Banner --------------------------------------------------------
printf "\n\e[1;34m"
echo "╔══════════════════════════════════════════╗"
echo "║        Arch Spring-Clean Script          ║"
echo "╚══════════════════════════════════════════╝"
printf "\e[0m"
echo "  AUR helper : $AUR"
echo "  Log file   : $LOG_FILE"
echo "  Started    : $(date)"

# ---------- 1. Mirrorlist refresh (optional) ------------------------------
if $DO_MIRRORS; then
  announce "Mirrorlist refresh (reflector)"
  if command -v reflector &>/dev/null; then
    if confirm "Refresh mirrorlist with reflector? [y/N]"; then
      sudo reflector \
        --country $(curl -s https://ipapi.co/country/ 2>/dev/null || echo "US") \
        --age 12 \
        --protocol https \
        --sort rate \
        --save /etc/pacman.d/mirrorlist
      success "Mirrorlist updated"
    else
      skip
    fi
  else
    warn "reflector not installed — skipping (install with: pacman -S reflector)"
  fi
fi

# ---------- 2. Optional system upgrade ------------------------------------
if $DO_UPGRADE; then
  announce "System upgrade ($AUR -Syu)"
  if confirm "Run full system upgrade now? [y/N]"; then
    $AUR -Syu
    success "System upgraded"
  else
    skip
  fi
fi

# ---------- 3. .pacnew / .pacsave merge -----------------------------------
announce "Checking for .pacnew / .pacsave files"
PACNEW_FILES=$(find /etc \( -name "*.pacnew" -o -name "*.pacsave" \) 2>/dev/null | wc -l || true)
if (( PACNEW_FILES > 0 )); then
  warn "Found $PACNEW_FILES .pacnew/.pacsave file(s):"
  find /etc \( -name "*.pacnew" -o -name "*.pacsave" \) 2>/dev/null | while read -r f; do
    echo "    $f"
  done
  if confirm "Run pacdiff interactively now? [y/N]"; then
    sudo pacdiff
    success "pacdiff completed"
  else
    warn "Skipped — remember to resolve these manually with: sudo pacdiff"
  fi
else
  success "No .pacnew / .pacsave files found"
fi

# ---------- 4. Pacman cache trim ------------------------------------------
announce "Pacman cache trim (keeping latest $PACCACHE_RETAIN versions)"
before=$(path_bytes /var/cache/pacman/pkg sudo)
echo "  Current cache: $(bytes_to_human "$before")"

if confirm "Clean pacman cache now? [y/N]"; then
  sudo paccache -vrk$PACCACHE_RETAIN   # keep N versions of installed pkgs
  sudo paccache -ruk0                   # remove ALL versions of uninstalled pkgs
  after=$(path_bytes /var/cache/pacman/pkg sudo)
  freed=$(( before - after ))
  success "Cache trimmed — freed $(bytes_to_human "$freed") (now $(bytes_to_human "$after"))"
else
  skip
fi

# ---------- 5. AUR build cache clean --------------------------------------
announce "AUR build cache clean ($AUR)"
AUR_CACHE=""
if [[ $AUR == "paru" ]]; then
  AUR_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/paru/clone"
elif [[ $AUR == "yay" ]]; then
  AUR_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/yay"
fi

if [[ -n "$AUR_CACHE" && -d "$AUR_CACHE" ]]; then
  # Check for root-owned subdirs (can happen if yay was accidentally run with sudo)
  ROOT_OWNED=$(find "$AUR_CACHE" -maxdepth 2 ! -readable 2>/dev/null | wc -l || echo 0)
  if (( ROOT_OWNED > 0 )); then
    warn "$ROOT_OWNED unreadable (root-owned) dir(s) in $AUR_CACHE"
    warn "Fix with: sudo chown -R $USER:$USER $AUR_CACHE"
  fi
  aur_before=$(path_bytes "$AUR_CACHE")
  echo "  AUR cache ($AUR_CACHE): $(bytes_to_human "$aur_before")"
  if confirm "Clean $AUR build cache? [y/N]"; then
    $AUR -Sc --noconfirm
    aur_after=$(path_bytes "$AUR_CACHE")
    freed=$(( aur_before - aur_after ))
    success "AUR cache cleaned — freed $(bytes_to_human "$freed")"
  else
    skip
  fi
else
  echo "  No $AUR cache directory found — skipping"
fi

# ---------- 6. Orphaned packages ------------------------------------------
announce "Removing orphaned packages"
mapfile -t ORPHANS < <($AUR -Qtdq 2>/dev/null || true)

if (( ${#ORPHANS[@]} > 0 )); then
  warn "Found ${#ORPHANS[@]} orphan(s):"
  printf "    %s\n" "${ORPHANS[@]}"
  if confirm "Remove these orphans? [y/N]"; then
    sudo pacman -Rns "${ORPHANS[@]}"
    success "Orphans removed"
  else
    skip
  fi
else
  success "No orphaned packages detected"
fi

# ---------- 7. Broken symlinks scan ---------------------------------------
announce "Scanning for broken symlinks"
BROKEN_LINKS=()
while IFS= read -r link; do
  BROKEN_LINKS+=("$link")
done < <(find /usr /opt "$HOME/.local" -xtype l 2>/dev/null)

if (( ${#BROKEN_LINKS[@]} > 0 )); then
  warn "Found ${#BROKEN_LINKS[@]} broken symlink(s):"
  printf "    %s\n" "${BROKEN_LINKS[@]}"
  if confirm "Remove these broken symlinks? [y/N]"; then
    for link in "${BROKEN_LINKS[@]}"; do
      rm -v "$link"
    done
    success "Broken symlinks removed"
  else
    warn "Skipped — review the list above manually"
  fi
else
  success "No broken symlinks found"
fi

# ---------- 8. $HOME/.cache prune ----------------------------------------
announce "Pruning ~/.cache (files unused > $CACHE_DAYS days)"
cache_before=$(path_bytes "$HOME/.cache")
echo "  Before: $(bytes_to_human "$cache_before")"

if confirm "Clean stale ~/.cache entries now? [y/N]"; then
  # -readable prunes dirs we don't have access to (e.g. root-owned yay build dirs)
  find "$HOME/.cache" -readable -type f -mtime +"$CACHE_DAYS" -print -delete 2>/dev/null || true
  find "$HOME/.cache" -readable -type d -empty -print -delete 2>/dev/null || true
  cache_after=$(path_bytes "$HOME/.cache")
  freed=$(( cache_before - cache_after ))
  success "Cache pruned — freed $(bytes_to_human "$freed") (now $(bytes_to_human "$cache_after"))"
else
  skip
fi

# ---------- 9. Flatpak cleanup (if installed) -----------------------------
if command -v flatpak &>/dev/null; then
  announce "Flatpak — removing unused runtimes"
  UNUSED=$(flatpak list --runtime --app-runtime=unused 2>/dev/null | wc -l || echo 0)
  if confirm "Run 'flatpak uninstall --unused'? [y/N]"; then
    flatpak uninstall --unused -y
    success "Flatpak unused runtimes removed"
  else
    skip
  fi
else
  announce "Flatpak not installed — skipping"
fi

# ---------- 10. Trash empty -----------------------------------------------
announce "Emptying trash"
if command -v gio &>/dev/null; then
  trash_before=0
  TRASH_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/Trash/files"
  [[ -d "$TRASH_DIR" ]] && trash_before=$(path_bytes "$TRASH_DIR")
  echo "  Trash size: $(bytes_to_human "$trash_before")"
  if (( trash_before > 0 )); then
    if confirm "Empty trash? [y/N]"; then
      gio trash --empty
      success "Trash emptied"
    else
      skip
    fi
  else
    success "Trash is already empty"
  fi
else
  warn "gio not available — install glib2 to enable trash management"
fi

# ---------- 11. Journald rotate & vacuum ----------------------------------
announce "Vacuuming journald logs (retain: $JOURNAL_RETAIN)"
journal_before=$(journalctl --disk-usage 2>/dev/null | grep -oP '[\d.]+\s*[A-Za-z]+' | head -1 || echo "unknown")
echo "  Before: $journal_before"

if confirm "Rotate & vacuum journald now? [y/N]"; then
  sudo journalctl --rotate
  sudo journalctl --vacuum-time="$JOURNAL_RETAIN"
  journal_after=$(journalctl --disk-usage 2>/dev/null | grep -oP '[\d.]+\s*[A-Za-z]+' | head -1 || echo "unknown")
  success "Journald vacuumed — $journal_before → $journal_after"
else
  skip
fi

# ---------- 12. Old kernel cleanup ----------------------------------------
announce "Checking for old kernel packages"
INSTALLED_KERNELS=$(pacman -Q 2>/dev/null | grep -E '^linux[^ ]*\s' | grep -v 'headers\|docs\|acpi\|nvidia' || true)
KERNEL_COUNT=$(echo "$INSTALLED_KERNELS" | grep -c . || echo 0)

echo "  Installed kernel packages ($KERNEL_COUNT):"
echo "$INSTALLED_KERNELS" | while read -r k; do echo "    $k"; done

if (( KERNEL_COUNT > 2 )); then
  warn "More than 2 kernel packages found — you may want to remove old ones manually"
  warn "Use: sudo pacman -Rns <package-name>"
else
  success "Kernel count looks fine"
fi

# ---------- 13. Failed systemd units --------------------------------------
announce "Scanning for failed systemd services"
FAILED=$(systemctl --failed --no-pager --plain 2>/dev/null | grep -v "^0 loaded" | grep "●" || true)

if [[ -z "$FAILED" ]]; then
  success "No failed units detected"
else
  warn "Failed units found:"
  systemctl --failed --no-pager
  if confirm "Attempt to restart failed units? [y/N]"; then
    systemctl --failed --no-pager --plain | awk '/●/{print $2}' | while read -r unit; do
      echo "  Restarting: $unit"
      sudo systemctl restart "$unit" && success "Restarted $unit" || warn "Could not restart $unit"
    done
  else
    warn "Review failed units with: systemctl --failed"
  fi
fi

# ---------- 14. Docker prune (optional) -----------------------------------
if $DO_DOCKER; then
  announce "Docker system prune"
  if command -v docker &>/dev/null; then
    if confirm "Run 'docker system prune -f'? (removes stopped containers, dangling images) [y/N]"; then
      docker system prune -f
      success "Docker pruned"
    else
      skip
    fi
  else
    warn "Docker not installed — skipping"
  fi
fi

# ---------- 15. npm cache clean (optional) --------------------------------
if $DO_NODE; then
  announce "npm cache clean"
  if command -v npm &>/dev/null; then
    npm_before=$(npm cache verify 2>/dev/null | grep "Content verified" | grep -oP '\d+ files' || echo "?")
    echo "  npm cache: $npm_before"
    if confirm "Clean npm cache? [y/N]"; then
      npm cache clean --force
      success "npm cache cleaned"
    else
      skip
    fi
  else
    warn "npm not installed — skipping"
  fi
fi

# ---------- 16. pip cache clean (optional) --------------------------------
if $DO_PYTHON; then
  announce "pip cache purge"
  if command -v pip &>/dev/null; then
    pip_size=$(pip cache info 2>/dev/null | grep "Cache size" | awk '{print $3, $4}' || echo "unknown")
    echo "  pip cache size: $pip_size"
    if confirm "Purge pip cache? [y/N]"; then
      pip cache purge
      success "pip cache purged"
    else
      skip
    fi
  elif command -v pip3 &>/dev/null; then
    if confirm "Purge pip3 cache? [y/N]"; then
      pip3 cache purge
      success "pip3 cache purged"
    else
      skip
    fi
  else
    warn "pip not installed — skipping"
  fi
fi

# ---------- Summary -------------------------------------------------------
printf "\n\e[1;34m"
echo "╔══════════════════════════════════════════╗"
echo "║              Run Complete                ║"
echo "╚══════════════════════════════════════════╝"
printf "\e[0m"
printf "  Finished in %ds\n" "$SECONDS"
printf "  Log saved to: %s\n\n" "$LOG_FILE"
