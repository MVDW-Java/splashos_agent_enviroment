#!/usr/bin/env bash
# setup-symlinks.sh — recreate the agent-environment symlinks.
#
# For each known SplashOS repository, links ./<name> -> ../<name> when that
# directory exists next to this repo; otherwise prompts for the location.
#
# Usage: ./setup-symlinks.sh [extra-dir ...]

set -eu

# The four repos this environment expects, plus any extras passed on the CLI.
KNOWN_DIRS=(BuildScripts SourceStream SplashBuilder configuration)
DIRS=("${KNOWN_DIRS[@]}" "$@")

prompt_for_path() {
    local name="$1" path resolved
    while true; do
        printf 'Where is "%s" located? (absolute path or path relative to %s): ' \
            "$name" "$PWD" >&2
        IFS= read -r path
        # Resolve relative input against the current directory.
        case "$path" in
            /*) ;;
            *) path="$PWD/$path" ;;
        esac
        # Normalize the path; only the resolved path goes to stdout.
        if [ -d "$path" ]; then
            resolved="$(cd "$path" 2>/dev/null && pwd -P)" || continue
            printf '%s\n' "$resolved"
            return 0
        fi
        printf '  Not a directory: %s — try again.\n' "$path" >&2
    done
}

link_dir() {
    local name="$1" target link
    link="./$name"

    if [ -L "$link" ]; then
        echo "✓ $name -> already linked to $(readlink "$link"), skipping."
        return 0
    fi
    if [ -e "$link" ]; then
        echo "✗ $name already exists and is not a symlink; refusing to touch it." >&2
        return 1
    fi

    if [ -d "../$name" ]; then
        target="../$name"
    else
        echo "? No directory '../$name' found next to this repo."
        target="$(prompt_for_path "$name")"
    fi

    ln -s "$target" "$link"
    echo "✓ $name -> $target"
}

failed=0
for dir in "${DIRS[@]}"; do
    link_dir "$dir" || failed=1
done

if [ "$failed" -ne 0 ]; then
    echo "Some links could not be created; see messages above." >&2
    exit 1
fi
echo "All symlinks are in place."
