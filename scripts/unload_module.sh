#!/bin/bash

set -o errexit -o pipefail -o nounset
source "scripts/common.sh"
preamble

if [ "${1:-"NO_PARAM"}" = "NO_PARAM" ]
then
    echo "Mandatory parameter missing. Call according the following scheme:"
    echo "./scripts/unload_module.sh <module name>"
    exit 1
fi

readonly MOD_NAME="${1}"
readonly MOD_OBJECT_NAME="${MOD_NAME}.ko"

if [ ! -e "${TMP_QEMU_PID_FILE}" ]
then
    echo "Development environment is not running. Do nothing."
    exit 0
fi

echo "Unload module '${MOD_NAME}'"

# shellcheck disable=SC2086 # Deliberate word splitting
sshpass -f "${SSH_PASSWORD_FILE}" ssh ${SSH_OPTS} "rmmod -f ${MOD_OBJECT_NAME} 2>/dev/null 1>&2 || true"

# shellcheck disable=SC2086 # Deliberate word splitting
sshpass -f "${SSH_PASSWORD_FILE}" ssh ${SSH_OPTS} "rm -f ${MOD_OBJECT_NAME}"
