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
export JUPYTER_AI_DEFAULT_MODEL=${JUPYTER_AI_DEFAULT_MODEL-"openai/gpt-5"}
export JUPYTER_AI_DEFAULT_PERSONA=${JUPYTER_AI_DEFAULT_PERSONA-"jupyter-ai-personas::goodbot::GoodBotPersona"}
export GOODBOT_STORE_IDS_PATH="$HOME/.goodbot/store_ids.json"
# Set a custom prompt for the user that's more pleasant to read in the terminal
export PROMPT_COMMAND='PS1="\[\033[32m\]\u\[\033[00m\]:\[\033[34m\]\w\[\033[00m\]\$ "'

# Clone the hackathon repo into the user's home directory if it doesn't already
# exist, then switch to a user-specific branch (creating it if needed).
HACKATHON_REPO="https://github.com/RENCI/AI-For-Public-Good-Hackathon"
HACKATHON_DIR="$HOME/AI-For-Public-Good-Hackathon"
if [ ! -d "$HACKATHON_DIR" ]; then
  echo "Cloning hackathon repo into $HACKATHON_DIR"
  git clone "$HACKATHON_REPO" "$HACKATHON_DIR"
fi
cd "$HACKATHON_DIR"
USERNAME=${USERNAME-$USER}
if git show-ref --verify --quiet "refs/heads/$USERNAME"; then
  echo "Switching to existing branch $USERNAME"
  git checkout "$USERNAME"
elif git show-ref --verify --quiet "refs/remotes/origin/$USERNAME"; then
  echo "Checking out remote branch $USERNAME"
  git checkout -b "$USERNAME" "origin/$USERNAME"
else
  echo "Creating new branch $USERNAME"
  git checkout -b "$USERNAME"
fi

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
# cd $HOME
cd $HACKATHON_DIR

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
    --ServerApp.root_dir=${HACKATHON_DIR} \
    --ServerApp.default_url=${NB_PREFIX}/lab \
    --AiExtension.default_language_model=${JUPYTER_AI_DEFAULT_MODEL} \
    --AiExtension.initial_language_model=${JUPYTER_AI_DEFAULT_MODEL} \
    --PersonaManager.default_persona_id=${JUPYTER_AI_DEFAULT_PERSONA}
