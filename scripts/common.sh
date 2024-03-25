#!/bin/bash
set -o errexit -o pipefail

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
readonly BUILDROOT_BINARY_DIR="${BUILDROOT_BUILD_DIR}/host/bin"

# Other paths and values
readonly BUILDROOT_CUSTOM_CONFIG="${WORK_DIR}/buildroot.config"
readonly QEMU_PID_FILE="/tmp/kernel_hacking_environment.pid"
readonly PASSWORD_FILE="${WORK_DIR}/.env_password"
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
    if [ ! -e "${QEMU_PID_FILE}" ]
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
    if [ -e "${QEMU_PID_FILE}" ]
    then
        PID=$(cat "${QEMU_PID_FILE}")

        echo "Stop virtual linux environment (pid=${PID})."
        kill -2 "${PID}"
        rm -rf "${QEMU_PID_FILE}"
    fi
}

# Export symbols to outer environment
export WORK_DIR
export BUILDROOT_DIR
export BUILDROOT_DOWNLOAD_DIR

export BUILDROOT_BUILD_DIR
export BUILDROOT_CONFIG
export BUILDROOT_ARTIFACT_DIR
export BUILDROOT_BINARY_DIR

export BUILDROOT_CUSTOM_CONFIG
export QEMU_PID_FILE
export PASSWORD_FILE
export SSH_PORT

export -f abort_if_buildroot_not_cloned
export -f abort_if_qemu_is_not_running
export -f create_random_password_if_not_existing
export -f stop_qemu_if_running
