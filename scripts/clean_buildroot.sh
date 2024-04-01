#!/bin/bash

set -o errexit -o pipefail
source "scripts/common.sh"
preamble
stop_qemu_if_running

if [ ! -e "${BUILDROOT_BUILD_DIR}/Makefile" ]
then
    echo "Nothing to delete. Do nothing."
    exit 0
fi

echo -n "Rebuilding 'buildroot' takes a while."\
        "Enter 'YES' to continue deleting: "

read CONFIRM
if [ ! "${CONFIRM}" = "YES" ]
then
    echo "Aborted by user. Do nothing."
    exit 0
fi

echo "Deleting development environment..."
rm -rf "${BUILDROOT_BUILD_DIR}"
rm -rf "${PASSWORD_FILE}"
rm -rf "${TMP_QEMU_PID_FILE}"
rm -rf "${TMP_KERNEL_PACKAGE_INFO_FILE}"
