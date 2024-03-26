#!/bin/bash

set -o errexit -o pipefail
source "scripts/common.sh"
abort_if_buildroot_not_cloned
create_random_password_if_not_existing
stop_qemu_if_running

echo "Configure 'buildroot' from '${BUILDROOT_CUSTOM_CONFIG}'"
mkdir -p "${BUILDROOT_BUILD_DIR}"
cp -f "${BUILDROOT_CUSTOM_CONFIG}" "${BUILDROOT_CONFIG}"

# Replace empty the root password with the password from the local file.
KEY="BR2_TARGET_GENERIC_ROOT_PASSWD"
VALUE=$(cat "${PASSWORD_FILE}")
sed -i "s/^${KEY}=.*/${KEY}=\"${VALUE}\"/" "${BUILDROOT_CONFIG}"

# Build development environment
echo "Building 'buildroot'..."
make -C "${BUILDROOT_DIR}" O="${BUILDROOT_BUILD_DIR}"

echo "Built 'buildroot' successfully"
echo "Start development environment via 'make start_env'"
