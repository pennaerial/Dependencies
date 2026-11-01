#!/usr/bin/env bash
set -euo pipefail

# Runs inside a fresh Ubuntu container; only package artifacts are mounted.
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y /packages/*.deb

python3 -c 'import libcamera'
test -n "$(find /usr/share/libcamera/ipa/rpi/vc4 -name imx708.json -print -quit)"
test -n "$(find /usr/lib -name ipa_rpi_vc4.so.sign -print -quit)"
dpkg-query -W pennair-libcamera-rpi

# Check the shared libraries, Python extensions, plugins and helper executables.
mapfile -t installed_files < <(dpkg-query -L pennair-libcamera-rpi)
for path in "${installed_files[@]}"; do
    [[ -f "$path" ]] || continue
    magic=$(od -An -tx1 -N4 "$path")
    [[ "${magic//[[:space:]]/}" == 7f454c46 ]] || continue
    output=$(ldd "$path" 2>&1) || { echo "$path: $output" >&2; exit 1; }
    if [[ "$output" == *"not found"* ]]; then
        echo "$path: $output" >&2
        exit 1
    fi
done

echo "libcamera package installation and runtime dependency checks passed."
