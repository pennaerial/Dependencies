# Dependencies

Run `./build_all.sh` to build and install the DDS tools.

## libcamera — Pi 4B / Ubuntu 24.04 ARM64

The [workflow](.github/workflows/libcamera.yml) builds the pinned Raspberry Pi
fork, tests the package in a fresh Ubuntu container, and publishes successful
`main` builds to the latest GitHub Release. Camera capture must be tested on
the Pi. Includes `cam` with DRM/KMS preview support (no desktop required).
Use `cam -l` to list cameras, `cam -c 1 --capture=10 --file` for headless
capture, or `cam -c 1 --capture --display` with a locally connected monitor.

### Build locally

Run from this directory on Ubuntu 24.04 ARM64:

```bash
sudo apt-get update
sudo apt-get install -y devscripts equivs
sudo mk-build-deps --install --remove --tool 'apt-get -y --no-install-recommends' packaging/libcamera/debian/control
JOBS=4 ./scripts/build_libcamera_arm.sh
```

Output: `dist/libcamera/`. Use `JOBS=1` on low-memory devices.

### Install on the Pi

```bash
curl -fL -o libcamera-pi4-noble-arm64.tar.gz \
  https://github.com/pennaerial/Dependencies/releases/latest/download/libcamera-pi4-noble-arm64.tar.gz
mkdir -p libcamera-package
tar -xzf libcamera-pi4-noble-arm64.tar.gz -C libcamera-package
cd libcamera-package
sha256sum -c SHA256SUMS
sudo apt-get update
sudo apt-get install --simulate ./pennair-libcamera-rpi_*.deb
sudo apt-get install ./pennair-libcamera-rpi_*.deb
```

`SHA256SUMS` verifies the package checksum; `source-revision.txt` records the
libcamera source commit. APT installs runtime dependencies.

Before installing, uninstall any previous source build from `/usr/local` using
its original build tree, and review APT's proposed package removals. Rebuild
`camera_ros` and any installed `rpicam-apps` against the new library. Use
`--skip-keys=libcamera` when running rosdep for this setup.
