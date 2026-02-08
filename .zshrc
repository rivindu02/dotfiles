# ===========================================================


# 1) Powerlevel10k instant prompt

# MUST be at the very top (after comments)

if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi


# 2) Environment & PATH

export ZSH="$HOME/.oh-my-zsh"
export PATH="$HOME/.local/bin:$PATH"
export LANG=en_US.UTF-8


# 3) Oh My Zsh configuration

ZSH_THEME=""  # Using Powerlevel10k directly

plugins=(
git
zsh-autosuggestions
zsh-syntax-highlighting
)

# Load Oh My Zsh ONCE
source "$ZSH/oh-my-zsh.sh"


# 4) Powerlevel10k theme

source "$HOME/powerlevel10k/powerlevel10k.zsh-theme"
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh


# 5) tmux auto-start (after prompt init)

# tmux auto-start ONLY in Alacritty
if [[ -z "$TMUX" && -n "$ALACRITTY_WINDOW_ID" ]]; then
  tmux new-session -A -s default
fi


# 6) Navigation & history (HIGH VALUE)

# zoxide — smarter cd
eval "$(zoxide init zsh)"
alias cd="z"

# fzf — fuzzy finder (history, files, git)

if [[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]]; then
source /usr/share/doc/fzf/examples/key-bindings.zsh
source /usr/share/doc/fzf/examples/completion.zsh
fi

# Safer shell behavior
setopt AUTO_CD           # cd without typing cd
setopt INTERACTIVE_COMMENTS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_SAVE_NO_DUPS
setopt SHARE_HISTORY
setopt INC_APPEND_HISTORY

# improve crtl+R behavior
export FZF_CTRL_R_OPTS="
  --preview 'echo {}'
  --preview-window down:3:hidden
  --bind '?:toggle-preview'
"


# 7) Modern CLI replacements
# bat (better cat) — Ubuntu binary is batcat
command -v batcat >/dev/null && alias cat="batcat"

# eza (better ls)
command -v eza >/dev/null && {
alias ls="eza --icons --group-directories-first"
alias ll="eza -lh --git"
}


show_file_or_dir_preview="if [ -d {} ]; then eza --tree --color=always {} | head -200; else batcat -n --color=always --line-range :500 {}; fi"

export FZF_CTRL_T_OPTS="--preview '$show_file_or_dir_preview'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"

# Advanced customization of fzf options via _fzf_comprun function
# - The first argument to the function is the name of the command.
# - You should make sure to pass the rest of the arguments to fzf.
_fzf_comprun() {
  local command=$1
  shift

  case "$command" in
    cd)           fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
    export|unset) fzf --preview "eval 'echo \${}'"         "$@" ;;
    ssh)          fzf --preview 'dig {}'                   "$@" ;;
    *)            fzf --preview "$show_file_or_dir_preview" "$@" ;;
  esac
}


# 8) Git productivity aliases

alias g="git"
alias gs="git status"
alias ga="git add"
alias gc="git commit"
alias gco="git checkout"
alias gl="git log --oneline --graph --decorate"


# 9) Language/tooling defaults

alias python="python3"


# Node / NVM

export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
[[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"

export TERMINAL=ghostty
export TERM_PROGRAM=ghostty

# 10) Local overrides (IMPORTANT)

# Put experimental or machine‑specific config here
#[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

#=========================================================

