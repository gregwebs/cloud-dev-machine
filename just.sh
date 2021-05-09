#!/usr/bin/env bash
set -euo pipefail

which just >/dev/null && exec just "$@"
curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to .
exec just "$@"