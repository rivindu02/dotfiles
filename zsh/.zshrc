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
    eval "$(tmuxifier init -)"
fi


# for lazydocker to maintain podman containers and images
export DOCKER_HOST="unix://$XDG_RUNTIME_DIR/podman/podman.sock"


# ===========================================================
# 3) Oh My Zsh & Theme (Only load if installed)
# ===========================================================


# oh-my-zsh and powerlevel10k come from the AUR (oh-my-zsh-git, zsh-theme-powerlevel10k-git),
# so yay updates them. Third-party plugins are git clones in $ZSH_CUSTOM/plugins.
export ZSH=/usr/share/oh-my-zsh
ZSH_CUSTOM="$HOME/.local/share/oh-my-zsh-custom"
DISABLE_AUTO_UPDATE=true        # root-owned install; updated by yay instead
if [[ -d "$ZSH" ]]; then
    ZSH_THEME=""                # p10k is sourced below from the AUR package
    plugins=(git zsh-autosuggestions zsh-syntax-highlighting fzf-tab)
    source "$ZSH/oh-my-zsh.sh"
fi

P10K_THEME=/usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme
[[ -r $P10K_THEME ]] && source $P10K_THEME
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# ------------- fzf-tab ------------------------
# Ctrl+Space : select multiple results, can be configured by `fzf-bindings` tag
# F1/F2		 : switch between groups, can be configured by `switch-group` tag
# /			 : trigger continuous completion (useful when completing a deep path), can be configured by `continuous-trigger` tag

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

# fzf (cross-distro path handling)
if command -v fzf >/dev/null; then
	
	[[ -f /usr/share/fzf/key-bindings.zsh ]] && source /usr/share/fzf/key-bindings.zsh
	[[ -f /usr/share/fzf/completion.zsh ]] && source /usr/share/fzf/completion.zsh

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


# Colcon autocomplete
[ -f /usr/share/colcon_argcomplete/hook/colcon-argcomplete.zsh ] && source /usr/share/colcon_argcomplete/hook/colcon-argcomplete.zsh

alias cubeide="ghostty -e zsh -c \"distrobox enter devbox -- /opt/st/stm32cubeide_2.1.0/stm32cubeide\""
alias ai-main="gemini"


# Auto-attach tmux only in Ghostty, not in IDE or other terminals
[[ -z "$TMUX" && -n "$GHOSTTY_RESOURCES_DIR" ]] && tmux new-session -A -s main
