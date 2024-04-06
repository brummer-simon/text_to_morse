#!/bin/bash

set -o errexit -o pipefail -o nounset
source "scripts/common.sh"
preamble
stop_qemu_if_running
setup_rust_tooling

echo "Load linux configuration..."
setup_linux_config
# shellcheck disable=SC2086 # Deliberate word splitting
make ${LINUX_MAKE_OPTS} -s menuconfig

# Copy newly created defconfig back to tracked source tree
echo "Store linux configuration..."
# shellcheck disable=SC2086 # Deliberate word splitting
make ${LINUX_MAKE_OPTS} -s savedefconfig
cp "${LINUX_BUILD_DIR}/defconfig" "${LINUX_CUSTOM_CONFIG}"
