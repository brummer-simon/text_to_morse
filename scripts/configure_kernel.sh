#!/bin/bash

set -o errexit -o pipefail
source "scripts/common.sh"
abort_if_buildroot_not_cloned
create_random_password_if_not_existing
stop_qemu_if_running

# TODO: Prepare Rust Environment
mkdir -p "${BUILDROOT_BUILD_DIR}"

# TODO: Append path to all commands?
PATH="${BUILDROOT_HOST_BIN_DIR}:${PATH}"

cp -f "${BUILDROOT_CUSTOM_CONFIG}" "${BUILDROOT_CONFIG}"
make ${MAKE_OPTS} linux-menuconfig
