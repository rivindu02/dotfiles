# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ===========================================================
# 1) Non-interactive shell check
# ===========================================================
[[ $- != *i* ]] && return 

typeset -g POWERLEVEL9K_INSTANT_PROMPT=off




# ===========================================================
# 2) Environment & Basics
# ===========================================================

export TERMINAL=ghostty
export EDITOR=nvim
export VISUAL=nvim
export LANG=en_US.UTF-8

typeset -U path PATH

[[ -d "$HOME/.local/bin" ]] && path=("$HOME/.local/bin" $path)
[[ -d "$HOME/.npm-global/bin" ]] && path=("$HOME/.npm-global/bin" $path)

if [[ -d /usr/lib/jvm/java-17-openjdk ]]; then
    export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
    path=("$JAVA_HOME/bin" $path)
fi

if command -v tmux >/dev/null 2>&1; then
    path=("$HOME/.tmuxifier/bin" $path)
    command -v tmuxifier >/dev/null 2>&1 && eval "$(tmuxifier init -)"
fi


# for lazydocker to maintain podman containers and images
export DOCKER_HOST="unix://$XDG_RUNTIME_DIR/podman/podman.sock"


# ===========================================================
# 3) Oh My Zsh & Theme (Only load if installed)
# ===========================================================


# Arch keeps Oh My Zsh and Powerlevel10k updated through the AUR.
# Distroboxes share the plugins in HOME and can read the host's prompt scripts.
export ZSH=/usr/share/oh-my-zsh
ZSH_CUSTOM="$HOME/.local/share/oh-my-zsh-custom"
DISABLE_AUTO_UPDATE=true        # root-owned install; updated by yay instead
if [[ -r "$ZSH/oh-my-zsh.sh" ]]; then
    ZSH_THEME=""                # p10k is sourced below from the AUR package
    plugins=(git)               # Shared third-party plugins load after other integrations.
    source "$ZSH/oh-my-zsh.sh"
else
    # Containers without Oh My Zsh still get completion and the shared plugins.
    # Keep completion dumps separate: installed commands differ per container.
    _zsh_cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/${CONTAINER_ID:-host}"
    mkdir -p "$_zsh_cache_dir"
    autoload -Uz compinit
    ZSH_COMPDUMP="$_zsh_cache_dir/zcompdump-$ZSH_VERSION"
    compinit -d "$ZSH_COMPDUMP"
    unset _zsh_cache_dir
fi

for P10K_THEME in \
    /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme \
    /run/host/usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme \
    "$HOME/.local/share/powerlevel10k/powerlevel10k.zsh-theme"; do
    if [[ -r $P10K_THEME ]]; then
        source "$P10K_THEME"
        [[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
        break
    fi
done

# ------------- fzf-tab ------------------------
# Ctrl+Space : select multiple results, can be configured by `fzf-bindings` tag
# F1/F2		 : switch between groups, can be configured by `switch-group` tag
# /			 : trigger continuous completion (useful when completing a deep path), can be configured by `continuous-trigger` tag

# Distrobox may not have the plugin that normally declares this array.
typeset -gA ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[comment]='fg=#a89984' # for comments


# ===========================================================
# 4) AI Tooling & API Config (OpenClaude via OpenRouter)
# ===========================================================
# Keys live in gnome-keyring (see `apikey`) and are fetched only when a tool runs,
# so normal shells never trigger the keyring unlock prompt.
# The OpenAI-compatible settings are passed to openclaude only, so other
# OpenAI SDK programs are not redirected to OpenRouter.
OC_KEY=openroute
OC_BASE_URL="https://openrouter.ai/api/v1"
OC_MODEL="openrouter/auto"

# openclaude: uses OPENAI_API_KEY if already set, else the OC_KEY keyring entry
openclaude() {
	local key="${OPENAI_API_KEY:-}"
	[[ -n "$key" ]] || key="$(apikey get "$OC_KEY")" || return
	CLAUDE_CODE_USE_OPENAI=1 OPENAI_BASE_URL="$OC_BASE_URL" OPENAI_MODEL="$OC_MODEL" \
		OPENAI_API_KEY="$key" command openclaude "$@"
}

# ── OpenRouter Auto (free): pick which keyring key openclaude uses ─────────
oc-open()  { OC_KEY=openroute;  echo "OpenClaude → OpenRouter Auto (key: openroute)"; }
oc-open2() { OC_KEY=openroute2; echo "OpenClaude → OpenRouter Auto (key: openroute2)"; }



# ===========================================================
# 5) Navigation & history
# ===========================================================
# zoxide (if installed)
command -v zoxide >/dev/null && {
  eval "$(zoxide init zsh)"
  alias cd="z"
}

# Use the local fzf binary's integration rather than distro-specific paths.
if command -v fzf >/dev/null; then
    if _fzf_init="$(fzf --zsh 2>/dev/null)"; then
        eval "$_fzf_init"
    else
        # Older fzf packages predate --zsh; Arch and Debian ship different paths.
        for _fzf_dir in /usr/share/fzf /usr/share/doc/fzf/examples; do
            [[ -r $_fzf_dir/key-bindings.zsh ]] && source "$_fzf_dir/key-bindings.zsh"
            [[ -r $_fzf_dir/completion.zsh ]] && source "$_fzf_dir/completion.zsh"
        done
        unset _fzf_dir
    fi
    unset _fzf_init
fi

# atuin: searchable history database. Loaded after fzf so it takes over Ctrl+R;
# the Up arrow keeps normal zsh history.
command -v atuin >/dev/null && eval "$(atuin init zsh --disable-up-arrow)"

show_file_or_dir_preview='
if [ -d {} ]; then
	command -v eza >/dev/null && eza --tree --color=always {} | head -200 || ls -R {} | head -200
else
	if command -v bat >/dev/null; then
		bat -n --color=always --line-range :500 {}
	elif command -v batcat >/dev/null; then
		batcat -n --color=always --line-range :500 {}
	else
		head -500 {}
	fi
fi
'
# folder and dir preview
export FZF_CTRL_T_OPTS="--preview \"$show_file_or_dir_preview\""

# folder tree view
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"


# Navigation using yazi
function y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}

# Mount <host>:<remote-dir> at ~/mnt/<host> over sshfs (only when not mounted), then open yazi.
# idmap=user maps remote file ownership to the local user, so git works inside the mount.
sshmount() {
  local host=$1 dir=$2 mnt=~/mnt/$1
  mkdir -p "$mnt"
  mountpoint -q "$mnt" || sshfs "$host:$dir" "$mnt" -o idmap=user,reconnect,ServerAliveInterval=15,ServerAliveCountMax=3 || return
  yazi "$mnt"
}
entc()   { sshmount entc /home/ravindu; }
jetson() { sshmount jetson /home/jetson; }
alias entc-umount='fusermount3 -u ~/mnt/entc'
alias jetson-umount='fusermount3 -u ~/mnt/jetson'


# Safer shell behavior
setopt AUTO_CD
setopt INTERACTIVE_COMMENTS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_SAVE_NO_DUPS
setopt SHARE_HISTORY

# ===========================================================
# 6) Modern CLI replacements (cross-distro safe)
# ===========================================================
# bat 
if command -v bat >/dev/null; then
  alias cat="bat"
fi

# eza
if command -v eza >/dev/null; then
  alias ls="eza --icons --group-directories-first"
  alias ll="eza -lh --git"
fi


# ===========================================================
# 7) Git productivity
# ===========================================================
#
alias g="git"
alias gs="git status"
alias ga="git add"
alias gc="git commit"
alias gco="git checkout"
alias gl="git log --oneline --graph --decorate"


# ===========================================================
# 8) Language/tooling defaults
# ===========================================================
#
alias python="python3"

# NVM
export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
[[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"

# nvim opeanings
alias nv="nvim"
inv() { fzf -m --print0 --preview="bat --color=always {}" | xargs -0 -r -o nvim; }


# ===========================================================
# 9) source ros2
# ===========================================================
#
[ -f /opt/ros/jazzy/setup.zsh ] && source /opt/ros/jazzy/setup.zsh

# elif [ -f /opt/ros/humble/setup.zsh ]; then
#     source /opt/ros/humble/setup.zsh
# fi

# # Only load the bridge workspace under Humble
# if [ "$ROS_DISTRO" = "humble" ] && [ -f ~/ros_gz_ws/install/setup.zsh ]; then
#     source ~/ros_gz_ws/install/setup.zsh
# fi

alias gz="env -u WAYLAND_DISPLAY QT_QPA_PLATFORM=xcb gz"


# Register colcon without its hook rerunning compinit with a shared cache path.
if [[ -r /usr/share/colcon_argcomplete/hook/colcon-argcomplete.zsh ]]; then
    autoload -Uz bashcompinit
    bashcompinit
    if command -v register-python-argcomplete3 >/dev/null 2>&1; then
        eval "$(register-python-argcomplete3 colcon)"
    elif command -v register-python-argcomplete >/dev/null 2>&1; then
        eval "$(register-python-argcomplete colcon)"
    fi
fi

alias cubeide="ghostty -e zsh -c \"distrobox enter devbox -- /opt/st/stm32cubeide_2.1.0/stm32cubeide\""
alias ai-main="gemini"


# Load after fzf/Atuin/ROS so their widgets cannot replace fzf-tab or highlighting.
for _zsh_plugin in zsh-autosuggestions fzf-tab zsh-syntax-highlighting; do
    [[ $_zsh_plugin == fzf-tab ]] && ! command -v fzf >/dev/null 2>&1 && continue
    _zsh_plugin_file="$ZSH_CUSTOM/plugins/$_zsh_plugin/$_zsh_plugin.plugin.zsh"
    [[ -r $_zsh_plugin_file ]] && source "$_zsh_plugin_file"
done
unset _zsh_plugin _zsh_plugin_file

[[ -r "$HOME/.config/tmux/context.zsh" ]] && source "$HOME/.config/tmux/context.zsh"

# Auto-attach tmux only in Ghostty, not in IDE or other terminals
[[ -z "$TMUX" && -n "$GHOSTTY_RESOURCES_DIR" ]] && tmux new-session -A -s main
