#!/bin/bash

set -o errexit -o pipefail -o nounset
source "scripts/common.sh"
abort_if_buildroot_not_cloned
abort_if_linux_not_cloned
stop_qemu_if_running

if [ ! -d "${BUILD_DIR}" ]
then
    echo "Nothing to clean."
    exit 0
fi

echo -n "Rebuilding everything takes a while."\
        "Enter 'YES' to continue cleaning: "

read -r CONFIRM
if [ ! "${CONFIRM}" = "YES" ]
then
    echo "Operation aborted by user. Do nothing."
    exit 0
fi

echo "Cleaning development environment..."
rm -rf "${BUILD_DIR}"
rm -rf "${BASE_DIR}/rust-project.json"

echo "Development environment cleaned."

