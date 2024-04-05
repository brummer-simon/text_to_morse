#!/bin/bash

set -o errexit -o pipefail -o nounset
source "scripts/common.sh"
preamble
abort_if_linux_was_not_built

# Build out-of-tree kernel module against built kernel.
make \
    ${MODULE_MAKE_OPTS} BUILDDIR="${MODULE_TEXT_TO_MORSE_BUILD_DIR}" -C "${MODULE_TEXT_TO_MORSE_DIR}" modules

# TODO: FIXUP: Generate Rust Analyzer Tooling
# TODO: Deploy module into virtual env
