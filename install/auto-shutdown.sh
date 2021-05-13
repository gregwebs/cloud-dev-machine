#!/usr/bin/env bash
set -euo pipefail
set -x

# Automatically shutdown if there are no active sessions for 2+ hours

user=$(curl --header 'Metadata-Flavor: Google' "http://metadata.google.internal/computeMetadata/v1/instance/attributes/user")

# check that no active user processes are running
if [[ "$(ps -au "$user" -F | grep -v -E "systemd|sshd|sd-pam|etterminal|zsh|bash|ps|grep|tab|$user|CMD" | grep "$user" | wc -l)" == 0 ]] ; then
  dir="$(dirname "$0")"

  # If not logged in for 2 hours, shutdown
  if ! last | grep 'logged in' ; then
    last_hour="$(last | grep "$user" | grep -v logged | cut -d '-' -f 2 | cut -d ':' -f 1 | awk '{print $1}' | sort | tail -1)"
    current_hour="$(date '+%H')"
    if [[ $(expr "$curren_hour" - 2) > "$last_hour" ]] ; then
      "$dir/shutdown.sh"
    fi
  fi

  # If logged in but not active for hours, shutdown
  if finger "$user" | grep 'Never logged in' ; then
    "$dir/shutdown.sh"
  fi

  if ! finger -l | grep idle | awk '{print $2}' | grep second ; then
    if ! finger -l | grep idle | awk '{print $2}' | grep minute ; then
      if finger -l | grep idle | awk '{print $2}' | grep hours || finger -l | grep idle | awk '{print $2}' | grep days ; then
        "$dir/shutdown.sh"
      fi
    fi
  fi
fi
