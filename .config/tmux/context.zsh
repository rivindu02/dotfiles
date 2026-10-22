# Update the host tmux status without requiring a compatible client in containers.
_tmux_context_update() {
    [[ -n $TMUX && -n $TMUX_PANE ]] || return 0

    local server_pid=${${(s:,:)TMUX}[2]} pane_id=${TMUX_PANE#%}
    [[ $server_pid == <-> && $pane_id == <-> ]] || return 0

    local label=${CONTAINER_ID:-}
    if [[ -z $label && ( -n $container || -e /run/.containerenv || -e /.dockerenv ) ]]; then
        label="CONTAINER:${HOSTNAME:-${HOST:-unknown}}"
    fi
    # Labels become tmux format text; keep format directives and shell syntax out.
    label=${label//[^[:alnum:]_.:-]/_}
    local cache_dir="$HOME/.cache/tmux/pane-context"
    [[ -d $cache_dir ]] || mkdir -p "$cache_dir" || return 0
    local context_file="$cache_dir/$server_pid-$pane_id"
    label=${(U)label}
    # Read with a Zsh builtin and write only when entering/leaving a container.
    [[ -r $context_file && "$(<"$context_file")" == "$label" ]] && return 0
    print -r -- "$label" > "$context_file"
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd _tmux_context_update
_tmux_context_update
