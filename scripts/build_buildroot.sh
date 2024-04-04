#!/bin/bash

# TODO: Take architecture into account for cross-compiling
set -o errexit -o pipefail -o nounset
source "scripts/common.sh"
preamble
stop_qemu_if_running
setup_rust_tooling

# Replace empty the root password with the generated password.
KEY="BR2_TARGET_GENERIC_ROOT_PASSWD"
VALUE=$(cat "${SSH_PASSWORD_FILE}")
sed -i "s/^${KEY}=.*/${KEY}=\"${VALUE}\"/" "${BUILDROOT_CONFIG}"

# Build development environment
echo "Building 'buildroot'..."
make ${BUILDROOT_MAKE_OPTS}

echo "Built 'buildroot' successfully"
echo "Start development environment via 'make start_env'"
