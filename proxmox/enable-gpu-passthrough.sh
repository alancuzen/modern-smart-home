#!/usr/bin/env bash
# Repo:   proxmox/enable-gpu-passthrough.sh
# Run on: Proxmox VE host, as root (Chapter 4)
# Binds the RTX 5060 Ti (GPU + HDMI audio function) to vfio-pci so it
# can be passed through to the Docker VM. Enable IOMMU first (Ch. 4.5).
set -euo pipefail

# Find both IDs with: lspci -nn | grep -i nvidia
GPU_IDS="10de:REPLACE,10de:REPLACE"
[[ "$GPU_IDS" != *REPLACE* ]] || { echo "[!] Set GPU_IDS first"; exit 1; }

cat > /etc/modules-load.d/vfio.conf <<'EOF'
vfio
vfio_iommu_type1
vfio_pci
EOF

cat > /etc/modprobe.d/vfio.conf <<EOF
options vfio-pci ids=${GPU_IDS} disable_vga=1
softdep nouveau pre: vfio-pci
softdep nvidia pre: vfio-pci
softdep snd_hda_intel pre: vfio-pci
EOF

cat > /etc/modprobe.d/blacklist-gpu.conf <<'EOF'
blacklist nouveau
blacklist nvidia
blacklist nvidiafb
EOF

update-initramfs -u -k all
if proxmox-boot-tool status >/dev/null 2>&1; then
  proxmox-boot-tool refresh   # systemd-boot / proxmox-boot hosts only
fi
echo "[OK] Reboot, then check: lspci -nnk -d 10de:"
echo "     Expect 'Kernel driver in use: vfio-pci' on both functions."
