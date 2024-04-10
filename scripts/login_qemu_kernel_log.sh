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

# shellcheck disable=SC2086 # Deliberate word splitting
TERM=linux sshpass -f "${SSH_PASSWORD_FILE}" ssh ${SSH_OPTS} "zsh -c 'tail -f /var/log/messages'" || true
