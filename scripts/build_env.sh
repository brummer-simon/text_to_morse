#!/bin/bash
#
set -o errexit -o pipefail -o nounset
source "scripts/common.sh"
preamble

echo "Building 'environment'..."
SECONDS=0

make -s -C "${BASE_DIR}" build_buildroot
make -s -C "${BASE_DIR}" build_linux
make -s -C "${BASE_DIR}" build_module

readonly SEC="${SECONDS}"
readonly DURATION="$((SEC / 3600))h $((SEC % 3600 / 60))m $((SEC % 60))s"
echo "Built 'environment' successfully. Build took ${DURATION}"
