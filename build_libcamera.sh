#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
if [[ "${1:-}" == --help || "${1:-}" == -h ]]; then
    echo "Usage: JOBS=4 ./build_libcamera.sh"
    echo "Build a Pi 4B libcamera .deb on Ubuntu 24.04 arm64; output: dist/libcamera/."
    exit 0
fi
if (( $# )); then
    echo "Unexpected arguments. See --help." >&2
    exit 1
fi
# shellcheck disable=SC1091
source /etc/os-release
if [[ "$ID" != ubuntu || "$VERSION_ID" != 24.04 || "$(dpkg --print-architecture)" != arm64 ]]; then
    echo "Build on Ubuntu 24.04 arm64 (locally or ubuntu-24.04-arm in Actions)." >&2
    exit 1
fi
JOBS="${JOBS:-4}"
[[ "$JOBS" =~ ^[1-9][0-9]*$ ]] || { echo "JOBS must be a positive integer." >&2; exit 1; }
for tool in git meson ninja dpkg-buildpackage dh; do
    command -v "$tool" >/dev/null || { echo "Missing $tool; see README.md prerequisites." >&2; exit 1; }
done
# Initialize only the recorded camera source revision, never --remote.
git -C "$SCRIPT_DIR" submodule update --init --recursive -- libcamera
SOURCE_DIR="$SCRIPT_DIR/libcamera"
if [[ -n "$(git -C "$SOURCE_DIR" status --porcelain --untracked-files=no)" ]]; then
    echo "libcamera has tracked changes; commit or stash them before packaging." >&2
    exit 1
fi
revision=$(git -C "$SOURCE_DIR" rev-parse HEAD)
version=$(sed -n "s/^[[:space:]]*version : '\([^']*\)',/\1/p" "$SOURCE_DIR/meson.build")
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "Cannot determine libcamera version." >&2; exit 1; }
mkdir -p "$SCRIPT_DIR/.build" "$SCRIPT_DIR/dist/libcamera"
work_dir=$(mktemp -d "$SCRIPT_DIR/.build/libcamera.XXXXXX")
echo "Building libcamera $version ($revision) in $work_dir"
# Build a clean export; generated packaging never modifies the source submodule.
git -C "$SOURCE_DIR" archive HEAD | tar -x -C "$work_dir"
cp -a "$SCRIPT_DIR/packaging/libcamera/debian" "$work_dir/debian"
package_version="$version+git${revision:0:12}-1~noble"
cat > "$work_dir/debian/changelog" <<EOF
pennair-libcamera-rpi ($package_version) noble; urgency=medium

  * Package Raspberry Pi VC4 libcamera revision $revision for Pi 4B.

 -- Penn Aerial Robotics <software@pennaerial.com>  $(date -R)
EOF
chmod +x "$work_dir/debian/rules"
(cd "$work_dir" && DEB_BUILD_OPTIONS="parallel=$JOBS nocheck" dpkg-buildpackage --build=binary --no-sign)
# dpkg-buildpackage writes its outputs in the source directory's parent.
package="$SCRIPT_DIR/.build/pennair-libcamera-rpi_${package_version}_arm64.deb"
cp "$package" "$SCRIPT_DIR/dist/libcamera/"
printf '%s\n' "$revision" > "$SCRIPT_DIR/dist/libcamera/source-revision.txt"
(cd "$SCRIPT_DIR/dist/libcamera" && sha256sum "$(basename "$package")" > SHA256SUMS)
dpkg-deb --field "$package" Package Version Architecture Depends
echo "Package ready in $SCRIPT_DIR/dist/libcamera; install on the Pi with apt."
