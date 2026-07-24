#!/bin/bash
set -uo pipefail

# Create canonical symlinks in $HOME for shared storage mounts so a document's
# path relative to this pod's jupyter root_dir ($HOME) equals its path relative
# to the collab broker's root (/collab/<basename>). Real-time collaboration
# rooms are keyed on that relative path: a shared file opened through any other
# path gets a private (single-user) room instead.
#
# Override the candidate mounts with SHARED_LINK_DIRS (space-separated dirs).
# Idempotent, and must never fail pod startup (init.sh runs under set -e).

shopt -s nullglob
candidates=(${SHARED_LINK_DIRS:-/home/shared /shared/*})
for target in "${candidates[@]}"; do
  [ -d "$target" ] || continue
  link="$HOME/$(basename "$target")"
  if [ -L "$link" ]; then
    ln -sfn "$target" "$link" || echo "WARN: could not refresh symlink $link"
  elif [ -e "$link" ]; then
    echo "WARN: $link exists and is not a symlink; shared RTC rooms unavailable for $target"
  else
    ln -s "$target" "$link" || echo "WARN: could not create symlink $link"
  fi
done

exit 0
