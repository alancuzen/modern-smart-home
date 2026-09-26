#!/usr/bin/env bash
# Repo:   zfs/pool-creation.sh
# Run on: Proxmox VE host, as root (Chapter 2)
# Creates the HDD mirror "tank" for Frigate recordings and backups,
# then registers it with Proxmox VE.
set -euo pipefail

# REQUIRED: replace with your own disk IDs. List them with:
#   ls -l /dev/disk/by-id/ | grep -v part
DISK1="/dev/disk/by-id/ata-REPLACE_ME_1"
DISK2="/dev/disk/by-id/ata-REPLACE_ME_2"

for d in "$DISK1" "$DISK2"; do
  [[ -e "$d" ]] || { echo "[!] $d not found - edit DISK1/DISK2"; exit 1; }
done

echo "[!] This DESTROYS all data on:"
echo "    $DISK1"
echo "    $DISK2"
read -r -p "Type YES to continue: " CONFIRM
[[ "$CONFIRM" == "YES" ]] || exit 1

zpool create -o ashift=12 \
  -O compression=lz4 -O atime=off -O xattr=sa \
  tank mirror "$DISK1" "$DISK2"

zfs create tank/vm                        # zvols for VM data disks
zfs create -o recordsize=1M tank/backups  # vzdump archives

pvesm add zfspool tank-vm --pool tank/vm --content images --sparse 1
pvesm add dir tank-backups --path /tank/backups --content backup \
  --is_mountpoint yes

zpool status tank
