#!/bin/bash

set -o errexit -o pipefail
source "scripts/common.sh"
preamble
abort_if_qemu_is_not_running

# TODO: Followup kernel log after login
#sshpass -f "${PASSWORD_FILE}" ssh ${SSH_OPTS} || true
sshpass -f "${PASSWORD_FILE}" ssh ${SSH_OPTS} "bash -l -c 'dmesg'" || true
