#!/bin/bash

set -o errexit -o pipefail -o nounset
source "scripts/common.sh"
preamble
abort_if_qemu_is_not_running

# Note: Drop return code. Although the login works it returns an non
# zero return code on exit causing the script to fail. || true prevents it.
# shellcheck disable=SC2086 # Deliberate word splitting
sshpass -f "${SSH_PASSWORD_FILE}" ssh ${SSH_OPTS} || true
