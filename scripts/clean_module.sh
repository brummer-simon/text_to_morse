#!/bin/bash

set -o errexit -o pipefail -o nounset
source "scripts/common.sh"
preamble
abort_if_linux_was_not_built

# Sanity checks
if [ "${1:-"NO_PARAM"}" = "NO_PARAM" ]
then
    echo "Mandatory parameter missing. Call according the following scheme:"
    echo "./scripts/clean_module.sh <module name>"
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

if [ ! -d "${MOD_BUILD_DIR}" ]
then
    echo "Nothing to clean."
    exit 0
fi

echo "Clean module '${MOD_NAME}'..."
# shellcheck disable=SC2086 # Deliberate word splitting
make ${MODULE_MAKE_OPTS} MOD_NAME="${MOD_NAME}" MOD_BUILD_DIR="${MOD_BUILD_DIR}" -C "${MOD_SRC_DIR}" clean
rm -r "${MOD_BUILD_DIR}"

echo "Module '${MOD_NAME}' cleaned."
