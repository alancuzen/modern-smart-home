#!/usr/bin/env bash
# Repo:   runbooks/frigate-gpu-recover.sh
# Run on: the Docker VM, as root (Appendix D and Chapter 9)
# Restarts Frigate cleanly and reports the detector's inference speed.
# If nvidia-smi itself hangs, the GPU is wedged: restart VM 101 from
# the Proxmox host instead (qm stop 101 && qm start 101).
set -euo pipefail
STACK=/opt/modern-smart-home/docker-compose/frigate

timeout 20 nvidia-smi >/dev/null \
  || { echo "[!] GPU not responding - restart VM 101 from the host"; exit 1; }

systemctl restart nvidia-persistenced || true
cd "$STACK"
docker compose --env-file ../.env restart frigate

echo "[*] Waiting for Frigate to start..."
sleep 45
curl -fsS --max-time 5 http://127.0.0.1:5000/api/stats \
  | jq '.detectors.onnx.inference_speed'
echo "[OK] Frigate restarted"
