# ===========================================================
# 1) Non-interactive shell check
# ===========================================================
[[ $- != *i* ]] && return 

typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
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
export TERM_PROGRAM=ghostty
export TERM=xterm-256color

# Defensive PATH additions
[[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"
[[ -d "$HOME/.npm-global/bin" ]] && export PATH="$HOME/.npm-global/bin:$PATH"

# Guarded JAVA_HOME (Only sets if the path actually exists)
if [[ -d /usr/lib/jvm/java-17-openjdk ]]; then
    export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
    export PATH="$JAVA_HOME/bin:$PATH"
fi

# Load P10k config if present
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh


# ===========================================================
# 3) Oh My Zsh & Theme (Only load if installed)
# ===========================================================

export ZSH="$HOME/.oh-my-zsh"
if [[ -d "$ZSH" ]]; then
    ZSH_THEME="powerlevel10k/powerlevel10k"
    plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
    source "$ZSH/oh-my-zsh.sh"
fi


# ===========================================================
# 4) AI Tooling & API Config (Aider, Gemini, OpenRouter)
# ===========================================================
export CLAUDE_CODE_USE_OPENAI=1  
export OPENAI_API_KEY="$(cat ~/.secrets/gemini 2>/dev/null)"
export OPENAI_BASE_URL="https://generativelanguage.googleapis.com/v1beta/openai"
export OPENAI_MODEL="gemini-flash-latest"

oc-gemini(){
	export OPENAI_API_KEY="$(cat ~/.secrets/gemini 2>/dev/null)"
	export OPENAI_BASE_URL="https://generativelanguage.googleapis.com/v1beta/openai"
	export OPENAI_MODEL="gemini-flash-latest"
}
oc-gemini2(){
	export OPENAI_API_KEY="$(cat ~/.secrets/gemini2 2>/dev/null)"
	export OPENAI_BASE_URL="https://generativelanguage.googleapis.com/v1beta/openai"
	export OPENAI_MODEL="gemini-flash-latest"
}
# ── OpenRouter: Llama 4 Maverick (free, fast) ─────────
oc-open() {
  export OPENAI_API_KEY="$(cat ~/.secrets/openroute 2>/dev/null)"
  export OPENAI_BASE_URL="https://openrouter.ai/api/v1"
  export OPENAI_MODEL="openrouter/auto"
  echo "OpenClaude → OpenRouter Auto (free)"
}
oc-open2() {
  export OPENAI_API_KEY="$(cat ~/.secrets/openroute2 2>/dev/null)"
  export OPENAI_BASE_URL="https://openrouter.ai/api/v1"
  export OPENAI_MODEL="openrouter/auto"
  echo "OpenClaude → OpenRouter Auto (free)"
}



# ===========================================================
# 6) Navigation & history
# ===========================================================

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
  # Improve Ctrl+R
  export FZF_CTRL_R_OPTS="
  --preview 'echo {}'
  --preview-window down:3:hidden
  --bind '?:toggle-preview'
  "
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
unalias gwt


# ===========================================================
# 9) Language/tooling defaults

alias python="python3"

# NVM
export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
[[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"
alias nv="nvim"





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
alias ai-gemma2="OLLAMA_API_BASE=$OLLAMA_BASE aider --model ollama/gemma4:e2b"
alias ai-gemma="aider --openai-api-base 'http://100.70.177.46:11434/v1' --openai-api-key ollama --model openai/gemma4:e2b --map-tokens 0 --timeout 600"
alias ai-deepseek-op="OLLAMA_API_BASE=$OLLAMA_BASE aider --novaforgeai/deepseek-coder:6.7b-optimized"
alias ai-deepseek="OLLAMA_API_BASE=$OLLAMA_BASE aider --model ollama/deepseek-coder:6.7b-instruct-q4_K_M"
alias ai-gemma4="OLLAMA_API_BASE=$OLLAMA_BASE aider --model ollama/gemma4:e4b"

# OPENCLAUDE (agentic, via Ollama)

alias oc-gemma="CLAUDE_CODE_USE_OPENAI=1 OPENAI_API_KEY=ollama OPENAI_BASE_URL=$OLLAMA_BASE/v1 OPENAI_MODEL=gemma4:e2b openclaude"
alias oc-3b="CLAUDE_CODE_USE_OPENAI=1 OPENAI_API_KEY=ollama OPENAI_BASE_URL=$OLLAMA_BASE/v1 OPENAI_MODEL=qwen2.5-coder:3b openclaude"
alias oc-7b="CLAUDE_CODE_USE_OPENAI=1 OPENAI_API_KEY=ollama OPENAI_BASE_URL=$OLLAMA_BASE/v1 OPENAI_MODEL=qwen2.5-coder:7b openclaude"
