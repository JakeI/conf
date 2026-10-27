#!/bin/sh
# Fuzzy new-session picker: pick a directory under $ROOT, get a new tmux
# session named after the directory's basename, rooted at that directory.
# If a session with that name already exists, just switch to it.

ROOT="${TMUX_FZF_NEW_ROOT:-/mnt/d/val}"

dir=$(fd --type d --max-depth 4 --hidden --exclude '.*' . "$ROOT" 2>/dev/null \
    | fzf --prompt="$ROOT/> " \
          --height=100% --reverse \
          --color=border:39,prompt:39 \
          --preview='ls -A --color=always {} | head -50') || exit 0

[ -d "$dir" ] || exit 0

name=$(basename "$dir")

if ! tmux has-session -t "=$name" 2>/dev/null; then
    tmux new-session -d -s "$name" -c "$dir"
fi
tmux switch-client -t "$name"
