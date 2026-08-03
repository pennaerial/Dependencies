#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# update all submodules
git -C "$SCRIPT_DIR" submodule update --init --recursive

# BUILD MICRO XRCE DDS CLIENT
# Built before the Agent: the Agent's P2P profile does its own
# find_package(microxrcedds_client 2.4.3 EXACT) during configure and
# otherwise fetches/builds a redundant private copy from GitHub, so
# installing our pinned Client first lets Agent reuse it instead.
echo "Building Client..."
cd "$SCRIPT_DIR/Micro-XRCE-DDS-Client"

mkdir -p build && cd build
cmake ..
make -j"$(nproc)"
sudo make install

sudo ldconfig /usr/local/lib/

# BUILD MICRO XRCE DDS AGENT
echo "Building Agent..."
cd "$SCRIPT_DIR/Micro-XRCE-DDS-Agent"

mkdir -p build && cd build
cmake ..
make -j"$(nproc)"
sudo make install

sudo ldconfig /usr/local/lib/

# BUILD MICRO XRCE DDS GEN
echo "Building Gen..."
cd "$SCRIPT_DIR/Micro-XRCE-DDS-Gen"
./gradlew assemble

echo "Done."

echo
echo "To make these environment variables available in future shell sessions, run:"
echo "    echo 'source \"$SCRIPT_DIR/monorepo-deps-env.sh\"' >> ~/.bashrc"
echo "    source ~/.bashrc"
