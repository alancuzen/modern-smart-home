#!/usr/bin/env bash
# Repo:   proxmox/create-docker-vm.sh
# Run on: Proxmox VE host, as root (Chapter 4)
# Creates VM 101: Debian 12 Docker host (10.0.10.55) with the GPU.
set -euo pipefail

GPU_PCI="0000:02:00"   # from: lspci -D | grep -i nvidia (drop the .0)
ISO="local:iso/debian-12-amd64-netinst.iso"

qm create 101 --name docker-ai --ostype l26 \
  --machine q35 --bios ovmf \
  --efidisk0 local-zfs:1,efitype=4m,pre-enrolled-keys=0 \
  --cpu host --sockets 1 --cores 8 --memory 14336 --balloon 0 \
  --scsihw virtio-scsi-single \
  --scsi0 local-zfs:120,discard=on,iothread=1,ssd=1 \
  --scsi1 tank-vm:2000,discard=on,iothread=1,backup=0 \
  --net0 virtio,bridge=vmbr0,tag=10 \
  --hostpci0 "${GPU_PCI}",pcie=1 \
  --ide2 "${ISO}",media=cdrom --boot 'order=scsi0;ide2' \
  --agent 1 --onboot 1

echo "[OK] VM 101 created. Install Debian 12 with static IP 10.0.10.55;"
echo "     scsi1 (2 TB on tank) becomes /opt/frigate/storage (Chapter 9)."
