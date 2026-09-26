#!/usr/bin/env bash
# Repo:   runbooks/nvme-wear-textfile.sh
# Run on: Proxmox VE host via cron (Chapter 14). Needs smartmontools, jq.
set -euo pipefail
OUT_DIR=/var/lib/prometheus/node-exporter
TMP="$(mktemp "${OUT_DIR}/nvme.prom.XXXXXX")"
lines=()

for dev in /dev/nvme[0-9]; do
  [[ -e "$dev" ]] || continue
  json="$(smartctl -j -a "$dev" || true)"   # non-zero exit = warning bits
  used="$(jq -r '.nvme_smart_health_information_log.percentage_used // empty' \
          <<<"$json")"
  if [[ -n "$used" ]]; then
    lines+=("nvme_percentage_used{device=\"${dev##*/}\"} ${used}")
  fi
done

{
  echo "# HELP nvme_percentage_used Rated NVMe endurance used, percent."
  echo "# TYPE nvme_percentage_used gauge"
  if (( ${#lines[@]} )); then printf '%s\n' "${lines[@]}"; fi
} > "$TMP"

chmod 0644 "$TMP"
mv "$TMP" "${OUT_DIR}/nvme.prom"
