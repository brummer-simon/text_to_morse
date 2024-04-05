#!/bin/bash

# TODO: Take architecture into account for cross-compiling
set -o errexit -o pipefail -o nounset
source "scripts/common.sh"
preamble
stop_qemu_if_running
setup_linux_config

# Build development environment
echo "Building 'linux'..."
make ${LINUX_MAKE_OPTS}

echo "Built 'linux' successfully"
