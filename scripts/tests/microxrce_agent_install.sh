#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends /packages/pennair-micro-xrce-dds-agent_*_arm64.deb
# Upstream 2.4.3 returns 1 after displaying help.
help_status=0
help_output=$(MicroXRCEAgent --help 2>&1) || help_status=$?
printf '%s\n' "$help_output"
if ((help_status > 1)) || [[ "$help_output" != *"Usage:"* || "$help_output" != *"--baudrate"* ]]; then
    echo "Agent help check failed (exit $help_status)." >&2
    exit 1
fi
dependencies=$(ldd /usr/bin/MicroXRCEAgent)
printf '%s\n' "$dependencies"
if [[ "$dependencies" == *"not found"* ]]; then
    echo "Agent has missing runtime libraries." >&2
    exit 1
fi
echo "Micro XRCE-DDS Agent installation and startup checks passed."
