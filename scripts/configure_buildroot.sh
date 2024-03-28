#!/bin/bash

set -o errexit -o pipefail
source "scripts/common.sh"
abort_if_buildroot_not_cloned
create_random_password_if_not_existing
stop_qemu_if_running

# Import out-of-tree config, change it via menuconfig and export it back.
mkdir -p "${BUILDROOT_BUILD_DIR}"
cp -f "${BUILDROOT_CUSTOM_CONFIG}" "${BUILDROOT_CONFIG}"

# TODO: Prepare Rust Environment
make ${MAKE_OPTS} menuconfig
cp -f "${BUILDROOT_CONFIG}" "${BUILDROOT_CUSTOM_CONFIG}"
