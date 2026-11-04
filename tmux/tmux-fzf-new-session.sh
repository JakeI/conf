#!/bin/sh
# Fuzzy new-session picker for tmux (bound to prefix N in tmux.conf).
#
# Pick a directory with fzf; get a session named after the directory's
# basename, rooted there. If the name is already taken by a session with a
# different root, a suffixed session ("<name>-2", "<name>-3", ...) is created;
# if the existing session has the same root directory, it is just switched to.

# Search locations -- one directory per line, `~` and `$HOME` both work.
# Each location itself and its subdirectories are selectable.
# Add more lines here to extend the list.
ROOTS="
/mnt/d/val
~
"

MAXDEPTH=4

# fd options: directories up to MAXDEPTH levels deep, skipping hidden dirs
# (default) and these noisy names everywhere -- add more --exclude as needed.
FD_OPTS="--type d --max-depth $MAXDEPTH --exclude miniconda3 --exclude node_modules"

# --- build the directory list ---------------------------------------------
# fd prints trailing slashes: strip them (a trailing slash in a pane's start
# directory makes zsh's %1~ prompt escape expand empty), then shorten $HOME
# to ~ so entries from there start with ~ as usual.
list=$(
    printf '%s\n' "$ROOTS" |
    while IFS= read -r root; do
        [ -n "$root" ] || continue
        case "$root" in
            "~")   root="$HOME" ;;
            "~"/*) root="$HOME/${root#\~\/}" ;;
        esac
        [ -d "$root" ] || continue
        printf '%s\n' "$root"
        fd $FD_OPTS . "$root" 2>/dev/null
    done |
    sed -e 's:/\+$::' -e "s:^$HOME:~:" |
    sort -u
)

dir=$(printf '%s\n' "$list" |
    fzf --prompt='dir> ' \
        --height=100% --reverse \
        --color=border:39,prompt:39 \
        --preview='p={}; case "$p" in "~") p="$HOME";; "~"/*) p="$HOME/${p#\~/}";; esac; ls -A --color=always -- "$p" 2>/dev/null | head -50') || exit 0

[ -n "$dir" ] || exit 0

# turn ~/... back into an absolute path
case "$dir" in
    "~")   dir="$HOME" ;;
    "~"/*) dir="$HOME/${dir#\~\/}" ;;
esac

# defense in depth: no trailing slashes in the pane's start directory
while [ "$dir" != "/" ] && [ "${dir%/}" != "$dir" ]; do
    dir="${dir%/}"
done
[ -d "$dir" ] || exit 0

# tmux session names may not contain "." or ":"
name=$(basename "$dir" | tr '.:' '--')

# remember each session's root directory, so re-picking the same directory
# switches to that session instead of fighting over the same name
TAG=tmux-fzf-session-root

session_root() {
    tmux show-environment -t "=$1" "$TAG" 2>/dev/null | cut -d= -f2-
}

if ! tmux has-session -t "=$name" 2>/dev/null; then
    tmux new-session -d -s "$name" -c "$dir"
    tmux set-environment -t "$name" "$TAG" "$dir"
else
    stored=$(session_root "$name")
    if [ -z "$stored" ]; then
        # session predates this script: fall back to the pane's current path
        # and record it, so the comparison is stable from now on
        stored=$(tmux display-message -p -t "=$name" '#{pane_current_path}')
        tmux set-environment -t "$name" "$TAG" "$stored"
    fi
    if [ "$stored" != "$dir" ]; then
        base=$name
        i=2
        while tmux has-session -t "=$name" 2>/dev/null; do
            name="$base-$i"
            i=$((i + 1))
        done
        tmux new-session -d -s "$name" -c "$dir"
        tmux set-environment -t "$name" "$TAG" "$dir"
    fi
fi

tmux switch-client -t "$name"
