#!/usr/bin/env bash
# Repo:   runbooks/zfs-health-textfile.sh
# Run on: Proxmox VE host via cron (Chapter 14)
# Publishes ZFS pool health and data-error counts for node_exporter.
set -euo pipefail
OUT_DIR=/var/lib/prometheus/node-exporter
TMP="$(mktemp "${OUT_DIR}/zfs.prom.XXXXXX")"
healthy=()
errors=()

for pool in $(zpool list -H -o name); do
  if [[ "$(zpool list -H -o health "$pool")" == "ONLINE" ]]; then
    healthy+=("zfs_pool_healthy{pool=\"${pool}\"} 1")
  else
    healthy+=("zfs_pool_healthy{pool=\"${pool}\"} 0")
  fi
  n="$(zpool status "$pool" | awk '/^errors:/ {print ($2 == "No") ? 0 : $2}')"
  errors+=("zfs_pool_data_errors{pool=\"${pool}\"} ${n:-0}")
done

{
  echo "# HELP zfs_pool_healthy 1 if the pool state is ONLINE."
  echo "# TYPE zfs_pool_healthy gauge"
  printf '%s\n' "${healthy[@]}"
  echo "# HELP zfs_pool_data_errors Data errors reported by zpool status."
  echo "# TYPE zfs_pool_data_errors gauge"
  printf '%s\n' "${errors[@]}"
} > "$TMP"

chmod 0644 "$TMP"
mv "$TMP" "${OUT_DIR}/zfs.prom"
