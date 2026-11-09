#!/bin/bash

set -eoux pipefail

# UNCDSR-182: /etc/group and /etc/passwd are mounted via subPath on emptyDirs
# so the container's root filesystem can be read-only, which means they start
# out empty on every boot. The base image's own ENTRYPOINT (start.sh) reads
# /etc/passwd (e.g. `id -u jovyan`) before our CMD (init.sh) ever runs, and
# aborts under `set -e` if that lookup fails -- re-seeding in init.sh is too
# late. Re-seed both files here, first, from the pristine, never-mounted-over
# backups baked at /etc/group.default and /etc/passwd.default, then hand off
# to the image's normal entrypoint chain.
if [ ! -s /etc/group ]; then
  cp /etc/group.default /etc/group
fi
if [ ! -s /etc/passwd ]; then
  cp /etc/passwd.default /etc/passwd
fi

exec tini -g -- start.sh "$@"
