#!/bin/bash

set -o errexit -o pipefail -o nounset
source "scripts/common.sh"
preamble
abort_if_qemu_is_not_running

# shellcheck disable=SC2086 # Deliberate word splitting
sshpass -f "${SSH_PASSWORD_FILE}" ssh ${SSH_OPTS} "zsh -c 'tail -f /var/log/messages'" || true
