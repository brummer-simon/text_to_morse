#!/bin/bash

set -o errexit -o pipefail -o nounset
source "scripts/common.sh"
preamble
stop_qemu_if_running

# Import out-of-tree config, change it via menuconfig and export it back.
echo "Load configuration..."
make ${BUILDROOT_MAKE_OPTS} defconfig BR2_DEFCONFIG="${BUILDROOT_CUSTOM_CONFIG}"
make ${BUILDROOT_MAKE_OPTS} menuconfig

echo "Store configuration..."
make ${BUILDROOT_MAKE_OPTS} savedefconfig BR2_DEFCONFIG="${BUILDROOT_CUSTOM_CONFIG}"

query_kernel_package_info "FORCE"

