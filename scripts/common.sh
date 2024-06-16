set -o errexit -o pipefail -o nounset

# Core paths
declare BASE_DIR
BASE_DIR="$(pwd)"
readonly BASE_DIR
readonly ENV_DIR="${BASE_DIR}/env"
readonly BUILD_DIR="${BASE_DIR}/build"

# Buildroot: paths
readonly BUILDROOT_DIR="${ENV_DIR}/buildroot"
readonly BUILDROOT_BUILD_DIR="${BUILD_DIR}/buildroot"
readonly BUILDROOT_ARTIFACT_DIR="${BUILDROOT_BUILD_DIR}/images"
readonly BUILDROOT_HOST_DIR="${BUILDROOT_BUILD_DIR}/host"
readonly BUILDROOT_HOST_BIN_DIR="${BUILDROOT_HOST_DIR}/bin"

# Buildroot: files
readonly BUILDROOT_CONFIG="${BUILDROOT_BUILD_DIR}/.config"
readonly BUILDROOT_CUSTOM_CONFIG="${ENV_DIR}/buildroot.config"
readonly BUILDROOT_ROOTFS_BINARY="${BUILDROOT_ARTIFACT_DIR}/rootfs.ext2"

# Buildroot: other
declare BUILDROOT_MAKE_OPTS
BUILDROOT_MAKE_OPTS="-C ${BUILDROOT_DIR} O=${BUILDROOT_BUILD_DIR}"
readonly BUILDROOT_MAKE_OPTS

# Linux: paths
readonly LINUX_DIR="${ENV_DIR}/linux"
readonly LINUX_BUILD_DIR="${BUILD_DIR}/linux"

# Linux: files
readonly LINUX_CONFIG="${LINUX_BUILD_DIR}/.config"
readonly LINUX_CUSTOM_CONFIG="${ENV_DIR}/linux.config"
readonly LINUX_DEFCONFIG_QEMU="${LINUX_DIR}/arch/x86/configs/qemu_defconfig"
readonly LINUX_KERNEL_BINARY="${LINUX_BUILD_DIR}/arch/x86/boot/bzImage"

# Linux: other
declare LINUX_MAKE_OPTS
LINUX_MAKE_OPTS="-j$(nproc) LLVM=1 -C ${LINUX_DIR} O=${LINUX_BUILD_DIR}"
readonly LINUX_MAKE_OPTS

# Linux modules: paths
readonly MODULE_DIR="${BASE_DIR}/modules"
readonly MODULE_BUILD_DIR="${BUILD_DIR}/modules"

# Linux modules: other
declare MODULE_MAKE_OPTS
MODULE_MAKE_OPTS="-j$(nproc) LLVM=1 LINUX_BUILD_DIR=${LINUX_BUILD_DIR}"
readonly MODULE_MAKE_OPTS

# Rust: paths
readonly RUSTUP_DIR="${BUILD_DIR}/rustup"
readonly RUSTUP_BIN_DIR="${RUSTUP_DIR}/bin"
readonly CARGO_DIR="${BUILD_DIR}/cargo"
readonly CARGO_BIN_DIR="${CARGO_DIR}/bin"

# Slides: files
readonly SLIDES_DIR="${BASE_DIR}/slides"
readonly SLIDES_BUILD_DIR="${BUILD_DIR}/slides"
readonly SLIDES="${SLIDES_BUILD_DIR}/slides.pdf"

# Tools: files
readonly TMP_QEMU_PID_FILE="/tmp/kernel_hacking_environment.pid"
readonly SSH_PASSWORD_FILE="${BUILD_DIR}/ssh_password"

# Tools: other
readonly BOOT_DURATION="15"
readonly SSH_PORT="2222"
readonly SSH_TARGET="root@localhost"
readonly SSH_OPTS="-p ${SSH_PORT} \
                   -o StrictHostKeyChecking=no \
                   -o PubkeyAuthentication=no \
                   -o PreferredAuthentications=password \
                   -o UserKnownHostsFile=/dev/null \
                   -o LogLevel=ERROR \
                      ${SSH_TARGET}
                   "
readonly SCP_OPTS="-P ${SSH_PORT} \
                   -o StrictHostKeyChecking=no \
                   -o PubkeyAuthentication=no \
                   -o PreferredAuthentications=password \
                   -o UserKnownHostsFile=/dev/null \
                   -o LogLevel=ERROR
                   "


# Overrides: paths
RUSTUP_HOME="${RUSTUP_DIR}"
CARGO_HOME="${CARGO_DIR}"
PATH="${CARGO_BIN_DIR}:${RUSTUP_BIN_DIR}:${PATH}"

# Functions
function abort_if_buildroot_not_cloned() {
    if [ ! -f "${BUILDROOT_DIR}/Makefile" ]
    then
        echo "Error: git repository 'env/buildroot' empty."\
             "Submodule might not be checked out."
        exit 1
    fi
}

function abort_if_linux_not_cloned() {
    if [ ! -f "${LINUX_DIR}/Makefile" ]
    then
        echo "Error: git repository 'env/linux' empty."\
             "Submodule might not be checked out."
        exit 1
    fi
}

function create_random_password_if_not_existing() {
    CMD="head -c 40 /dev/urandom | base64 | tr -dc _A-Z-a-z-0-9; echo;"
    if [ ! -f "${SSH_PASSWORD_FILE}" ]
    then
        mkdir -p "$(dirname "${SSH_PASSWORD_FILE}")"
        eval "${CMD}" > "${SSH_PASSWORD_FILE}"

    elif [ -z "$(cat "${SSH_PASSWORD_FILE}")" ]
    then
        eval "${CMD}" > "${SSH_PASSWORD_FILE}"
    fi
}

# Exported functions
function abort_if_buildroot_was_not_built() {
    if [ ! -f "${BUILDROOT_ROOTFS_BINARY}" ]
    then
        echo "Root filesystem not found at '${BUILDROOT_ROOTFS_BINARY}'."\
             "It was not built. Build via 'make build_buildroot'."
        exit 1
    fi
}

function abort_if_linux_was_not_built() {
    if [ ! -f "${LINUX_KERNEL_BINARY}" ]
    then
        echo "Kernel binary not found at '${LINUX_KERNEL_BINARY}'."\
             "It was not built. Build via 'make build_linux'."
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

function setup_rust_tooling() {
    echo "Prepare rust tooling compatible to linux kernel..."

    # Examine linux sources to determine the required rust toolchain / bindgen version.
    # Unpack linux sources if needed
    local KERNEL_TOOL_VERSION_SCRIPT
    KERNEL_TOOL_VERSION_SCRIPT="${LINUX_DIR}/scripts/min-tool-version.sh"

    local MINIMUM_RUSTC_VERSION
    MINIMUM_RUSTC_VERSION="$(${KERNEL_TOOL_VERSION_SCRIPT} rustc)"

    local MINIMUM_BINDGEN_VERSION
    MINIMUM_BINDGEN_VERSION="$(${KERNEL_TOOL_VERSION_SCRIPT} bindgen)"

    local KERNEL_VERSION
    # shellcheck disable=SC2086 # Deliberate word splitting
    KERNEL_VERSION="$(make ${LINUX_MAKE_OPTS} -s kernelversion)"

    echo "Linux kernel (${KERNEL_VERSION}) expects:"
    echo "    - rustc (${MINIMUM_RUSTC_VERSION})"
    echo "    - bindgen (${MINIMUM_BINDGEN_VERSION})"

    # Check rust installation
    local INSTALL_RUST="no"

    if [ ! -x "${RUSTUP_BIN_DIR}/rustc" ]
    then
        echo "Rust toolchain not found. Install it."
        INSTALL_RUST="yes"

    elif [ ! "$("${RUSTUP_BIN_DIR}"/rustc --version | awk '{print $2}')" = "${MINIMUM_RUSTC_VERSION}" ]
    then
        echo "Rust toolchain version does not match kernel expectency. Install it."
        INSTALL_RUST="yes"

        # Cleanup: symlinks from current toolchain
        local TOOLCHAIN_BIN_DIR
        TOOLCHAIN_BIN_DIR="$(dirname "$(rustup which rustc)")"

        for BINARY in "${TOOLCHAIN_BIN_DIR}"/*
        do
            rm -f "${RUSTUP_BIN_DIR}/$(basename "${BINARY}")"
        done

    else
        echo "Rust toolchain (${MINIMUM_RUSTC_VERSION}) meets kernel expectency."
    fi

    if [ "${INSTALL_RUST}" = "yes" ]
    then
        mkdir -p "${CARGO_BIN_DIR}"

        # Install rustup if not already available
        if [ ! -x "${CARGO_BIN_DIR}/rustup" ]
        then
            wget -q -O - https://sh.rustup.rs | sh -s -- -y --no-modify-path --default-toolchain none
        fi

        # Build required rust version and link tooling it to host bin location
        # shellcheck disable=SC2086 # Deliberate word splitting
        rustup install ${MINIMUM_RUSTC_VERSION}
        # shellcheck disable=SC2086 # Deliberate word splitting
        rustup override set ${MINIMUM_RUSTC_VERSION}
        rustup component add rust-src

        local TOOLCHAIN_BIN_DIR
        TOOLCHAIN_BIN_DIR="$(dirname "$(rustup which rustc)")"

        mkdir -p "${RUSTUP_BIN_DIR}"
        for BINARY in "${TOOLCHAIN_BIN_DIR}"/*
        do
            ln -sf "${BINARY}" "${RUSTUP_BIN_DIR}"
        done
    fi

     # Check bindgen installation
     local INSTALL_BINDGEN="no"

     if [ ! -x "${CARGO_BIN_DIR}/bindgen" ]
     then
         echo "Bindgen not found. Install it."
         INSTALL_BINDGEN="yes"

     elif [ ! "$("${CARGO_BIN_DIR}"/bindgen --version | awk '{print $2}')" = "${MINIMUM_BINDGEN_VERSION}" ]
     then
         echo "Bindgen version does not match kernel expectency. Install it."
         INSTALL_BINDGEN="yes"

     else
         echo "Bindgen (${MINIMUM_BINDGEN_VERSION}) meets kernel expectency."
     fi

     # Install bindgen installation
     if [ "${INSTALL_BINDGEN}" = "yes" ]
     then
         # shellcheck disable=SC2086 # Deliberate word splitting
         rustup run --install stable cargo install --locked --force --version ${MINIMUM_BINDGEN_VERSION} bindgen-cli
     fi
}

function setup_buildroot_config() {
    if [ ! -e "${BUILDROOT_CONFIG}" ]
    then
        echo "Buildroot config does not exist. Create it."
        # shellcheck disable=SC2086 # Deliberate word splitting
        make ${BUILDROOT_MAKE_OPTS} -s defconfig BR2_DEFCONFIG="${BUILDROOT_CUSTOM_CONFIG}"
    fi
}

function setup_linux_config() {
    if [ ! -e "${LINUX_CONFIG}" ]
    then
        # Copy versioned defconfig into a findable location
        # to generate normal config from it. Delete it afterwards.
        echo "Linux config does not exist. Create it."
        cp "${LINUX_CUSTOM_CONFIG}" "${LINUX_DEFCONFIG_QEMU}"

        # shellcheck disable=SC2086 # Deliberate word splitting
        make ${LINUX_MAKE_OPTS} -s "$(basename "${LINUX_DEFCONFIG_QEMU}")"
        rm "${LINUX_DEFCONFIG_QEMU}"
    fi

}

function preamble() {
    abort_if_buildroot_not_cloned
    abort_if_linux_not_cloned
    create_random_password_if_not_existing
}

# Export symbols to outer environment
export BASE_DIR
export ENV_DIR
export BUILD_DIR

# Buildroot: paths
export BUILDROOT_DIR
export BUILDROOT_BUILD_DIR
export BUILDROOT_ARTIFACT_DIR
export BUILDROOT_HOST_DIR
export BUILDROOT_HOST_BIN_DIR

# Buildroot: files
export BUILDROOT_CONFIG
export BUILDROOT_CUSTOM_CONFIG
export BUILDROOT_ROOTFS_BINARY

# Buildroot: other
export BUILDROOT_MAKE_OPTS

# Linux: paths
export LINUX_DIR
export LINUX_BUILD_DIR

# Linux: files
export LINUX_CONFIG
export LINUX_CUSTOM_CONFIG
export LINUX_DEFCONFIG_QEMU
export LINUX_KERNEL_BINARY

# Linux: other
export LINUX_MAKE_OPTS

# Linux modules: paths
export MODULE_DIR
export MODULE_BUILD_DIR

# Linux modules: other
export MODULE_MAKE_OPTS

# Rust: paths
export RUSTUP_DIR
export RUSTUP_BIN_DIR
export CARGO_DIR
export CARGO_BIN_DIR

# Slides: paths
export SLIDES_DIR
export SLIDES_BUILD_DIR
export SLIDES

# Tools: files
export TMP_QEMU_PID_FILE
export SSH_PASSWORD_FILE

# Tools: other
export BOOT_DURATION
export SSH_TARGET
export SSH_PORT
export SSH_OPTS
export SCP_OPTS

# Overrides: paths
export RUSTUP_HOME
export CARGO_HOME
export PATH

# Functions
export -f abort_if_buildroot_not_cloned
export -f abort_if_linux_not_cloned
export -f create_random_password_if_not_existing
export -f abort_if_buildroot_was_not_built
export -f abort_if_linux_was_not_built
export -f stop_qemu_if_running
export -f setup_rust_tooling
export -f setup_buildroot_config
export -f setup_linux_config
export -f preamble
