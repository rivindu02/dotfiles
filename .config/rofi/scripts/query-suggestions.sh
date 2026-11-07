#!/usr/bin/env bash
# Build into the user cache, and rebuild after source or Rofi ABI updates.
set -euo pipefail
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
theme="$HOME/.config/rofi/menus/search.rasi"
platform=${1:-duckduckgo}
provider=duckduckgo
prompt=Query
placeholder=""
case "$platform" in
    duckduckgo) label=DuckDuckGo; border_color='#DE5833'; verb=Search ;;
    chatgpt) label=ChatGPT; border_color='#10A37F'; verb=Ask ;;
    claude) label=Claude; border_color='#D79921'; verb=Ask ;;
    youtube) label=YouTube; border_color='#FB4934'; verb=Search; provider=youtube ;;
    *) printf 'Unknown search platform: %s\n' "$platform" >&2; exit 2 ;;
esac
export ROFI_SEARCH_PLATFORM="$label"
export ROFI_SEARCH_PROVIDER="$provider"
placeholder=${placeholder:-"${verb} ${label}…"}
query_style="window { border-color: ${border_color}; } entry { placeholder: \"${placeholder}\"; }"

plain_query() {
    exec rofi -dmenu -i -p "$prompt" -theme "$theme" \
        -theme-str "$query_style mainbox { children: [ \"inputbar\", \"message\" ]; }"
}

if ! command -v cc >/dev/null || ! command -v pkg-config >/dev/null || \
    ! pkg-config --exists rofi gio-2.0; then
    plain_query
fi
key=$(cat "$script_dir/search-suggestions.c" /usr/include/rofi/mode{,-private}.h; pkg-config --modversion rofi gio-2.0)
key=$(printf '%s' "$key" | sha256sum)
cache="${XDG_CACHE_HOME:-$HOME/.cache}/rofi-search/${key%% *}"
if ! mkdir -p "$cache"; then plain_query; fi
if [[ ! -f "$cache/search-suggestions.so" ]]; then
    build=$(mktemp "$cache/build.XXXXXX.so")
    trap 'rm -f -- "$build"' EXIT
    # pkg-config deliberately supplies separate compiler arguments.
    # shellcheck disable=SC2046
    if ! cc -std=c11 -Wall -Wextra -Werror -O2 -shared -fPIC \
        $(pkg-config --cflags rofi gio-2.0) "$script_dir/search-suggestions.c" \
        -o "$build" $(pkg-config --libs rofi gio-2.0); then
        rm -f -- "$build"
        plain_query
    fi
    mv -- "$build" "$cache/search-suggestions.so"
    trap - EXIT
fi
export ROFI_SEARCH_HELPER="$script_dir/search-suggestions.py"
export ROFI_PLUGIN_PATH="$cache${ROFI_PLUGIN_PATH:+:$ROFI_PLUGIN_PATH}"
exec rofi -show search-suggestions -modes search-suggestions \
    -display-search-suggestions "$prompt" -no-sort -no-auto-select \
    -kb-accept-custom 'Control+Return' -theme "$theme" \
    -theme-str "$query_style listview { lines: 6; fixed-height: false; dynamic: true; }"
