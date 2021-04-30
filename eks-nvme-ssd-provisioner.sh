#!/usr/bin/env bash
set -Eeuo pipefail

mapfile -t SSD_NVME_DEVICE_LIST < <(nvme list | awk '/Amazon EC2 NVMe Instance Storage/{print $1}' || true)
SSD_NVME_DEVICE_COUNT=${#SSD_NVME_DEVICE_LIST[@]}
FILESYSTEM_BLOCK_SIZE=${FILESYSTEM_BLOCK_SIZE:-4096}  # Bytes

# Checking if provisioning already happened
if [[ "$(ls -A /pv-disks)" ]]; then
    echo 'Volumes already present in "/pv-disks"'
    echo -e "\n$(ls -Al /pv-disks | tail -n +2)\n"
    echo "I assume that provisioning already happened, doing nothing!"
    sleep infinity
fi

# Perform provisioning based on nvme device count
case ${SSD_NVME_DEVICE_COUNT} in
"0")
    echo 'No devices found of type "Amazon EC2 NVMe Instance Storage"'
    echo "Maybe your node selectors are not set correct"
    exit 1
    ;;
*)
    i=0
    for DEVICE in "${SSD_NVME_DEVICE_LIST[@]}"; do
        ((i+=1))
        mkfs.xfs -f -m crc=0 -b size="${FILESYSTEM_BLOCK_SIZE}" "${DEVICE}"
        UUID=$(blkid -s UUID -o value "${DEVICE}")
        mkdir -p /pv-disks/"${UUID}"
        mount -o defaults,noatime,discard,nobarrier --uuid "${UUID}" /pv-disks/"${UUID}"
        mkdir -p /nvme
        ln -s /pv-disks/"${UUID}" /nvme/disk"${i}"
        echo "Device ${DEVICE} has been mounted to /pv-disks/${UUID}"
        echo "NVMe SSD provisioning is done and I will go to sleep now"
    done
    ;;
esac


sleep infinity