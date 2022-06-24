#!/usr/bin/env bash
set -euxo pipefail

disk1=/dev/sda
disk2=/dev/sdb
bootSize=512MiB
# `swapSize` should equal system RAM.
# This setup will create one swap partition on each disk.
swapSize=${swapSize:-32GiB}

# Remount already formatted storage
if [[ ${1:-} == remount ]]; then
    zpool import -f -N rpool
    zfs set mountpoint=/mnt rpool/root
    zfs set mountpoint=/mnt/nix rpool/nix
    zfs set mountpoint=/mnt/var/lib/db rpool/root/db
    zfs mount rpool/root
    zfs mount rpool/root/db
    zfs mount rpool/nix
    mount ${disk1}2 /mnt/boot1
    mount ${disk2}2 /mnt/boot2
    exit
fi

formatDisk() {
  disk=$1
  sgdisk --zap-all \
   -n 0:0:+1MiB      -t 0:ef02 -c 0:bios-boot \
   -n 0:0:+$bootSize -t 0:8300 -c 0:boot \
   -n 0:0:+$swapSize -t 0:8200 -c 0:swap \
   -n 0:0:0          -t 0:bf01 -c 0:root $disk
}
formatDisk $disk1
formatDisk $disk2
mkfs.fat -n boot1 ${disk1}2
mkfs.fat -n boot2 ${disk2}2
mkswap -L swap1 ${disk1}3
mkswap -L swap2 ${disk2}3

# ashift=12
# Set pool sector size to 2^12 to optimize performance for storage devices with 4K sectors.
# Auto-detection of physical sector size (/sys/block/sdX/queue/physical_block_size) can be unreliable.
#
# acltype=posixacl
# Required for / and the systemd journal
#
# xattr=sa
# Improve performance of certain extended attributes
#
# normalization=formD
# Enable UTF-8 normalization for file names
#
zpool create -f \
  -R /mnt \
  -O canmount=off \
  -O mountpoint=none \
  -o ashift=12 \
  -O acltype=posixacl \
  -O xattr=sa \
  -O normalization=formD \
  -O relatime=on \
  -O compression=lz4 \
  -O dnodesize=auto \
  rpool mirror ${disk1}4 ${disk2}4

zfs create -o mountpoint=/ -o canmount=on rpool/root
zfs create -o mountpoint=/nix -o canmount=on rpool/nix
# Create dataset optimized for RDBMS like postgres or mysql
# https://openzfs.github.io/openzfs-docs/Performance%20and%20Tuning/Workload%20Tuning.html?#database-workloads
zfs create -o mountpoint=/var/lib/db -o canmount=on \
  -o recordsize=8K \
  -o primarycache=metadata \
  -o logbias=throughput \
  rpool/root/db
zfs create -o refreservation=1G -o mountpoint=none -o canmount=off rpool/reserved

mkdir -p /mnt/{boot1,boot2}
mount ${disk1}2 /mnt/boot1
mount ${disk2}2 /mnt/boot2
