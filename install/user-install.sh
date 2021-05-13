#!/usr/bin/env bash
set -euo pipefail
set -x

if ! test -f .volta/bin/volta ; then
  curl https://get.volta.sh | bash
  .volta/bin/volta install node
fi

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs > rustup-init.sh
bash rustup-init.sh -y
rm rustup-init.sh

if ! echo "$PATH" | grep go ; then
  # shellcheck disable=SC2016
  echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.zshrc
fi

if ! grep starship .zshrc ; then
  if ! grep starship ~/.zshrc ; then
    # shellcheck disable=SC2016
    echo 'eval "$(starship init zsh)"' >> ~/.zshrc
  fi
fi

if ! test -d .zim ; then
  wget -nv -O - https://raw.githubusercontent.com/zimfw/install/master/install.zsh | zsh
fi

if test -f id_rsa.pub ; then
  mkdir -p ~/.ssh
  mv id_rsa.pub ~/.ssh/
fi

if command -v zoxide > /dev/null ; then
  if ! grep zoxide ~/.zshrc ; then
    # shellcheck disable=SC2016
    echo 'eval "$(zoxide init zsh)" >/dev/null || true' >> ~/.zshrc
  fi
fi

tab --install all || echo "tab --install all will fail, but it can be ignored"

echo "final step, restoring data to SSD"
mkdir -p ssd/save
if ls ssd/save/* 2> /dev/null ; then
  gsutil cp -r "gs://$(whoami)-dev-machine" /mnt/disks/ssd/*
  mv ssd/save/* /mnt/disks/ssd/
fi
