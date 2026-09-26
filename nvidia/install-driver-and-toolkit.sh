#!/usr/bin/env bash
# Repo:   nvidia/install-driver-and-toolkit.sh
# Run on: the Docker VM (VM 101, Debian 12), as root (Chapter 9)
# Prerequisite: Docker Engine from Docker's apt repository
# (https://docs.docker.com/engine/install/debian/).
set -euo pipefail

# 1. NVIDIA driver R575 or later with the open kernel modules
#    (required for Blackwell GPUs such as the RTX 5060 Ti)
CUDA_REPO=https://developer.download.nvidia.com/compute/cuda/repos/debian12/x86_64
wget -O /tmp/cuda-keyring.deb "$CUDA_REPO/cuda-keyring_1.1-1_all.deb"
dpkg -i /tmp/cuda-keyring.deb
apt-get update
apt-get install -y "linux-headers-$(uname -r)" nvidia-open
systemctl enable nvidia-persistenced \
  || echo "[i] Enable nvidia-persistenced after the reboot"

# 2. NVIDIA Container Toolkit (stable channel)
KEYRING=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
LIBNV=https://nvidia.github.io/libnvidia-container
curl -fsSL "$LIBNV/gpgkey" | gpg --dearmor --yes -o "$KEYRING"
curl -fsSL "$LIBNV/stable/deb/nvidia-container-toolkit.list" \
  | sed "s#deb https://#deb [signed-by=$KEYRING] https://#g" \
  > /etc/apt/sources.list.d/nvidia-container-toolkit.list
apt-get update
apt-get install -y nvidia-container-toolkit

# 3. Register the NVIDIA runtime with Docker
nvidia-ctk runtime configure --runtime=docker
systemctl restart docker

echo "[OK] Reboot, then run nvidia-smi: expect driver 575+ and the GPU."
