#!/bin/bash

# NOTE: Script functionality superceded on ordr-d deployments by user identity management
# The script has been maintained since it is relevant to non-ordrd deployments at the moment.

set -eoux pipefail

# Copy default environment setup files if they don't already exist.
if [ ! -f $HOME/.bashrc ]; then
    cp /etc/skel/.bashrc $HOME/.bashrc
fi