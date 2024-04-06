#!/bin/bash

set -o errexit -o pipefail -o nounset
source "scripts/common.sh"
preamble
abort_if_linux_was_not_built

# Query kernel build directory and execute out-of-tree build against it.
echo "Clean module text_to_morse..."
make ${MODULE_MAKE_OPTS} BUILDDIR="${MODULE_TEXT_TO_MORSE_BUILD_DIR}" -C "${MODULE_TEXT_TO_MORSE_DIR}" clean

echo "Module text_to_morse cleaned."
