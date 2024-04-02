#!/bin/bash

# TODO: Take architecture into account for cross-compiling
# TODO: Analyize objtool error at the end of the build? Objtool could be disabled with option: CONFIG_STACK_VALIDATION=n
# TODO: Build linux kernel with LLVM support? See: https://www.linuxembedded.fr/2019/08/my-first-linux-kernel-built-with-clang-compiler

set -o errexit -o pipefail
source "scripts/common.sh"
preamble
stop_qemu_if_running
setup_rust_tooling

# Replace empty the root password with the password from the local file.
KEY="BR2_TARGET_GENERIC_ROOT_PASSWD"
VALUE=$(cat "${PASSWORD_FILE}")
sed -i "s/^${KEY}=.*/${KEY}=\"${VALUE}\"/" "${BUILDROOT_CONFIG}"

# Build development environment
echo "Building 'buildroot'..."
make ${MAKE_OPTS}

echo "Built 'buildroot' successfully"
echo "Start development environment via 'make start_env'"
