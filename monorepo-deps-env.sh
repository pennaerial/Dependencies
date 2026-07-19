#!/usr/bin/env bash

# Root of the Dependencies repository.
MONOREPO_DEPENDENCIES_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# DDS_GEN_PATH. Can access the executable by using $XRCE_DDS_GEN_PATH/scripts/microxrceddsgen from anywhere
export XRCE_DDS_GEN_PATH="$MONOREPO_DEPENDENCIES_ROOT/Micro-XRCE-DDS-Gen"
