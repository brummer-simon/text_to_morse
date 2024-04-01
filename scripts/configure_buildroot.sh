#!/bin/bash

set -o errexit -o pipefail
source "scripts/common.sh"
preamble
stop_qemu_if_running

# Import out-of-tree config, change it via menuconfig and export it back.
make ${MAKE_OPTS} menuconfig
cp -f "${BUILDROOT_CONFIG}" "${BUILDROOT_CUSTOM_CONFIG}"
