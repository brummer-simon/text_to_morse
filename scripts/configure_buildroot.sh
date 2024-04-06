#!/bin/bash

set -o errexit -o pipefail -o nounset
source "scripts/common.sh"
preamble
stop_qemu_if_running
setup_buildroot_config

# Import out-of-tree config, change it via menuconfig and export it back.
echo "Load buildroot configuration..."
# shellcheck disable=SC2086 # Deliberate word splitting
make ${BUILDROOT_MAKE_OPTS} -s menuconfig

echo "Store buildroot configuration..."
# shellcheck disable=SC2086 # Deliberate word splitting
make ${BUILDROOT_MAKE_OPTS} -s savedefconfig BR2_DEFCONFIG="${BUILDROOT_CUSTOM_CONFIG}"
