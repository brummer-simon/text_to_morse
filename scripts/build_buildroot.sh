#!/bin/bash

# TODO: Take architecture into account for cross-compiling
set -o errexit -o pipefail -o nounset
source "scripts/common.sh"
preamble
stop_qemu_if_running
setup_buildroot_config

# Replace empty the root password with the generated password.
KEY="BR2_TARGET_GENERIC_ROOT_PASSWD"
VALUE=$(cat "${SSH_PASSWORD_FILE}")
sed -i "s/^${KEY}=.*/${KEY}=\"${VALUE}\"/" "${BUILDROOT_CONFIG}"

# Build development environment
echo "Building 'buildroot'..."
SECONDS=0
make ${BUILDROOT_MAKE_OPTS}
readonly SEC="${SECONDS}"
readonly DURATION="$((SEC / 3600))h $((SEC % 3600 / 60))m $((SEC % 60))s"
echo "Built 'buildroot' successfully. Build took ${DURATION}"

# Strip password from config file to prevent ending up in
# version controlled buildroot.config after reconfiguration
sed -i "s/^${KEY}=\"${VALUE}\"/${KEY}=\"\"/" "${BUILDROOT_CONFIG}"
