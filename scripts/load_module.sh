#!/bin/bash

set -o errexit -o pipefail -o nounset
source "scripts/common.sh"
preamble
abort_if_linux_was_not_built

# Sanity checks
if [ "${1:-"NO_PARAM"}" = "NO_PARAM" ]
then
    echo "Mandatory parameter missing. Call according the following scheme:"
    echo "./scripts/load_module.sh <module name>"
    exit 1
fi

readonly MOD_NAME="${1}"
readonly MOD_OBJECT_NAME="${MOD_NAME}.ko"
readonly MOD_KERNEL_OBJECT="${MODULE_BUILD_DIR}/${MOD_NAME}/${MOD_OBJECT_NAME}"

if [ ! -e "${MOD_KERNEL_OBJECT}" ]
then
    echo "Unable to find kernel module at '${MOD_KERNEL_OBJECT}'."
    exit 1
fi

if [ ! -e "${TMP_QEMU_PID_FILE}" ]
then
    echo "Development environment is not running. Start it."
    make -s -C "${BASE_DIR}" start_env
    echo "Wait a moment before attempting login..."
    sleep "${BOOT_DURATION}"
fi

# shellcheck disable=SC2086 # Deliberate word splitting
sshpass -f "${SSH_PASSWORD_FILE}" ssh ${SSH_OPTS} "rmmod -f ${MOD_OBJECT_NAME} 2>/dev/null 1>&2 || true"

echo "Deploy module '${MOD_NAME}'"
# shellcheck disable=SC2086 # Deliberate word splitting
sshpass -f "${SSH_PASSWORD_FILE}" scp ${SCP_OPTS} "${MOD_KERNEL_OBJECT}" "${SSH_TARGET}:~"

echo "Load/reload module '${MOD_NAME}'"
# shellcheck disable=SC2086 # Deliberate word splitting
sshpass -f "${SSH_PASSWORD_FILE}" ssh ${SSH_OPTS} "insmod ${MOD_OBJECT_NAME}"
