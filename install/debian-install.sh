#!/usr/bin/env bash
set -euo pipefail
set -x

apt update && apt upgrade

# Dev tools
apt install -y wget zsh fzf git shellcheck jq neovim bc xclip
# Build tools
apt install -y make cmake gcc g++

# Podman only available on newer versions of distros
apt install -y podman zoxide

# Docker
apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io

if ! command -v starship ; then
  set -x
  sh -c "$(curl -fsSL https://starship.rs/install.sh)" -- -y
  set +x
fi

if ! command -v rg ; then
  curl -LO https://github.com/BurntSushi/ripgrep/releases/download/12.1.1/ripgrep_12.1.1_amd64.deb
  dpkg -i ripgrep_12.1.1_amd64.deb
  rm ripgrep_12.1.1_amd64.deb
fi

if ! command -v sad ; then
  sad=x86_64-unknown-linux-gnu.deb
  wget "https://github.com/ms-jpq/sad/releases/download/ci_0.4.7_2020-08-06_07-03/$sad"
  dpkg -i "$sad"
  rm "$sad"
fi

if ! grep 40123 /etc/security/limits.conf ; then
  echo "* soft nofile 40123" | tee -a /etc/security/limits.conf
fi

#if ! command -v et ; then
#  Eternal terminal #does not yet work on Debian Bullseye
#  echo "deb https://github.com/MisterTea/debian-et/raw/master/debian-source/ buster main" | tee -a /etc/apt/sources.list.d/et.list
#  curl -sSL https://github.com/MisterTea/debian-et/raw/master/et.gpg | apt-key add -
#  apt update
#  apt install et
# Compile from source instaed
# sudo apt install -y build-essential libgflags-dev libprotobuf-dev protobuf-compiler libsodium-dev cmake git unzip zip
#fi
# sudo apt install libboost-dev libsodium-dev libncurses5-dev libprotobuf-dev protobuf-compiler libutempter-dev libcurl4-nss-dev libunwind-dev
