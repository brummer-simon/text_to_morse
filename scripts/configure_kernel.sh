#!/bin/bash

set -o errexit -o pipefail
source "scripts/common.sh"
preamble
stop_qemu_if_running
setup_rust_tooling

make ${MAKE_OPTS} linux-menuconfig
