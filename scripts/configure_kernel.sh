#!/bin/bash

set -o errexit -o pipefail -o nounset
source "scripts/common.sh"
preamble
stop_qemu_if_running
setup_rust_tooling

make ${BUILDROOT_MAKE_OPTS} linux-menuconfig
make ${BUILDROOT_MAKE_OPTS} linux-update-defconfig
