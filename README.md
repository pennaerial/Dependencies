# Dependencies

`build_all.sh` builds the DDS tools used by monorepo CI. Camera packaging is
separate: `build_libcamera.sh` builds the pinned Raspberry Pi libcamera fork
for **Pi 4B, Ubuntu 24.04, arm64**. No installation occurs on the build host.

## GitHub Actions

The workflow belongs in this repository's `.github/workflows/libcamera.yml`.
Run **Pi 4B libcamera package** in `pennaerial/Dependencies`, then download its
artifact. GitHub does not run workflows inside a monorepo's submodule. These
changes must be committed/pushed to Dependencies to run; a monorepo submodule
pointer update records that Dependencies commit separately.

The job uses `ubuntu-24.04-arm`, builds a `.deb`, and checks package installation
and Python import in a fresh Ubuntu 24.04 container. Camera capture still needs
testing on the Pi. Artifacts include the source SHA and package checksum.

## Local build

On Ubuntu 24.04 arm64, install the prerequisites and build as a normal user:

```bash
sudo apt-get update
sudo apt-get install -y devscripts equivs
sudo mk-build-deps --install --remove --tool 'apt-get -y --no-install-recommends' packaging/libcamera/debian/control
JOBS=4 ./build_libcamera.sh
```

Use `JOBS=1` for a low-memory Pi. Builds use a clean export of the libcamera
submodule and retain their working directories in `.build/` for diagnosis.
Output is in `dist/libcamera/`.

The build keeps the Python/GStreamer settings from `~/Documents/rpi.md`, but
selects VC4 only, so no Pi 5 libpisp is needed. Optional tracing, backtrace and
neural-network AWB dependencies are disabled. Debian's `dh_shlibdeps` derives
runtime library dependencies from the built ELF files; `dh_python3` adds Python
dependencies. Headers, pkg-config files, tuning data, IPA modules/signatures and
helpers are included. IPA binaries are not rewritten by dh_strip/dh_dwz after
Meson signs them. Upstream license texts are included.

## Install on the Pi

Transfer the downloaded `.deb` to the Pi, then review the proposed installation:

```bash
sudo apt-get update
sudo apt-get install --simulate ./pennair-libcamera-rpi_*.deb
sudo apt-get install ./pennair-libcamera-rpi_*.deb
```

APT installs the package's declared runtime dependencies. The Pi does not need
Meson, Ninja, a compiler, or development dependencies just to run the library.
The package installs to `/usr` and declares conflicts with distribution and
ROS Jazzy libcamera packages; review any proposed removals before proceeding.

Your notes describe an existing source installation under `/usr/local`. Before
installing this package, uninstall that build using its original install
manifest/build tree; otherwise those files can shadow the packaged library.
Do not delete whole `/usr/local/lib` or `/usr/local/share` directories.

Rebuild `camera_ros` and any `rpicam-apps` against this packaged libcamera before
using them. They are not included here. Skip the `libcamera` rosdep key when
resolving ROS dependencies so it does not reinstall a conflicting binary.
After rebuilding rpicam-apps, test `rpicam-hello --list-cameras` and a capture on
the Pi. Kernel/firmware, camera overlays and permissions remain Pi setup steps.

References: [Raspberry Pi camera documentation](https://www.raspberrypi.com/documentation/accessories/camera-software.html)
and the checked-in `libcamera/README.rst`.
