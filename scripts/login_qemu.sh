#!/bin/bash

set -o errexit -o pipefail
source "scripts/common.sh"
preamble
abort_if_qemu_is_not_running

# Note: Drop return code. Although the login works it returns an non
# zero return code on exit causing the script to fail. || true prevents it.
sshpass -f "${SSH_PASSWORD_FILE}" ssh ${SSH_OPTS} || true
