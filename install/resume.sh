#!/usr/bin/env bash
set -euo pipefail

user=$(curl --header 'Metadata-Flavor: Google' "http://metadata.google.internal/computeMetadata/v1/instance/attributes/user")
mv "/home/$user/ssd/save/*" /mnt/disks/ssd/