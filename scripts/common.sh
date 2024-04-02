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
readonly BUILDROOT_HOST_DIR="${BUILDROOT_BUILD_DIR}/host"
readonly BUILDROOT_HOST_BIN_DIR="${BUILDROOT_HOST_DIR}/bin"
readonly BUILDROOT_HOST_RUSTUP_DIR="${BUILDROOT_HOST_DIR}/rustup"
readonly BUILDROOT_HOST_CARGO_DIR="${BUILDROOT_HOST_DIR}/cargo"
readonly BUILDROOT_HOST_CARGO_BIN_DIR="${BUILDROOT_HOST_CARGO_DIR}/bin"

# Temporary files
readonly TMP_QEMU_PID_FILE="/tmp/kernel_hacking_environment.pid"
readonly TMP_KERNEL_PACKAGE_INFO_FILE="/tmp/kernel_package_info.json"

# Other paths and values
readonly BUILDROOT_CUSTOM_CONFIG="${WORK_DIR}/buildroot.config"
readonly PASSWORD_FILE="${WORK_DIR}/.env_password"
readonly MAKE_OPTS="-C "${BUILDROOT_DIR}" O="${BUILDROOT_BUILD_DIR}" -s"
readonly SSH_PORT="2222"
readonly SSH_OPTS="-p ${SSH_PORT} \
                   -o StrictHostKeyChecking=no \
                   -o PubkeyAuthentication=no \
                   -o PreferredAuthentications=password \
                   -o UserKnownHostsFile=/dev/null \
                   -o LogLevel=ERROR \
                      root@localhost
                   "

# Update path an other vital environment variables
RUSTUP_HOME="${BUILDROOT_HOST_RUSTUP_DIR}"
CARGO_HOME="${BUILDROOT_HOST_CARGO_DIR}"

PATH="${BUILDROOT_HOST_BIN_DIR}:${PATH}"

# Internal functions
function _abort_if_buildroot_not_cloned() {
    if [ ! -f "${BUILDROOT_DIR}/Makefile" ]
    then
        echo "Error: git repository 'buildroot' empty."\
             "Submodule might not be checked out."
        exit 1
    fi
}

function _create_random_password_if_not_existing() {
    CMD="head -c 40 /dev/urandom | base64 | tr -dc _A-Z-a-z-0-9; echo;"
    if [ ! -f "${PASSWORD_FILE}" ]
    then
        eval "${CMD}" > "${PASSWORD_FILE}"

    elif [ -z "$(cat "${PASSWORD_FILE}")" ]
    then
        eval "${CMD}" > "${PASSWORD_FILE}"
    fi
}

# Exported functions
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

function _query_kernel_package_info() {
    if [ ! -f "${TMP_KERNEL_PACKAGE_INFO_FILE}" ]
    then
        echo "Query package information of the configured linux kernel..."
        make ${MAKE_OPTS} linux-show-info > "${TMP_KERNEL_PACKAGE_INFO_FILE}"
    fi
}

function _get_kernel_version() {
    if [ ! -f "${TMP_KERNEL_PACKAGE_INFO_FILE}" ]
    then
        echo "Unable to determine linux version. query_kernel_package_info first".
        exit 1
    fi

    cat "${TMP_KERNEL_PACKAGE_INFO_FILE}" | jq ".linux.version" | tr -d '"'
}

function _get_kernel_build_dir() {
    if [ ! -f "${TMP_KERNEL_PACKAGE_INFO_FILE}" ]
    then
        echo "Unable to determine linux version. query_kernel_package_info first".
        exit 1
    fi

    DIR="$(cat "${TMP_KERNEL_PACKAGE_INFO_FILE}" | jq ".linux.build_dir" | tr -d '"')"
    echo "${BUILDROOT_BUILD_DIR}/${DIR}"
}

function setup_rust_tooling() {
    echo "Prepare rust tooling compatible to linux kernel..."

    # Examine linux sources to determine the required rust toolchain / bindgen version.
    # Unpack linux sources if needed
    _query_kernel_package_info
    local KERNEL_BUILD_DIR="$(_get_kernel_build_dir)"
    local KERNEL_TOOL_VERSION_SCRIPT="${KERNEL_BUILD_DIR}scripts/min-tool-version.sh"

    if [ ! -x "${KERNEL_TOOL_VERSION_SCRIPT}" ]
    then
        echo "Linux sources not found. Fetch and unpack them..."
        make ${MAKE_OPTS} linux-extract
    fi

    # Extract required minimal versions
    local KERNEL_VERSION="$(_get_kernel_version)"
    local MINIMUM_RUSTC_VERSION="$(${KERNEL_TOOL_VERSION_SCRIPT} rustc)"
    local MINIMUM_BINDGEN_VERSION="$(${KERNEL_TOOL_VERSION_SCRIPT} bindgen)"

    echo "Detected Linux kernel (${KERNEL_VERSION}) expects:"
    echo "    - rustc (${MINIMUM_RUSTC_VERSION})"
    echo "    - bindgen (${MINIMUM_BINDGEN_VERSION})"

    # Check rust installation
    local INSTALL_RUST="no"

    # Install if not found
    if [ ! -x "${BUILDROOT_HOST_BIN_DIR}/rustc" ]
    then
        echo "Rust toolchain not found. Install it."
        INSTALL_RUST="yes"

    # Install if version does not match
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

    # Don't install. Everything is fine.
    else
        echo "Rust toolchain (${MINIMUM_RUSTC_VERSION}) meets kernel expectency."
        INSTALL_RUST="no"
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
            if [ -x "${BINARY}" ]
            then
                ln -sf "${BINARY}" "${BUILDROOT_HOST_BIN_DIR}"
            fi
        done
    fi

    # Check bindgen installation
    local INSTALL_BINDGEN="no"

    if [ ! -x "${BUILDROOT_HOST_BIN_DIR}/bindgen" ]
    then
        echo "Bindgen not found. Install it."
        INSTALL_BINDGEN="yes"

    # Install if version does not match
    elif [ ! "$(${BUILDROOT_HOST_BIN_DIR}/bindgen --version | awk '{print $2}')" = "${MINIMUM_BINDGEN_VERSION}" ]
    then
        echo "Bindgen version does not match kernel expectency. Install it."
        rm -f "${BUILDROOT_HOST_BIN_DIR}/bindgen"
        INSTALL_BINDGEN="yes"

    # Don't install. Everything is fine.
    else
        echo "Bindgen (${MINIMUM_BINDGEN_VERSION}) meets kernel expectency."
        INSTALL_BINDGEN="no"
    fi

    # Install bindgen installation
    if [ "${INSTALL_BINDGEN}" = "yes" ]
    then
        rustup run --install stable cargo install --locked --force --version "${MINIMUM_BINDGEN_VERSION}" bindgen-cli
        ln -sf "${BUILDROOT_HOST_CARGO_BIN_DIR}/bindgen" "${BUILDROOT_HOST_BIN_DIR}/bindgen"
    fi
}

function preamble() {
    # Call sanity checks valid for each script
    _abort_if_buildroot_not_cloned
    _create_random_password_if_not_existing

    # Prepare directories
    mkdir -p "${BUILDROOT_BUILD_DIR}"
    mkdir -p ${BUILDROOT_HOST_BIN_DIR}

    if [ ! -e "${BUILDROOT_CONFIG}" ]
    then
        echo "Buildroot config does not exist. Create it."
        make ${MAKE_OPTS} defconfig BR2_DEFCONFIG="${BUILDROOT_CUSTOM_CONFIG}"
    fi
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
export BUILDROOT_HOST_RUSTUP_DIR
export BUILDROOT_HOST_CARGO_DIR
export BUILDROOT_HOST_CARGO_BIN_DIR

export TMP_QEMU_PID_FILE
export TMP_KERNEL_PACKAGE_INFO_FILE

export BUILDROOT_CUSTOM_CONFIG
export PASSWORD_FILE
export MAKE_OPTS
export SSH_PORT
export SSH_OPTS
export RUSTUP_HOME
export CARGO_HOME
export PATH

export -f preamble
export -f abort_if_qemu_is_not_running
export -f setup_rust_tooling
export -f stop_qemu_if_running
