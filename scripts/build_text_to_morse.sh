#!/bin/bash

set -o errexit -o pipefail
source "scripts/common.sh"
preamble
abort_if_buildroot_was_not_built

# Query kernel build directory and execute out-of-tree build against it.
query_kernel_package_info
make KDIR="$(get_kernel_build_dir)" BUILD_DIR="${MODULE_TEXT_TO_MORSE_BUILD_DIR}" -C "${MODULE_TEXT_TO_MORSE_DIR}" modules

# TODO: FIXUP: HOSTCC Fix gcc version warning
# TODO: FIXUP: Generate Rust Analyzer Tooling
# TODO: Deploy module into virtual env
