#!/bin/sh

# Sanitize input
OPERATION="$1"
case "${OPERATION}" in
    "-a")
        echo "Operation: Add"
        shift 1
        ;;
    "-r")
        echo "Operation: Remove"
        shift 1
        ;;
    *)
        echo "Invalid operation: param1 must be either -a or -r"
        exit 1
        ;;
esac

MODULE="$1"
if [ -z "${MODULE}" ]
then
    echo "Module name was given. Abort."
    exit 1
fi

# Cleanup stale nodes
DEV_PATH="/dev"
DEVICE_BASE_FILE="${DEV_PATH}/${MODULE}"
rm -f "${DEVICE_BASE_FILE}"*

# Try to lookup major id of kernel module
DEVICES_FILE="/proc/devices"
MAJOR_ID="$(grep "${MODULE}" "${DEVICES_FILE}" | awk '{print $1}')"

if [ -z "${MAJOR_ID}" ]
then
    echo "Failed to lookup MAJOR id of module ${MODULE}. Return Error."
    exit 1

elif [ ! "${MAJOR_ID}" -eq "${MAJOR_ID}" ]
then
    echo "Read MAJOR id of module ${MODULE} is not a number. Return Error."
    exit 1
fi

# Try to lookup minor id of created devices
PARAMETERS_PATH="/sys/module/${MODULE}/parameters"
MINOR_ID="$(cat "${PARAMETERS_PATH}/DEVICES" 2>/dev/null | awk '{print $1}')"

if [ -z "${MINOR_ID}" ]
then
    echo "Failed to lookup maximum MINOR id of module ${MODULE}. Return Error."
    exit 1

elif [ ! "${MINOR_ID}" -eq "${MINOR_ID}" ]
then
    echo "Read maximum MINOR id of module ${MODULE} is not a number. Return Error."
    exit 1
fi

case "${OPERATION}" in
    "-a")
        for NUMBER in $(seq 0 $(($MINOR_ID-1)))
        do
            mknod "${DEVICE_BASE_FILE}${NUMBER}" c ${MAJOR_ID} ${NUMBER}
        done
        ;;

    "-r")
        # Do nothing.
        ;;
esac
