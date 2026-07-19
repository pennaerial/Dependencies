#!/usr/bin/env bash

# Root of the Dependencies repository.
MONOREPO_DEPENDENCIES_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# DDS_GEN_PATH. Can access the executable by using $XRCE_DDS_GEN_PATH/scripts/microxrceddsgen from anywhere
export XRCE_DDS_GEN_PATH="$MONOREPO_DEPENDENCIES_ROOT/Micro-XRCE-DDS-Gen"

# DDS_CLIENT_PATH. Source checkout of Micro-XRCE-DDS-Client, built per
# ESP-IDF target via ExternalProject_Add in payload_controller (its own
# ABI-sensitive cross-compile flags, e.g. -mlongcalls, must match the rest
# of the firmware) instead of relying on a host-installed copy.
export XRCE_DDS_CLIENT_PATH="$MONOREPO_DEPENDENCIES_ROOT/Micro-XRCE-DDS-Client"

# DDS_MICROCDR_PATH. Pinned Micro-CDR checkout (v2.0.1, the version
# Micro-XRCE-DDS-Client v2.4.3 requires), built the same way and installed
# to a local prefix so the Client's own find_package(microcdr) resolves it,
# without a live git fetch during the build.
export XRCE_DDS_MICROCDR_PATH="$MONOREPO_DEPENDENCIES_ROOT/Micro-CDR"
