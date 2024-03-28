#!/bin/bash
set -o errexit -o pipefail

# TODO: Add versions for rust installment, bindgen and kernel
# TODO: buildroot: 2024-02
# TODO: kernel: 6.6.18
# TODO: rustc: 1.73.0
# TODO: bindgen: 0.65.1

# Define common variables
declare WORK_DIR
WORK_DIR="$(pwd)"
readonly WORK_DIR

# Buildroot paths
readonly BUILDROOT_DIR="${WORK_DIR}/buildroot"
readonly BUILDROOT_DOWNLOAD_DIR="${BUILDROOT_DIR}/dl"

# Out of tree buildroot paths
readonly BUILDROOT_BUILD_DIR="${WORK_DIR}/buildroot_build"
readonly BUILDROOT_CONFIG="${BUILDROOT_BUILD_DIR}/.config"
readonly BUILDROOT_ARTIFACT_DIR="${BUILDROOT_BUILD_DIR}/images"
readonly BUILDROOT_HOST_DIR="${BUILDROOT_BUILD_DIR}/host"
readonly BUILDROOT_HOST_BIN_DIR="${BUILDROOT_HOST_DIR}/bin"

# Temporary files
readonly TMP_QEMU_PID_FILE="/tmp/kernel_hacking_environment.pid"
readonly TMP_KERNEL_PACKAGE_INFO_FILE="/tmp/kernel_package_info.json"

# Other paths and values
readonly BUILDROOT_CUSTOM_CONFIG="${WORK_DIR}/buildroot.config"
readonly PASSWORD_FILE="${WORK_DIR}/.env_password"
readonly MAKE_OPTS="-C "${BUILDROOT_DIR}" O="${BUILDROOT_BUILD_DIR}" -s"
readonly SSH_PORT="2222"

# Define common functions
function abort_if_buildroot_not_cloned() {
    if [ ! -f "${BUILDROOT_DIR}/Makefile" ]
    then
        echo "Error: git repository 'buildroot' empty."\
             "Submodule might not be checked out."
        exit 1
    fi
}

function abort_if_qemu_is_not_running() {
    if [ ! -e "${TMP_QEMU_PID_FILE}" ]
    then
        echo "Virtual linux environment not running."\
             "Start it via 'make start_env'"
        exit 1
    fi
}

function create_random_password_if_not_existing() {
    CMD="head -c 40 /dev/urandom | base64 | tr -dc _A-Z-a-z-0-9; echo;"
    if [ ! -f "${PASSWORD_FILE}" ]
    then
        eval "${CMD}" > "${PASSWORD_FILE}"

    elif [ -z "$(cat "${PASSWORD_FILE}")" ]
    then
        eval "${CMD}" > "${PASSWORD_FILE}"
    fi
}

function stop_qemu_if_running() {
    if [ -e "${TMP_QEMU_PID_FILE}" ]
    then
        PID=$(cat "${TMP_QEMU_PID_FILE}")

        echo "Stop virtual linux environment (pid=${PID})."
        kill -2 "${PID}"
        rm -rf "${TMP_QEMU_PID_FILE}"
    fi
}

function query_kernel_package_info() {
    if [ ! -f "${TMP_KERNEL_PACKAGE_INFO_FILE}" ]
    then
        echo "Query package information of the configured linux kernel."
        make ${MAKE_OPTS} linux-show-info > "${TMP_KERNEL_PACKAGE_INFO_FILE}"
    fi
}

function get_kernel_version() {
    query_kernel_package_info

    cat "${TMP_KERNEL_PACKAGE_INFO_FILE}" | jq ".linux.version" | tr -d '"'
}

function get_kernel_build_dir() {
    query_kernel_package_info

    DIR="$(cat "${TMP_KERNEL_PACKAGE_INFO_FILE}" | jq ".linux.build_dir" | tr -d '"')"
    echo "${BUILDROOT_BUILD_DIR}/${DIR}"
}

# Export symbols to outer environment
export WORK_DIR
export BUILDROOT_DIR
export BUILDROOT_DOWNLOAD_DIR

export BUILDROOT_BUILD_DIR
export BUILDROOT_CONFIG
export BUILDROOT_ARTIFACT_DIR
export BUILDROOT_HOST_DIR
export BUILDROOT_HOST_BIN_DIR

export TMP_QEMU_PID_FILE
export TMP_KERNEL_PACKAGE_INFO_FILE

export BUILDROOT_CUSTOM_CONFIG
export PASSWORD_FILE
export MAKE_OPTS
export SSH_PORT

export -f abort_if_buildroot_not_cloned
export -f abort_if_qemu_is_not_running
export -f create_random_password_if_not_existing
export -f stop_qemu_if_running
export -f get_kernel_version
export -f get_kernel_build_dir
