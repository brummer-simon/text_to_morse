#!/bin/bash

set -o errexit -o pipefail -o nounset
source "scripts/common.sh"
preamble
stop_qemu_if_running
setup_rust_tooling
setup_linux_config

readonly KERNEL_INDEX="rust/doc/kernel/index.html"
readonly RUSTDOC_INDEX_HTML="${LINUX_BUILD_DIR}/${KERNEL_INDEX}"

if [ ! -f "${RUSTDOC_INDEX_HTML}" ]
then
    echo "Linux rustdoc not found. Build it."
    make -s -C "${BASE_DIR}" build_linux_rustdoc
fi

xdg-open "${RUSTDOC_INDEX_HTML}" 2>/dev/null 1>&2
