#!/usr/bin/env bash
# Repo:   network/tailscale-subnet-router.sh
# Run on: a dedicated Debian 12 LXC on VLAN 10, as root (Chapter 3)
# LXC prerequisite, in /etc/pve/lxc/<ctid>.conf on the Proxmox host:
#   lxc.cgroup2.devices.allow: c 10:200 rwm
#   lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file
set -euo pipefail

# 1. Install Tailscale from the official repository
curl -fsSL https://tailscale.com/install.sh | sh

# 2. Enable IP forwarding (overwrites the file, so re-runs are safe)
cat > /etc/sysctl.d/99-tailscale.conf <<'EOF'
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
EOF
sysctl -p /etc/sysctl.d/99-tailscale.conf

# 3. Authenticate and advertise the Trusted and IoT subnets
tailscale up \
  --advertise-routes=10.0.10.0/24,10.0.20.0/24 \
  --accept-dns=false \
  --ssh

# 4. Approve the routes in the Tailscale admin console
#    (Machines > this node > Edit route settings); until you do,
#    remote clients will not use them.
