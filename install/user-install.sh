#!/usr/bin/env bash
set -euo pipefail

if ! test -f .volta/bin/volta ; then
  curl https://get.volta.sh | bash
  .volta/bin/volta install node
fi

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs > rustup-init.sh
bash rustup-init.sh -y
rm rustup-init.sh

if ! echo "$PATH" | grep go ; then
  echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.zshrc
fi

if ! grep starship .zshrc ; then
  echo 'eval "$(starship init zsh)"' >> ~/.zshrc
fi

if ! test -d .zim ; then
  wget -nv -O - https://raw.githubusercontent.com/zimfw/install/master/install.zsh | zsh
fi

if test -f id_rsa.pub ; then
  mkdir -p ~/.ssh
  mv id_rsa.pub ~/.ssh/
fi

mkdir -p ssd/save
if ls ssd/save/* &> /dev/null ; then
  mv ssd/save/* /mnt/disks/ssd/
fi

tab --install all || echo "tab --install all will fail, but it can be ignored"