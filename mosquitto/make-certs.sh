#!/usr/bin/env bash
# Repo:   mosquitto/make-certs.sh
# Run on: the Mosquitto LXC (10.0.20.15), as root (Chapter 5)
# Creates a private CA and a server certificate for 10.0.20.15.
set -euo pipefail
install -d -m 0755 /etc/mosquitto/certs
cd /etc/mosquitto/certs

openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes \
  -keyout ca.key -out ca.crt -subj "/CN=Foxglove Lane MQTT CA"

openssl req -newkey rsa:2048 -nodes -keyout server.key \
  -out server.csr -subj "/CN=mqtt.home.arpa"

printf 'subjectAltName=IP:10.0.20.15,DNS:mqtt.home.arpa\n' > san.ext
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key \
  -CAcreateserial -out server.crt -days 825 -sha256 -extfile san.ext

chown root:mosquitto server.key && chmod 0640 server.key
chmod 0600 ca.key
echo "[OK] Copy ca.crt (never ca.key) to Home Assistant and Frigate."
