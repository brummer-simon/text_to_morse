#!/bin/bash

set -o errexit -o pipefail
source "scripts/common.sh"
abort_if_buildroot_not_cloned
abort_if_qemu_is_not_running
create_random_password_if_not_existing

# Note: Drop return code. Although the login works it returns an non
# zero return code causing the script to fail. This prevents it.
# TODO: Refactor ssh options out. SCP might use them as well
sshpass -f "${PASSWORD_FILE}"\
    ssh -p "${SSH_PORT}"\
        -o "StrictHostKeyChecking=no"\
        -o "PubkeyAuthentication=no"\
        -o "PreferredAuthentications=password"\
        -o "UserKnownHostsFile=/dev/null"\
        -o "LogLevel ERROR"\
        root@localhost || true
