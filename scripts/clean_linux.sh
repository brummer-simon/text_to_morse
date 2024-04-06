#!/bin/bash

set -o errexit -o pipefail -o nounset
source "scripts/common.sh"
preamble
stop_qemu_if_running

if [ ! -d "${LINUX_BUILD_DIR}" ]
then
    echo "Noting to clean."
    exit 0
fi

echo -n "Rebuilding 'linux' takes a while."\
        "Enter 'YES' to continue cleaning: "

read CONFIRM
if [ ! "${CONFIRM}" = "YES" ]
then
    echo "Operation aborted by user. Do nothing."
    exit 0
fi

echo "Clean linux..."
rm -rf "${LINUX_BUILD_DIR}"

echo "Linux cleaned."
