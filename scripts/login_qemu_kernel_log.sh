#!/bin/bash

set -o errexit -o pipefail
source "scripts/common.sh"
preamble
abort_if_qemu_is_not_running

sshpass -f "${PASSWORD_FILE}" ssh ${SSH_OPTS} "zsh -c 'tail -f /var/log/messages'" || true
