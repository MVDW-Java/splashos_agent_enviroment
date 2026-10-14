#!/usr/bin/env bash
# setup-git.sh — fetch or update the SplashOS repositories next to this repo.
#
# For each known repository:
#   - ../<repo> missing  -> git clone into ../<repo>
#   - ../<repo> exists   -> git pull (fast-forward only)
#
# Usage: ./setup-git.sh [repo ...]
#   repo is a bare name (defaults to the MVDW-SplashOS GitHub org) or an
#   explicit "name=url" pair.

set -eu

ORG="https://github.com/MVDW-SplashOS"

# "name|url|flags" entries (flags optional). SourceStream uses submodules,
# so it is cloned recursively.
KNOWN_REPOS=(
    "BuildScripts|$ORG/BuildScripts.git|"
    "SourceStream|$ORG/SourceStream.git|recursive"
    "SplashBuilder|$ORG/SplashBuilder.git|"
    "configuration|$ORG/configuration.git|"
)

resolve_repo() {
    # Turn a CLI argument into a "name|url|flags" entry.
    case "$1" in
        *"="*) printf '%s|%s|\n' "${1%%=*}" "${1#*=}" ;;
        *)     echo "$1|$ORG/$1.git|" ;;
    esac
}

update_repo() {
    local entry="$1" name url flags clone_flags recursive
    name="${entry%%|*}"
    entry="${entry#*|}"
    url="${entry%%|*}"
    flags="${entry#*|}"
    [ "$flags" = "$entry" ] && flags=""
    case "$flags" in
        recursive) recursive=1; clone_flags=(--recursive) ;;
        *)         recursive=0; clone_flags=() ;;
    esac

    if [ -d "../$name" ]; then
        if [ ! -d "../$name/.git" ] && ! git -C "../$name" rev-parse --git-dir >/dev/null 2>&1; then
            echo "✗ ../$name exists but is not a git repository; leaving it alone." >&2
            return 1
        fi
        echo "→ Updating $name ..."
        if git -C "../$name" pull --ff-only; then
            if [ "$recursive" -eq 1 ]; then
                git -C "../$name" submodule update --init --recursive || return 1
            fi
            echo "✓ $name updated."
        else
            echo "✗ $name could not be fast-forwarded (dirty tree or diverged branch)." >&2
            return 1
        fi
    else
        echo "→ Cloning $name ..."
        if git clone "${clone_flags[@]}" "$url" "../$name"; then
            echo "✓ $name cloned."
        else
            echo "✗ Failed to clone $name from $url." >&2
            return 1
        fi
    fi
}

failed=0
if [ "$#" -gt 0 ]; then
    entries=()
    for arg in "$@"; do entries+=("$(resolve_repo "$arg")"); done
else
    entries=("${KNOWN_REPOS[@]}")
fi

for entry in "${entries[@]}"; do
    update_repo "$entry" || failed=1
done

if [ "$failed" -ne 0 ]; then
    echo "Some repositories could not be fetched/updated; see messages above." >&2
    exit 1
fi
echo "All repositories are up to date."
