#!/usr/bin/env bash
set -euo pipefail
set -x

# Do this first
# system packages (e.g. wget) may be needed by other installers
sudo ./debian-install.sh

sudo ./linux-install.sh

wd=$(pwd)
user=$(curl --header 'Metadata-Flavor: Google' "http://metadata.google.internal/computeMetadata/v1/instance/attributes/user")
if test -f authorized_keys ; then
    sudo mv authorized_keys "/home/$user/"
    sudo chown "$user:$user" "/home/$user/authorized_keys"
fi
if test -f .gitconfig ; then
    sudo mv .gitconfig "/home/$user/"
    sudo chown "$user:$user" "/home/$user/.gitconfig"
fi
sudo su "$user" -l -c "$wd/user-install.sh"

if ! command -v et >/dev/null && test -d "/home/$user/code/EternalTerminal" ; then
  cd "/home/$user/code/EternalTerminal/build"
  # cmake -DCMAKE_MAKE_PROGRAM=/usr/bin/make ../
  sudo make install
  sudo cp ../systemctl/et.service /etc/systemd/system/
  sudo cp ../etc/et.cfg /etc/
fi
