#!/usr/bin/env bash
# Repo:   mosquitto/provision-users.sh
# Run on: the Mosquitto LXC, as root (Chapter 5)
# Creates one credential per client. mosquitto_passwd prompts for each
# password, so none end up in shell history or process listings.
set -euo pipefail
PASSWD=/etc/mosquitto/passwd
USERS=(homeassistant zigbee2mqtt frigate esp32_living_room)

[[ -f "$PASSWD" ]] || install -m 0640 -o root -g mosquitto /dev/null "$PASSWD"

for u in "${USERS[@]}"; do
  echo "Password for ${u}:"
  mosquitto_passwd "$PASSWD" "$u"   # stores a salted PBKDF2-SHA512 hash
done

chown root:mosquitto "$PASSWD" && chmod 0640 "$PASSWD"
systemctl reload mosquitto          # SIGHUP: re-reads passwd and ACLs
