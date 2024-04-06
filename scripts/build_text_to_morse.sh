#!/bin/bash

set -o errexit -o pipefail -o nounset
source "scripts/common.sh"
preamble
abort_if_linux_was_not_built

# Build out-of-tree kernel module against built kernel.
echo "Building module 'text_to_morse'..."
SECONDS=0

# shellcheck disable=SC2086 # Deliberate word splitting
make ${MODULE_MAKE_OPTS} BUILDDIR="${MODULE_TEXT_TO_MORSE_BUILD_DIR}" -C "${MODULE_TEXT_TO_MORSE_DIR}" modules

readonly SEC="${SECONDS}"
readonly DURATION="$((SEC / 3600))h $((SEC % 3600 / 60))m $((SEC % 60))s"
echo "Built module 'text_to_morse' successfully. Build took ${DURATION}"

# TODO: Deploy module into virtual env
# TODO: FIXUP: Generate Rust Analyzer Tooling
