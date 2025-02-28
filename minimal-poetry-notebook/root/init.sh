#!/bin/bash

set -eoux pipefail

# The USER variable will be set if this container is created with Tycho, on
# most (if not all) local environments USER will also be set.  If USER is not
# set then use the NB_USER variable, which is set in the Dockerfile.
if [ -z "${USER+x}" ]; then
  echo "USER is not set, setting it to $NB_USER"
  USER=$NB_USER
else
  echo "setting NB_USER=$USER"
  export NB_USER=$USER
fi

export USER=${USER-"jovyan"}
export DEFAULT_USER="jovyan"
export HOME="/home/$USER"
export NB_ROOT_DIR=${NB_ROOT_DIR-$HOME}

# Change to the root directory to mitigate problems if the current working
# directory is deleted.
cd /

# Add other init scripts in $HELX_SCRIPTS_DIR with ".sh" as their extension.
# To run in a certain order, name them appropriately.
HELX_SCRIPT_DIR=/helx-startup
INIT_SCRIPTS_TO_RUN=$(ls -1 $HELX_SCRIPT_DIR/*.sh) || true
for INIT_SCRIPT in $INIT_SCRIPTS_TO_RUN
do
  echo "Running $INIT_SCRIPT"
  $INIT_SCRIPT  
done

# Change CWD to /home/$USER so it is the starting point for shells in jupyter.
cd $HOME

# The default for XDG_CACHE_HOME to use /home/jovyan/.cache and jupyter will
# create the directory if it doesn't exist.
export XDG_CACHE_HOME=$HOME/.cache

# Run "jupyter -h" to see some options (notebook, server, lab, etc.).  To get more
# options run "jupyter server --help-all".
jupyter lab \
    --IdentityProvider.token= \
    --ServerApp.ip='*' \
    --ServerApp.base_url=${NB_PREFIX} \
    --ServerApp.allow_origin="*" \
    --ServerApp.root_dir=${NB_ROOT_DIR} \
    --ServerApp.default_url=${NB_PREFIX}/lab \
    --ContentsManager.allow_hidden=True