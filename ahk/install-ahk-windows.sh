#!/usr/bin/env bash
set -euo pipefail

# Only run in WSL
grep -qi microsoft /proc/version 2>/dev/null || exit 0

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
local_file="${SCRIPT_DIR}/fix_win_nav.ahk"
[[ -f "$local_file" ]] || { echo "Local file not found: $local_file" >&2; exit 1; }

WINDOWS_USER_HOME="/mnt/c/Users/$USER"
remote_dir="${WINDOWS_USER_HOME}/fix_win_nav"
remote_file="${remote_dir}/fix_win_nav.ahk"

mkdir -p "$remote_dir"

if [[ ! -f "$remote_file" ]] || [[ "$local_file" -nt "$remote_file" ]]; then
    cp "$local_file" "$remote_file"
    echo "Updated remote file: $remote_file"
else
    echo "Remote file already up to date: $remote_file"
fi
