#!/usr/bin/env bash
set -euo pipefail
set -x

# The SSD data will be gone

# Not necessary to restore /tmp
# Main goal is not to save the SSD tmp
rm /tmp
mv /mnt/disks/ssd/tmp /tmp

user=$(curl --header 'Metadata-Flavor: Google' "http://metadata.google.internal/computeMetadata/v1/instance/attributes/user")
mkdir -p "/home/$user/ssd/save/"
gsutil cp -r /mnt/disks/ssd/ "gs://${user}-dev-machine"
sudo shutdown now
