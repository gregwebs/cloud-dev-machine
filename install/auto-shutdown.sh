#!/usr/bin/env bash
set -euo pipefail
set -x

# Automatically shutdown if there are no active sessions for 2+ hours

user=$(curl --header 'Metadata-Flavor: Google' "http://metadata.google.internal/computeMetadata/v1/instance/attributes/user")

# check that no active processes are running
if [[ "$(ps -au "$user" | grep -v systemd | grep -v sd-pam | grep -v etterminal | grep -v zsh | grep -v bash | grep -v ps | grep -v grep | wc -l)" == 1 ]] ; then
  cd "$(basename "$0")/.."

  # If not logged in for 2 hours, shutdown
  if ! last | grep 'logged in' ; then
    last_hour="$(last | grep "$user" | grep -v logged | cut -d '-' -f 2 | cut -d ':' -f 1 | awk '{print $1}' | sort | tail -1)"
    current_hour="$(date '+%H')"
    if [[ $(expr "$curren_hour" - 2) > "$last_hour" ]] ; then
      ./shutdown.sh
    fi
  fi

  # If logged in but not active for hours, shutdown
  active="$(finger "$user" | grep idle | awk '{print $2}' | uniq)"
  if [[ "$active" == hours ]] || [[ "$active" == days ]] ; then
    ./shutdown.sh
  fi
fi
