# ===========================================================
# 1) Non-interactive shell check
# ===========================================================
[[ $- != *i* ]] && return 

typeset -g POWERLEVEL9K_INSTANT_PROMPT=off
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi




# ===========================================================
# 2) Environment & Basics
# ===========================================================

export TERMINAL=ghostty
export TERM_PROGRAM=ghostty
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

# Load P10k config if present
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh


# for lazydocker to maintain podman containers and images
export DOCKER_HOST="unix://$XDG_RUNTIME_DIR/podman/podman.sock"


# ===========================================================
# 3) Oh My Zsh & Theme (Only load if installed)
# ===========================================================


export ZSH="$HOME/.oh-my-zsh"
if [[ -d "$ZSH" ]]; then
    ZSH_THEME="powerlevel10k/powerlevel10k"
    plugins=(git zsh-autosuggestions zsh-syntax-highlighting fzf-tab)
    source "$ZSH/oh-my-zsh.sh"
fi

# ------------- fzf-tab ------------------------
# Ctrl+Space : select multiple results, can be configured by `fzf-bindings` tag
# F1/F2		 : switch between groups, can be configured by `switch-group` tag
# /			 : trigger continuous completion (useful when completing a deep path), can be configured by `continuous-trigger` tag

ZSH_HIGHLIGHT_STYLES[comment]='fg=#a89984' # for comments


# ===========================================================
# 4) AI Tooling & API Config (OpenClaude via OpenRouter)
# ===========================================================
export CLAUDE_CODE_USE_OPENAI=1
export OPENAI_BASE_URL="https://openrouter.ai/api/v1"
export OPENAI_MODEL="openrouter/auto"
# Keys live in gnome-keyring (see `apikey`) and are fetched only when a tool runs,
# so normal shells never trigger the keyring unlock prompt.
export OC_KEY=openroute

# openclaude: uses OPENAI_API_KEY if already set, else the OC_KEY keyring entry
openclaude() {
	local key="${OPENAI_API_KEY:-}"
	[[ -n "$key" ]] || key="$(apikey get "$OC_KEY")" || return
	OPENAI_API_KEY="$key" command openclaude "$@"
}

# ── OpenRouter: Llama 4 Maverick (free, fast) ─────────
oc-open() {
  export OC_KEY=openroute
  export OPENAI_BASE_URL="https://openrouter.ai/api/v1"
  export OPENAI_MODEL="openrouter/auto"
  echo "OpenClaude → OpenRouter Auto (free)"
}
oc-open2() {
  export OC_KEY=openroute2
  export OPENAI_BASE_URL="https://openrouter.ai/api/v1"
  export OPENAI_MODEL="openrouter/auto"
  echo "OpenClaude → OpenRouter Auto (free)"
}



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

  # Improve Ctrl+R
  export FZF_CTRL_R_OPTS="
  --preview 'echo {}'
  --preview-window down:3:hidden
  --bind '?:toggle-preview'
  "
fi

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


# Safer shell behavior
setopt AUTO_CD
setopt INTERACTIVE_COMMENTS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_SAVE_NO_DUPS
setopt SHARE_HISTORY
setopt INC_APPEND_HISTORY

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
# 9) Language/tooling defaults
# ===========================================================
#
alias python="python3"

# NVM
export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
[[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"

# nvim opeanings
alias nv="nvim"
alias inv='nvim $(fzf -m --preview="bat --color=always {}")'


# ===========================================================
# 10) source ros2
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


[[ -z "$TMUX" ]] && tmux new-session -A -s main
