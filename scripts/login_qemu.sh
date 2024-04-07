#!/bin/bash

set -o errexit -o pipefail -o nounset
source "scripts/common.sh"
preamble

if [ ! -e "${TMP_QEMU_PID_FILE}" ]
then
    echo "Development environment is not running. Start it."
    make -s -C "${BASE_DIR}" start_env
    echo "Wait a moment before attempting login..."
    sleep "${BOOT_DURATION}"

fi

# Note: Drop return code. Although the login works it returns an non
# zero return code on exit causing the script to fail. || true prevents it.
# shellcheck disable=SC2086 # Deliberate word splitting
sshpass -f "${SSH_PASSWORD_FILE}" ssh ${SSH_OPTS} || true
