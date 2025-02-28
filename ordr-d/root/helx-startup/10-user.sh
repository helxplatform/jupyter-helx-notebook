#!/bin/bash

set -eoux pipefail

HELX_GROUP_NAME=${HELX_GROUP_NAME-"helx"}
DELETE_DEFAULT_USER_HOME_IF_UNUSED=${DELETE_DEFAULT_USER_HOME_IF_UNUSED-"yes"}
declare -i DEFAULT_UID=1000
declare -i DEFAULT_GID=0
declare -i CURRENT_UID=`id -u`
declare -i CURRENT_GID=`id -g`

echo "running as UID=$CURRENT_UID GID=$CURRENT_GID"

if [ $CURRENT_UID -ne 0 ]; then
  echo "not running as root"
  if [[ $CURRENT_UID -ne $DEFAULT_UID || "$USER" != "$DEFAULT_USER" ]]; then
    echo "not running as uid=$DEFAULT_UID or USER!=\"$DEFAULT_USER\""
    # Modify user entry in /etc/passwd.
    cp /etc/passwd /tmp/passwd
    sed -i -e "s/^$DEFAULT_USER\:x\:$DEFAULT_UID\:$DEFAULT_GID\:\:\/home\/$DEFAULT_USER/$USER\:x\:$CURRENT_UID\:$CURRENT_GID\:\:\/home\/$USER/" /tmp/passwd
    cp /tmp/passwd /etc/passwd
    rm /tmp/passwd

    if [[ -d /home/$DEFAULT_USER ]]; then
      if [[ "$USER" != "$DEFAULT_USER" && "$DELETE_DEFAULT_USER_HOME_IF_UNUSED" == "yes" ]]; then
        echo "deleting /home/$DEFAULT_USER"
        rm -rf /home/$DEFAULT_USER
      fi
    fi

  else
    echo "running as uid that is $DEFAULT_UID and USER is not \"$DEFAULT_USER\""
  fi
fi

# Get second supplementary group id with id command.  This is a hack for when
# OpenShift adds supplementary group id to process but the gid doesn't exist
# in /etc/group.  This might not work in all circumstances.
SUPPLEMENTARY_GROUP_ID=$( id | cut -d ',' -f 2 )
if [[ "$SUPPLEMENTARY_GROUP_ID" != "" ]]; then
  # Check if extra supplementary group ID is in /etc/group
  CHECK_FOR_SUP_GROUP_ID=$( grep -e "^.*:.*:$SUPPLEMENTARY_GROUP_ID:.*\$" /etc/group ) || true
  if [[ "$CHECK_FOR_SUP_GROUP_ID" == "" ]]; then
    # group doesn't exist, add it
    echo "$HELX_GROUP_NAME:x:$SUPPLEMENTARY_GROUP_ID:$USER">>/etc/group
  fi
fi

mkdir -p $HOME
# Copy default environment setup files if they don't already exist.
if [ ! -f $HOME/.bashrc ]; then
    cp /etc/skel/.bashrc $HOME/.bashrc
fi
if [ ! -f $HOME/.bash_logout ]; then
    cp /etc/skel/.bash_logout $HOME/.bash_logout
fi
if [ ! -f $HOME/.profile ]; then
    cp /etc/skel/.profile $HOME/.profile
fi
