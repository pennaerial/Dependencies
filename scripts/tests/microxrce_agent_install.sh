#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends /packages/pennair-micro-xrce-dds-agent_*_arm64.deb
MicroXRCEAgent --help
dependencies=$(ldd /usr/bin/MicroXRCEAgent)
printf '%s\n' "$dependencies"
if [[ "$dependencies" == *"not found"* ]]; then
    echo "Agent has missing runtime libraries." >&2
    exit 1
fi
echo "Micro XRCE-DDS Agent installation and startup checks passed."
