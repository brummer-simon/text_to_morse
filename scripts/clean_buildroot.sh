#!/bin/bash

set -o errexit -o pipefail
source "scripts/common.sh"
abort_if_buildroot_not_cloned
create_random_password_if_not_existing
stop_qemu_if_running

if [ ! -d "${BUILDROOT_BUILD_DIR}" ]
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
