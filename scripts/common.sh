set -o errexit -o pipefail -o nounset

# Define common variables
declare BASE_DIR
BASE_DIR="$(pwd)"
readonly BASE_DIR
readonly ENV_DIR="${BASE_DIR}/env"
readonly BUILD_DIR="${BASE_DIR}/build"

# Buildroot paths
readonly BUILDROOT_DIR="${ENV_DIR}/buildroot"

# Out of tree buildroot paths
readonly BUILDROOT_BUILD_DIR="${BUILD_DIR}/buildroot"
readonly BUILDROOT_CONFIG="${BUILDROOT_BUILD_DIR}/.config"
readonly BUILDROOT_ARTIFACT_DIR="${BUILDROOT_BUILD_DIR}/images"
readonly BUILDROOT_HOST_DIR="${BUILDROOT_BUILD_DIR}/host"
readonly BUILDROOT_HOST_BIN_DIR="${BUILDROOT_HOST_DIR}/bin"
readonly BUILDROOT_HOST_RUSTUP_DIR="${BUILDROOT_BUILD_DIR}/host_rustup"
readonly BUILDROOT_HOST_CARGO_DIR="${BUILDROOT_BUILD_DIR}/host_cargo"
readonly BUILDROOT_HOST_CARGO_BIN_DIR="${BUILDROOT_HOST_CARGO_DIR}/bin"
readonly BUILDROOT_KERNEL_BINARY="${BUILDROOT_ARTIFACT_DIR}/bzImage"
readonly BUILDROOT_ROOTFS_BINARY="${BUILDROOT_ARTIFACT_DIR}/rootfs.ext2"
readonly BUILDROOT_KERNEL_PACKAGE_INFO="${BUILDROOT_BUILD_DIR}/kernel_package_info.json"

# Out of tree kernel module paths
readonly MODULE_DIR="${BASE_DIR}/modules"
readonly MODULE_TEXT_TO_MORSE_DIR="${MODULE_DIR}/text_to_morse"

readonly MODULE_BUILD_DIR="${BUILD_DIR}/modules"
readonly MODULE_TEXT_TO_MORSE_BUILD_DIR="${MODULE_BUILD_DIR}/text_to_morse"

# Temporary files
readonly TMP_QEMU_PID_FILE="/tmp/kernel_hacking_environment.pid"

# Other paths and values
readonly BUILDROOT_CUSTOM_CONFIG="${ENV_DIR}/buildroot.config"
readonly BUILDROOT_MAKE_OPTS="-C "${BUILDROOT_DIR}" O="${BUILDROOT_BUILD_DIR}" -s"
readonly SSH_PASSWORD_FILE="${BUILDROOT_BUILD_DIR}/ssh_password"
readonly SSH_PORT="2222"
readonly SSH_OPTS="-p ${SSH_PORT} \
                   -o StrictHostKeyChecking=no \
                   -o PubkeyAuthentication=no \
                   -o PreferredAuthentications=password \
                   -o UserKnownHostsFile=/dev/null \
                   -o LogLevel=ERROR \
                      root@localhost
                   "

# Override environment variables used by used tooling
RUSTUP_HOME="${BUILDROOT_HOST_RUSTUP_DIR}"
CARGO_HOME="${BUILDROOT_HOST_CARGO_DIR}"
PATH="${BUILDROOT_HOST_BIN_DIR}:${PATH}"

# Internal functions
function abort_if_buildroot_not_cloned() {
    if [ ! -f "${BUILDROOT_DIR}/Makefile" ]
    then
        echo "Error: git repository 'buildroot' empty."\
             "Submodule might not be checked out."
        exit 1
    fi
}

function create_random_password_if_not_existing() {
    CMD="head -c 40 /dev/urandom | base64 | tr -dc _A-Z-a-z-0-9; echo;"
    if [ ! -f "${SSH_PASSWORD_FILE}" ]
    then
        eval "${CMD}" > "${SSH_PASSWORD_FILE}"

    elif [ -z "$(cat "${SSH_PASSWORD_FILE}")" ]
    then
        eval "${CMD}" > "${SSH_PASSWORD_FILE}"
    fi
}

# Exported functions
function abort_if_buildroot_was_not_built() {
    if [ ! -f "${BUILDROOT_KERNEL_BINARY}" ]
    then
        echo "Kernel binary not found at '${BUILDROOT_KERNEL_BINARY}'."\
             "It was not built. Build via 'make build_env'."
        exit 1
    fi
    if [ ! -f "${BUILDROOT_ROOTFS_BINARY}" ]
    then
        echo "Root filesystem not found at '${BUILDROOT_ROOTFS_BINARY}'."\
             "It was not built. Build via 'make build_env'."
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
    if [ "${1:-NOT_FORCE}" = "FORCE" ]
    then
        rm -f "${BUILDROOT_KERNEL_PACKAGE_INFO}"
    fi

    if [ ! -f "${BUILDROOT_KERNEL_PACKAGE_INFO}" ]
    then
        echo "Query package information of the configured linux kernel..."
        make ${BUILDROOT_MAKE_OPTS} linux-show-info > "${BUILDROOT_KERNEL_PACKAGE_INFO}"
    fi
}

function get_kernel_version() {
    if [ ! -f "${BUILDROOT_KERNEL_PACKAGE_INFO}" ]
    then
        echo "Unable to determine linux version. Call query_kernel_package_info first".
        exit 1
    fi

    cat "${BUILDROOT_KERNEL_PACKAGE_INFO}" | jq ".linux.version" | tr -d '"'
}

function get_kernel_build_dir() {
    if [ ! -f "${BUILDROOT_KERNEL_PACKAGE_INFO}" ]
    then
        echo "Unable to determine linux version. Call query_kernel_package_info first".
        exit 1
    fi

    local DIR="$(cat "${BUILDROOT_KERNEL_PACKAGE_INFO}" | jq ".linux.build_dir" | tr -d '"')"
    echo "${BUILDROOT_BUILD_DIR}/${DIR}"
}

function setup_rust_tooling() {
    echo "Prepare rust tooling compatible to linux kernel..."

    # Examine linux sources to determine the required rust toolchain / bindgen version.
    # Unpack linux sources if needed
    query_kernel_package_info
    local KERNEL_BUILD_DIR="$(get_kernel_build_dir)"
    local KERNEL_TOOL_VERSION_SCRIPT="${KERNEL_BUILD_DIR}scripts/min-tool-version.sh"

    if [ ! -x "${KERNEL_TOOL_VERSION_SCRIPT}" ]
    then
        echo "Linux sources not found. Fetch and unpack them..."
        make ${BUILDROOT_MAKE_OPTS} linux-extract
    fi

    # Extract required minimal versions
    local KERNEL_VERSION="$(get_kernel_version)"
    local MINIMUM_RUSTC_VERSION="$(${KERNEL_TOOL_VERSION_SCRIPT} rustc)"
    local MINIMUM_BINDGEN_VERSION="$(${KERNEL_TOOL_VERSION_SCRIPT} bindgen)"

    echo "Detected Linux kernel (${KERNEL_VERSION}) expects:"
    echo "    - rustc (${MINIMUM_RUSTC_VERSION})"
    echo "    - bindgen (${MINIMUM_BINDGEN_VERSION})"

    # Check rust installation
    local INSTALL_RUST="no"

    if [ ! -x "${BUILDROOT_HOST_BIN_DIR}/rustc" ]
    then
        echo "Rust toolchain not found. Install it."
        INSTALL_RUST="yes"

    elif [ ! "$(${BUILDROOT_HOST_BIN_DIR}/rustc --version | awk '{print $2}')" = "${MINIMUM_RUSTC_VERSION}" ]
    then
        echo "Rust toolchain version does not match kernel expectency. Install it."
        INSTALL_RUST="yes"

        # Cleanup: symlinks from current toolchain in host dir
        local TOOLCHAIN_BIN_DIR="$(dirname "$(rustup which rustc)")"
        for BINARY in "${TOOLCHAIN_BIN_DIR}"/*
        do
            rm -f "${BUILDROOT_HOST_BIN_DIR}/$(basename "${BINARY}")"
        done

    else
        echo "Rust toolchain (${MINIMUM_RUSTC_VERSION}) meets kernel expectency."
    fi

    if [ "${INSTALL_RUST}" = "yes" ]
    then
        # Build required rust version and link tooling it to host bin location
        rustup install ${MINIMUM_RUSTC_VERSION}
        rustup override set ${MINIMUM_RUSTC_VERSION}
        rustup component add rust-src

        local TOOLCHAIN_BIN_DIR="$(dirname "$(rustup which rustc)")"
        for BINARY in "${TOOLCHAIN_BIN_DIR}"/*
        do
            ln -sf "${BINARY}" "${BUILDROOT_HOST_BIN_DIR}"
        done
    fi

    # Check bindgen installation
    local INSTALL_BINDGEN="no"

    if [ ! -x "${BUILDROOT_HOST_BIN_DIR}/bindgen" ]
    then
        echo "Bindgen not found. Install it."
        INSTALL_BINDGEN="yes"

    elif [ ! "$(${BUILDROOT_HOST_BIN_DIR}/bindgen --version | awk '{print $2}')" = "${MINIMUM_BINDGEN_VERSION}" ]
    then
        echo "Bindgen version does not match kernel expectency. Install it."
        rm -f "${BUILDROOT_HOST_BIN_DIR}/bindgen"
        INSTALL_BINDGEN="yes"

    else
        echo "Bindgen (${MINIMUM_BINDGEN_VERSION}) meets kernel expectency."
    fi

    # Install bindgen installation
    if [ "${INSTALL_BINDGEN}" = "yes" ]
    then
        rustup run --install stable cargo install --locked --force --version "${MINIMUM_BINDGEN_VERSION}" bindgen-cli
        ln -sf "${BUILDROOT_HOST_CARGO_BIN_DIR}/bindgen" "${BUILDROOT_HOST_BIN_DIR}/bindgen"
    fi
}

function preamble() {
    # Prepare directories
    mkdir -p "${BUILD_DIR}"
    mkdir -p "${BUILDROOT_BUILD_DIR}"
    mkdir -p "${BUILDROOT_HOST_BIN_DIR}"

    # Call sanity checks valid for each script
    abort_if_buildroot_not_cloned
    create_random_password_if_not_existing

    if [ ! -e "${BUILDROOT_CONFIG}" ]
    then
        echo "Buildroot config does not exist. Create it."
        make ${BUILDROOT_MAKE_OPTS} defconfig BR2_DEFCONFIG="${BUILDROOT_CUSTOM_CONFIG}"
    fi
}

# Export symbols to outer environment
export BASE_DIR
export ENV_DIR
export BUILD_DIR

export BUILDROOT_DIR

export BUILDROOT_BUILD_DIR
export BUILDROOT_CONFIG
export BUILDROOT_ARTIFACT_DIR
export BUILDROOT_HOST_DIR
export BUILDROOT_HOST_BIN_DIR
export BUILDROOT_HOST_RUSTUP_DIR
export BUILDROOT_HOST_CARGO_DIR
export BUILDROOT_HOST_CARGO_BIN_DIR
export BUILDROOT_KERNEL_BINARY
export BUILDROOT_ROOTFS_BINARY
export BUILDROOT_KERNAL_PACKAGE_INFO

export TMP_QEMU_PID_FILE

export MODULE_DIR
export MODULE_TEXT_TO_MORSE_DIR

export MODULE_BUILD_DIR
export MODULE_TEXT_TO_MORSE_BUILD_DIR

export BUILDROOT_CUSTOM_CONFIG
export BUILDROOT_MAKE_OPTS
export SSH_PASSWORD_FILE
export SSH_PORT
export SSH_OPTS

export RUSTUP_HOME
export CARGO_HOME
export PATH

export -f preamble
export -f abort_if_buildroot_not_cloned
export -f create_random_password_if_not_existing
export -f abort_if_buildroot_was_not_built
export -f abort_if_qemu_is_not_running
export -f query_kernel_package_info
export -f get_kernel_version
export -f get_kernel_build_dir
export -f setup_rust_tooling
export -f stop_qemu_if_running
