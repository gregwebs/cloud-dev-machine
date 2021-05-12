#!/usr/bin/env bash
set -euo pipefail
set -x

croncmd="sudo /home/$(whoami)/auto-shutdown.sh > /home/$(whoami)/auto-shutdown.log 2>&1"
cronjob="* * * 1 * $croncmd"
if !  crontab -l | grep -F "$croncmd" ; then
  # crontab -l will exit with a non-zero code when empty
  #( crontab -l | echo "$cronjob" ) | crontab -
  echo "$cronjob" | crontab -
fi

sudo ./debian-preinstall.sh
# Speed things up by running in parallel
sudo ./debian-install.sh &
install_pid=$!
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

wait "$install_pid"

if ! command -v et >/dev/null && test -d "/home/$user/code/EternalTerminal" ; then
  cd "/home/$user/code/EternalTerminal/build"
  # Some of these may only be needed for building
  sudo apt install -y libunwind-dev libboost-dev libsodium-dev libncurses5-dev libprotobuf-dev libutempter-dev libcurl4-nss-dev libsodium-dev libgflags-dev protobuf-compiler
  if test -x et && test -x etserver ; then
    sudo cp et etserver /usr/bin/
  else
    sudo apt install -y build-essential cmake git unzip zip protobuf-compiler 
    cmake -DCMAKE_MAKE_PROGRAM=/usr/bin/make ../
    sudo make install
  fi
  sudo cp ../systemctl/et.service /etc/systemd/system/
  sudo cp ../etc/et.cfg /etc/
  sudo systemctl start et
fi

sudo su "$user" -l -c "$wd/user-install.sh"
