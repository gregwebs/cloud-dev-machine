#!/usr/bin/env bash
set -euo pipefail
set -x

user=$(curl --header 'Metadata-Flavor: Google' "http://metadata.google.internal/computeMetadata/v1/instance/attributes/user")

# Mount the home directory to /home/$USER
home_device=/dev/disk/by-id/google-home
if test -e "$home_device" ; then
  if ! (mount | grep "$(readlink -f "$home_device")") ; then
    user_id=1010
    # Give user as an argument. Otherwise will need to later symlink to this dir
    if ! users | grep "^$user$" ; then
      useradd -M -s /bin/zsh -G sudo -u "$user_id" "$user"
    fi
    mkdir -p "/home/$user"
    if [[ 1 == $(lsblk -f "$home_device" | tail -1 | wc -w) ]] ; then
        mkfs.ext4 -F /dev/disk/by-id/google-home
    fi
    echo UUID="$(blkid -s UUID -o value "$home_device")" "/home/$user" ext4 discard,defaults,nofail 0 2 | tee -a /etc/fstab
    mount -o discard,defaults "$home_device" "/home/$user"
    chown -R "$user:$user" "/home/$user"
  fi
fi

# Mount the SSD drive to /mnt/disks/ssd
if test -e /dev/nvme0n1 && ! (mount | grep /mnt/disks/ssd) ; then
    if [[ 1 == $(lsblk -f /dev/nvme0n1 | tail -1 | wc -w) ]] ; then
      mkfs.ext4 -F /dev/nvme0n1
    fi
    mkdir -p /mnt/disks/ssd
    echo UUID="$(blkid -s UUID -o value /dev/nvme0n1)" /mnt/disks/ssd ext4 discard,defaults,nobarrier 0 2 | tee -a /etc/fstab
    mount -o discard,defaults,nobarrier /dev/nvme0n1 /mnt/disks/ssd
    chmod a+w /mnt/disks/ssd
    mkdir /mnt/disks/ssd/tmp
    chmod a+w /mnt/disks/ssd/tmp
    chown -R "$user:$user" /mnt/disks/ssd
    mv /tmp/* /mnt/disks/ssd/tmp/
    mv /tmp/.*-* /mnt/disks/ssd/tmp/
    rmdir /tmp
    ln -s /mnt/disks/ssd/tmp /tmp
fi

if ! test -f /usr/local/go/bin/go ; then
  go=go1.16.3.linux-amd64.tar.gz
  wget "https://golang.org/dl/$go"
  rm -rf /usr/local/go && tar -C /usr/local -xzf "$go"
  rm "$go"
fi

if ! test -e /usr/local/bin/tab ; then
  tab="tab-x86_64-unknown-linux-musl.tar.gz"
  wget "https://github.com/austinjones/tab-rs/releases/download/v0.5.7/$tab"
  tar xvf "$tab"
  rm "$tab"
  mv tab /usr/local/bin
  chmod +x /usr/local/bin/tab
fi
