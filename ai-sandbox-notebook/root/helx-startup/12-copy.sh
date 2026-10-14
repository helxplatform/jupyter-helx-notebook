#!/bin/bash

set -eoux pipefail

# Copies files matching glob patterns to target directories at startup.
#
# COPY_GLOB_PATTERNS format:
#   glob_pattern:target_dir;glob_pattern2:target_dir2
#
# Example:
#   COPY_GLOB_PATTERNS="/shared/users/User_Documentation/*.ipynb:~/;/shared/data/*.csv:~/data"

if [[ -z "${COPY_GLOB_PATTERNS:-}" ]]; then
    echo "COPY_GLOB_PATTERNS is not set, skipping file copy"
    exit
fi

# nullglob: unmatched globs expand to nothing instead of the literal pattern string.
# globstar: enable ** for recursive directory matching.
shopt -s nullglob globstar

IFS=';' read -ra ENTRIES <<< "$COPY_GLOB_PATTERNS"

for entry in "${ENTRIES[@]}"; do
    # Skip empty entries (e.g. from trailing semicolons)
    [[ -z "$entry" ]] && continue

    # Split on first colon into pattern and target_dir
    pattern="${entry%%:*}"
    target_dir="${entry#*:}"

    if [[ -z "$pattern" || -z "$target_dir" ]]; then
        echo "WARNING: malformed entry '$entry', skipping"
        continue
    fi

    # Expand ~ to $HOME
    target_dir="${target_dir/#\~/$HOME}"

    # Create target directory if it doesn't exist
    mkdir -p "$target_dir"

    # Expand the glob pattern
    files=($pattern)

    if [[ ${#files[@]} -eq 0 ]]; then
        echo "No files matched pattern: $pattern"
        continue
    fi

    for file in "${files[@]}"; do
        dest="$target_dir/$(basename "$file")"

        if [[ -e "$dest" ]]; then
            echo "Skipping $file -> $dest (already exists)"
        else
            echo "Copying $file -> $dest"
            cp -rn "$file" "$dest"
        fi
    done
done
