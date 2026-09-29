#!/usr/bin/env bash
# Repo:   runbooks/backup_sync.sh
# Run on: Proxmox VE host, as root, nightly after vzdump (Chapter 11)
# Pushes VM backups and host configuration to an encrypted offsite repo.
set -euo pipefail

export RESTIC_REPOSITORY="s3:https://s3.eu-west-1.amazonaws.com/homelab-backups"
export RESTIC_PASSWORD_FILE=/root/.restic/password
export AWS_SHARED_CREDENTIALS_FILE=/root/.restic/aws_credentials

BACKUP_PATHS=(
  /tank/backups/dump        # nightly vzdump archives of VM 100 and 101
  /etc/pve                  # VM, storage and cluster configuration
  /etc/network/interfaces
  /etc/modprobe.d
)

echo "[*] Offsite backup started: $(date -Is)"

# Fails loudly if the repository is missing or unreachable.
# Create it once, by hand, with: restic init
restic cat config >/dev/null

restic backup --tag nightly "${BACKUP_PATHS[@]}"

restic forget --tag nightly \
  --keep-daily 7 --keep-weekly 4 --keep-monthly 12 --prune

restic check
# Sundays: also re-read a 5 % sample of the stored data itself
if [[ "$(date +%u)" == "7" ]]; then
  restic check --read-data-subset=5%
fi

echo "[+] Offsite backup completed: $(date -Is)"
