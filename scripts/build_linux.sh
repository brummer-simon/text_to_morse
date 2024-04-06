#!/bin/bash

# TODO: Take architecture into account for cross-compiling
set -o errexit -o pipefail -o nounset
source "scripts/common.sh"
preamble
stop_qemu_if_running
setup_linux_config

# Build development environment
echo "Building 'linux'..."
SECONDS=0
make ${LINUX_MAKE_OPTS}
readonly SEC="${SECONDS}"
readonly DURATION="$((SEC / 3600))h $((SEC % 3600 / 60))m $((SEC % 60))s"
echo "Built 'linux' successfully. Build took ${DURATION}"
