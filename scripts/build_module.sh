#!/bin/bash

set -o errexit -o pipefail -o nounset
source "scripts/common.sh"
preamble
abort_if_linux_was_not_built
setup_rust_tooling
setup_linux_config

# Sanity checks
if [ "${1:-"NO_PARAM"}" = "NO_PARAM" ]
then
    echo "Mandatory parameter missing. Call according the following scheme:"
    echo "./scripts/build_module.sh <module name>"
    exit 1
fi

readonly MOD_NAME="${1}"
readonly MOD_SRC_DIR="${MODULE_DIR}/${MOD_NAME}"
readonly MOD_BUILD_DIR="${MODULE_BUILD_DIR}/${MOD_NAME}"

if [ ! -d "${MOD_SRC_DIR}" ]
then
    echo "Kernel module sources not found at '${MOD_SRC_DIR}'. Create it."
    exit 1
fi

echo "Building module '${MOD_NAME}'..."
SECONDS=0

# shellcheck disable=SC2086 # Deliberate word splitting
make ${MODULE_MAKE_OPTS} MOD_NAME="${MOD_NAME}" MOD_BUILD_DIR="${MOD_BUILD_DIR}" -C "${MOD_SRC_DIR}" modules

readonly SEC="${SECONDS}"
readonly DURATION="$((SEC / 3600))h $((SEC % 3600 / 60))m $((SEC % 60))s"
echo "Built module '${MOD_NAME}' successfully. Build took ${DURATION}"

# TODO: Make this work?
# shellcheck disable=SC2086 # Deliberate word splitting
make ${MODULE_MAKE_OPTS} MOD_NAME="${MOD_NAME}" MOD_BUILD_DIR="${MOD_BUILD_DIR}" -C "${MOD_SRC_DIR}" rustfmt
# TODO: Deploy module into virtual env
