#!/bin/bash

set -o errexit -o pipefail
source "scripts/common.sh"
abort_if_buildroot_not_cloned
create_random_password_if_not_existing
stop_qemu_if_running

readonly QEMU_BINARY="${BUILDROOT_HOST_BIN_DIR}/qemu-system-x86_64"
readonly KERNEL_BINARY="${BUILDROOT_ARTIFACT_DIR}/bzImage"
readonly ROOTFS_BINARY="${BUILDROOT_ARTIFACT_DIR}/rootfs.ext2"

# Sanity checks
if [ ! -f "${QEMU_BINARY}" ]
then
    echo "Qemu binary not found at '${QEMU_BINARY}'."\
         "It might not been build. Build via 'make build_env'."
    exit 1
fi

if [ ! -f "${KERNEL_BINARY}" ]
then
    echo "Kernel binary not found at '${KERNEL_BINARY}'."\
         "It might not been build. Build via 'make build_env'."
    exit 1
fi

if [ ! -f "${ROOTFS_BINARY}" ]
then
    echo "Root filesystem not found at '${ROOTFS_BINARY}'."\
         "It might not been build. Build via 'make build_env'."
    exit 1
fi

# Spawn development environment via qemu (buildroot version)
${QEMU_BINARY} \
    -M pc \
    -kernel "${KERNEL_BINARY}" \
    -drive file="${ROOTFS_BINARY}",if=virtio,format=raw \
    -append "rootwait root=/dev/vda console=tty1 console=ttyS0" \
    -net nic,model=virtio \
    -net user,hostfwd=tcp::${SSH_PORT}-:22 \
    -daemonize > /dev/null 2>&1

PID=$(pidof ${QEMU_BINARY})

if [ -z "${PID}" ]
then
    echo "Failed to start virtual linux environment. Abort."
    exit 1
else
    echo "${PID}" > "${TMP_QEMU_PID_FILE}"
fi

echo "Started virtual linux environment (pid=${PID})."
echo "Wait a moment then login via 'make login'"
