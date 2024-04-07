#!/bin/bash

# TODO: Take architecture into account for cross-compiling
set -o errexit -o pipefail -o nounset
source "scripts/common.sh"
preamble
stop_qemu_if_running
setup_rust_tooling
setup_linux_config

case "${1:-"NO_PARAM"}" in
  "ONLY_LINUX")
    readonly BUILD_LINUX="YES"
    readonly BUILD_LINUX_RUSTDOC="NO"
    readonly BUILD_LINUX_RUSTPROJECT="NO"
    ;;

  "ONLY_LINUX_RUSTDOC")
    readonly BUILD_LINUX="NO"
    readonly BUILD_LINUX_RUSTDOC="YES"
    readonly BUILD_LINUX_RUSTPROJECT="NO"
    ;;

  "ONLY_LINUX_RUSTPROJECT")
    readonly BUILD_LINUX="NO"
    readonly BUILD_LINUX_RUSTDOC="NO"
    readonly BUILD_LINUX_RUSTPROJECT="YES"
    ;;

  *)
    readonly BUILD_LINUX="YES"
    readonly BUILD_LINUX_RUSTDOC="YES"
    readonly BUILD_LINUX_RUSTPROJECT="YES"
    ;;
esac

# Build development environment
if [ "${BUILD_LINUX}" = "YES" ]
then
    echo "Building 'linux'..."
    SECONDS=0
    # shellcheck disable=SC2086 # Deliberate word splitting
    make ${LINUX_MAKE_OPTS}

    SEC="${SECONDS}"
    DURATION="$((SEC / 3600))h $((SEC % 3600 / 60))m $((SEC % 60))s"
    echo "Built 'linux' successfully. Build took ${DURATION}"
fi

if [ "${BUILD_LINUX_RUSTDOC}" = "YES" ]
then
    echo "Creating rust documentation for 'linux sources'..."
    SECONDS=0
    # shellcheck disable=SC2086 # Deliberate word splitting
    make ${LINUX_MAKE_OPTS} rustdoc

    SEC="${SECONDS}"
    DURATION="$((SEC / 3600))h $((SEC % 3600 / 60))m $((SEC % 60))s"
    echo "Created rust documentation for 'linux sources'. Creation took ${DURATION}"
fi

if [ "${BUILD_LINUX_RUSTPROJECT}" = "YES" ]
then
    echo "Creating rust-project.json for 'linux sources'..."
    SECONDS=0
    # shellcheck disable=SC2086 # Deliberate word splitting
    make ${LINUX_MAKE_OPTS} rust-analyzer
    cp "${LINUX_BUILD_DIR}/rust-project.json" "${BASE_DIR}/rust-project.json"

    SEC="${SECONDS}"
    DURATION="$((SEC / 3600))h $((SEC % 3600 / 60))m $((SEC % 60))s"
    echo "Created rust-project.json for 'linux sources'. Creation took ${DURATION}"
fi
