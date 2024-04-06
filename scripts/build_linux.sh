#!/bin/bash

# TODO: Take architecture into account for cross-compiling
set -o errexit -o pipefail -o nounset
source "scripts/common.sh"
preamble
stop_qemu_if_running
setup_rust_tooling
setup_linux_config

# Build development environment
echo "Building 'linux'..."
SECONDS=0

# shellcheck disable=SC2086 # Deliberate word splitting
make ${LINUX_MAKE_OPTS}

readonly SEC="${SECONDS}"
readonly DURATION="$((SEC / 3600))h $((SEC % 3600 / 60))m $((SEC % 60))s"
echo "Built 'linux' successfully. Build took ${DURATION}"
