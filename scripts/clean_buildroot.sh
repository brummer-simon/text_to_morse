#!/bin/bash

set -o errexit -o pipefail -o nounset
source "scripts/common.sh"
preamble
stop_qemu_if_running

if [ ! -d "${BUILDROOT_BUILD_DIR}" ]
then
    echo "Nothing to clean."
    exit 0
fi

echo -n "Rebuilding 'buildroot' takes a while."\
        "Enter 'YES' to continue cleaning: "

read -r CONFIRM
if [ ! "${CONFIRM}" = "YES" ]
then
    echo "Operation aborted by user. Do nothing."
    exit 0
fi

echo "Cleaning buildroot..."
rm -rf "${BUILDROOT_BUILD_DIR}"

echo "Buildroot cleaned."
