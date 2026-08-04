#!/bin/bash
set -uo pipefail

target="${SHARED_LINK_TARGET:-/shared}"
link="$HOME/shared"

if [ -d "$target" ]; then
  if [ -L "$link" ] || [ ! -e "$link" ]; then
    ln -sfn "$target" "$link" || echo "WARN: could not create $link -> $target"
  else
    echo "WARN: $link exists and is not a symlink"
  fi
fi

exit 0
