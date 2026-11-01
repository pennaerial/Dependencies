#!/usr/bin/env bash

set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DEPENDENCIES_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"

if [[ "${1:-}" == --help || "${1:-}" == -h ]]; then
	echo "Usage: JOBS=4 ./scripts/build_microxrceagent_arm.sh"
	echo "Build a Micro XRCE-DDS Agent .deb on Ubuntu 24.04 arm64; output: dist/microxrce-agent/."
	exit 0
fi

if (($#)); then
	echo "Unexpected arguments. See --help." >&2
	exit 1
fi

# Ensure that OS and arch is Ubuntu 24.04 ARM 64
# shellcheck disable=SC1091
source /etc/os-release
if [[ "$ID" != ubuntu || "$VERSION_ID" != 24.04 || "$(dpkg --print-architecture)" != arm64 ]]; then
	echo "Build on Ubuntu 24.04 arm64 (locally or ubuntu-24.04-arm in Actions)." >&2
	exit 1
fi

JOBS="${JOBS:-4}"
[[ "$JOBS" =~ ^[1-9][0-9]*$ ]] || {
	echo "JOBS must be a positive integer." >&2
	exit 1
}

# checking installed build tools
for tool in git cmake make dpkg-buildpackage dpkg-parsechangelog dh; do
	command -v "$tool" >/dev/null || {
		echo "Missing $tool; see $DEPENDENCIES_DIR/README.md prerequisites." >&2
		exit 1
	}
done

# Checkout pinned source dir
git -C "$DEPENDENCIES_DIR" submodule update --init --recursive -- Micro-XRCE-DDS-Agent
SOURCE_DIR="$DEPENDENCIES_DIR/Micro-XRCE-DDS-Agent"
if [[ -n "$(git -C "$SOURCE_DIR" status --porcelain --untracked-files=no)" ]]; then
	echo "microxrce-agent has tracked changes; commit or stash them before packaging." >&2
	exit 1
fi

# Read the upstream version from the packaging changelog.
revision=$(git -C "$SOURCE_DIR" rev-parse HEAD)
base_version=$(dpkg-parsechangelog -l "$DEPENDENCIES_DIR/packaging/microxrce-agent/debian/changelog" -S Version)
version="${base_version%-*}"
packaging_revision="${base_version##*-}"

mkdir -p "$DEPENDENCIES_DIR/.build" "$DEPENDENCIES_DIR/dist/microxrce-agent"
work_dir=$(mktemp -d "$DEPENDENCIES_DIR/.build/microxrce-agent.XXXXXX")
echo "Building microxrce-agent $version ($revision) in $work_dir"

# Build a clean export; generated packaging never modifies the source submodule.
git -C "$SOURCE_DIR" archive HEAD | tar -x -C "$work_dir"
cp -a "$DEPENDENCIES_DIR/packaging/microxrce-agent/debian" "$work_dir/debian"
package_version="$version+git${revision:0:12}-$packaging_revision"

cat >"$work_dir/debian/changelog" <<EOF
pennair-micro-xrce-dds-agent ($package_version) noble; urgency=medium

  * Package Micro XRCE-DDS Agent revision $revision for Ubuntu 24.04 ARM64.

 -- Penn Aerial Robotics <software@pennaerial.com>  $(date -R)
EOF

chmod +x "$work_dir/debian/rules"
(cd "$work_dir" && DEB_BUILD_OPTIONS="parallel=$JOBS nocheck" dpkg-buildpackage --build=binary --no-sign)

# dpkg-buildpackage writes its outputs in the source directory's parent.
package="$DEPENDENCIES_DIR/.build/pennair-micro-xrce-dds-agent_${package_version}_arm64.deb"
cp "$package" "$DEPENDENCIES_DIR/dist/microxrce-agent/"
printf '%s\n' "$revision" >"$DEPENDENCIES_DIR/dist/microxrce-agent/source-revision.txt"
(cd "$DEPENDENCIES_DIR/dist/microxrce-agent" && sha256sum "$(basename "$package")" >SHA256SUMS)
dpkg-deb --field "$package" Package Version Architecture Depends

echo "Package ready in $DEPENDENCIES_DIR/dist/microxrce-agent; install on the Pi with apt."
