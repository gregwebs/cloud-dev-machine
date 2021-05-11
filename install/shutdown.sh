#!/usr/bin/env bash
set -euo pipefail

# The SSD data will be gone

# Not necessary to restore /tmp
# Main goal is not to save the SSD tmp
rm /tmp
mv /mnt/disks/ssd/tmp /tmp

user=$(curl --header 'Metadata-Flavor: Google' "http://metadata.google.internal/computeMetadata/v1/instance/attributes/user")
mkdir -p "/home/$user/ssd/save/"
mv /mnt/disks/ssd/* "/home/$user/ssd/save/"
sudo shutdown now
