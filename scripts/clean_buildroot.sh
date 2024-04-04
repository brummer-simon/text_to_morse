#!/bin/bash

set -o errexit -o pipefail
source "scripts/common.sh"
preamble
stop_qemu_if_running

if [ ! -d "${BUILD_DIR}" ]
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
rm -rf "${BUILD_DIR}"
rm -rf "${TMP_QEMU_PID_FILE}"
