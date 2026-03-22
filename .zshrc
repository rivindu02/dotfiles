typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
# ===========================================================
# 1) Powerlevel10k instant prompt (must stay at top)

if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi


# ===========================================================
# 2) Environment & PATH

export ZSH="$HOME/.oh-my-zsh"
export PATH="$HOME/.local/bin:$PATH"
export LANG=en_US.UTF-8


# ===========================================================
# 3) Oh My Zsh configuration

ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
)

# Load Oh My Zsh only if installed
if [[ -f "$ZSH/oh-my-zsh.sh" ]]; then
  source "$ZSH/oh-my-zsh.sh"
fi


# ===========================================================
# 4) Powerlevel10k config (do NOT manually source theme)

[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh


# ===========================================================
# 5) tmux auto-start (terminal aware)
# # || "$TERM_PROGRAM" == "ghostty" 
export TERMINAL=ghostty   

if [[ -z "$TMUX" ]]; then
  if [[ -n "$ALACRITTY_WINDOW_ID" ]]; then
    command -v tmux >/dev/null && tmux new-session -A -s default
  fi
fi

# ===========================================================
# 6) Navigation & history

# zoxide (if installed)
command -v zoxide >/dev/null && {
  eval "$(zoxide init zsh)"
  alias cd="z"
}

# fzf (cross-distro path handling)
if command -v fzf >/dev/null; then
  # Arch path
  [[ -f /usr/share/fzf/key-bindings.zsh ]] && source /usr/share/fzf/key-bindings.zsh
  [[ -f /usr/share/fzf/completion.zsh ]] && source /usr/share/fzf/completion.zsh

  # Ubuntu path
  [[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]] && \
    source /usr/share/doc/fzf/examples/key-bindings.zsh
  [[ -f /usr/share/doc/fzf/examples/completion.zsh ]] && \
    source /usr/share/doc/fzf/examples/completion.zsh
fi

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


# Improve Ctrl+R
export FZF_CTRL_R_OPTS="
  --preview 'echo {}'
  --preview-window down:3:hidden
  --bind '?:toggle-preview'
"


# ===========================================================
# 7) Modern CLI replacements (cross-distro safe)

# bat (Ubuntu uses batcat)
if command -v bat >/dev/null; then
  alias cat="bat"
elif command -v batcat >/dev/null; then
  alias cat="batcat"
fi

# eza
if command -v eza >/dev/null; then
  alias ls="eza --icons --group-directories-first"
  alias ll="eza -lh --git"
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

export FZF_CTRL_T_OPTS="--preview \"$show_file_or_dir_preview\""
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"


# ===========================================================
# 8) Git productivity

alias g="git"
alias gs="git status"
alias ga="git add"
alias gc="git commit"
alias gco="git checkout"
alias gl="git log --oneline --graph --decorate"


# ===========================================================
# 9) Language/tooling defaults

alias python="python3"

# NVM
export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
[[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"
alias nv="nvim"


export TERMINAL=ghostty
export TERM_PROGRAM=ghostty
export TERM=xterm-256color
export EDITOR=nvim
export VISUAL=nvim


# ===========================================================
# 10) Local overrides
# [[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
# ===========================================================
#
#
# ===========================================================
# 11) source ros2
#
[ -f /opt/ros/humble/setup.zsh ] && source /opt/ros/humble/setup.zsh
alias cubeide="ghostty -e zsh -c \"distrobox enter devbox -- /opt/st/stm32cubeide_2.1.0/stm32cubeide\""
export PATH=~/.npm-global/bin:$PATH
alias aider="~/.venvs/aider/bin/aider"
export GROQ_API_KEY="$(cat ~/.secrets/groq 2>/dev/null)"
alias ai-main="gemini"
alias ai-groq="aider --model groq/llama-3.3-70b-versatile"
alias ai-kimi="aider -c ~/.config/aider/aider.kimi.yml"
# OFFLINE MODELS
OLLAMA_BASE="http://100.70.177.46:11434"
alias ai-7b="OLLAMA_API_BASE=$OLLAMA_BASE aider --model ollama/qwen2.5-coder:7b"
alias ai-3b="OLLAMA_API_BASE=$OLLAMA_BASE aider --model ollama/qwen2.5-coder:3b"
alias ai-deepseek-op="OLLAMA_API_BASE=$OLLAMA_BASE aider --model ollama/qwen2.5-coder:7b"
alias ai-deepseek="OLLAMA_API_BASE=$OLLAMA_BASE aider --model ollama/deepseek-coder:6.7b-instruct-q4_K_M"


