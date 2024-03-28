#!/bin/bash

# TODO: Take architecture into account for cross-compiling

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

# Extract expected rust tooling versions from configured linux kernel
# Unpack sources if not already done
echo "Examine linux sources to determine required rust tooling..."
KERNEL_BUILD_DIR="$(get_kernel_build_dir)"
KERNEL_TOOL_VERSION_SCRIPT="${KERNEL_BUILD_DIR}/scripts/min-tool-version.sh"

if [ ! -x "${KERNEL_TOOL_VERSION_SCRIPT}" ]
then
    echo "Extracting linux sources..."
    make ${MAKE_OPTS} linux-extract
fi

KERNEL_VERSION="$(get_kernel_version)"
MINIMUM_RUSTC_VERSION="$(${KERNEL_TOOL_VERSION_SCRIPT} rustc)"
MINIMUM_BINDGEN_VERSION="$(${KERNEL_TOOL_VERSION_SCRIPT} bindgen)"

echo "Detected Linux kernel (${KERNEL_VERSION}) expects:"
echo "    - rustc (>= ${MINIMUM_RUSTC_VERSION}))"
echo "    - bindgen (>= ${MINIMUM_BINDGEN_VERSION}))"

echo "Configure rust toolchain..."
# TODO: Use different rust settings
RUST_TOOLCHAIN="$(rustup show active-toolchain)"

if [[ "${RUST_TOOLCHAIN}" == "${MINIMUM_RUSTC_VERSION}"* ]]
then
    echo "Matching rust toolchain found. Do nothing."
else
    echo "Matching rust toolchain not found. Install toolchain rustup"\
         "and add directory override"
    rustup install --profile complete "${MINIMUM_RUSTC_VERSION}"
    rustup override set "${MINIMUM_RUSTC_VERSION}"
fi

echo "Configure bindgen..."
BINDGEN_PATH="${BUILDROOT_HOST_BIN_DIR}/bindgen"

if [ ! -x "${BINDGEN_PATH}" ]
then
    echo "Bindgen not found in ${BINDGEN_PATH}. Build and install it!"
    cargo +stable install --version "${MINIMUM_BINDGEN_VERSION}" --root "${BUILDROOT_HOST_DIR}" bindgen-cli
fi

# TODO: Bindgen exists. Check version and force rebuild if not matching

# Build development environment
echo "Building 'buildroot'..."
#make ${MAKE_OPTS}

echo "Built 'buildroot' successfully"
echo "Start development environment via 'make start_env'"
