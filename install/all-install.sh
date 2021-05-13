#!/usr/bin/env bash
set -euo pipefail
set -x

sudo mv auto-shutdown.sh shutdown.sh /usr/local/bin/
sudo mv auto-shutdown.service auto-shutdown.timer /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable auto-shutdown.timer
sudo systemctl start auto-shutdown

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
  sudo apt install -y libunwind-dev libprotobuf-dev libgflags-dev
  cd "/home/$user/code/EternalTerminal"
  mkdir -p build
  cd build
  if ! test -x et && test -x etserver ; then
    sudo apt install -y pkg-config libboost-dev libsodium-dev libncurses5-dev libutempter-dev libcurl4-nss-dev libsodium-dev lprotobuf-compiler
    sudo apt install -y build-essential cmake git unzip zip
    cmake -DCMAKE_MAKE_PROGRAM=/usr/bin/make ../
    make
  fi
  sudo cp et etserver etterminal /usr/bin/
  sudo cp ../systemctl/et.service /etc/systemd/system/
  sudo cp ../etc/et.cfg /etc/
  sudo systemctl start et
fi

sudo su "$user" -l -c "$wd/user-install.sh"
