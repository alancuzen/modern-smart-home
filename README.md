# Designing and Building the Modern Smart Home

**Proxmox, Home Assistant, Frigate, TensorRT & Edge AI** — companion repository for the book by Alan Cuzen.

Every configuration file and script in this repository is printed in full in the book (only this README, LICENSE and .gitignore are not), and every configuration file in the book is here. Appendix F of the book maps each file to its chapter.

## Reference versions

The versions these configurations were written against (September 2026). Several of these projects ship breaking changes monthly: check this table against your own install and record the exact versions you run.

| Component | Version | Why it matters |
| --- | --- | --- |
| Proxmox VE | 8.4 or 9.x | The Helper-Scripts installer requires 8.4+ |
| Docker VM OS | Debian 12 | NVIDIA repository path used in Chapter 9 |
| NVIDIA driver | R575+, open kernel modules | Required for Blackwell (RTX 50-series) |
| Docker Engine | 24+ with NVIDIA Container Toolkit | GPU reservations in Compose |
| Home Assistant | 2025.1+ | Tile/Heading cards, `perform-action`, current automation syntax |
| ESPHome | 2026.9+ | OTA encrypted with the `api:` key; `channel_colors` |
| Frigate | 0.17.2 (`-tensorrt`) | Security fixes; 0.18 changed the config format and is not covered |
| Mosquitto | 2.0.x (Debian package) | 2.1 plugin equivalents noted in the config |
| Mushroom (HACS) | 5.x | Template cards use `color`, not `icon_color` |
| Prometheus / Alertmanager / node_exporter | 3.11.2 / 0.34.1 / 1.12.1 | Pinned in the monitoring stack |
| cAdvisor | 0.56.2 (`ghcr.io/google/cadvisor`) | Older releases can't talk to current Docker Engine |
| Grafana | 13.2.2 | Supported release with security fixes |
| PostgreSQL | 16 | Recorder database |
| Ollama, Piper, faster-whisper | Pin after testing | Record the image digest you tested |

## Addressing plan

| Address | Role |
| --- | --- |
| 10.0.10.2 | Proxmox VE host |
| 10.0.10.50 | Home Assistant OS VM (VM 100) |
| 10.0.10.55 | Docker VM (VM 101) — `HOST_IP` |
| 10.0.10.60 | Caddy reverse proxy |
| 10.0.20.15 | Mosquitto broker (TLS only, port 8883) |
| 10.0.20.105–.135 | ESPHome nodes (including the heating controller at .135) |
| 10.0.30.201–.204 | Cameras |

## Quick start (Appendix E)

Prerequisites: Proxmox VE 8.4 or 9.x installed on a ZFS mirror (Chapter 2), and this repository cloned on the host:

```bash
git clone https://github.com/alancuzen/modern-smart-home.git /opt/modern-smart-home
cd /opt/modern-smart-home
```

**1. Create the ZFS data pool (Chapter 2)** — on the Proxmox host:

```bash
# Edit DISK1/DISK2 in the script first
bash zfs/pool-creation.sh
```

**2. Set ARC limits (Chapter 2)** — on the Proxmox host:

```bash
cp zfs/zfs.conf /etc/modprobe.d/zfs.conf
update-initramfs -u -k all
proxmox-boot-tool refresh   # systemd-boot hosts only
```

**3. Pass the GPU through and create the Docker VM (Chapter 4)** — on the Proxmox host:

```bash
# Edit GPU_IDS, run, reboot; then edit GPU_PCI and create VM 101
bash proxmox/enable-gpu-passthrough.sh
bash proxmox/create-docker-vm.sh
```

**4. Install the NVIDIA driver and Container Toolkit (Chapter 9)** — on the Docker VM, after installing Debian 12 and Docker Engine:

```bash
sudo git clone https://github.com/alancuzen/modern-smart-home.git \
  /opt/modern-smart-home
cd /opt/modern-smart-home
sudo bash nvidia/install-driver-and-toolkit.sh   # then reboot
```

**5. Export the detection model and prepare Frigate (Chapter 9)** — on the Docker VM:

```bash
cd /opt/modern-smart-home
sudo bash frigate/export-yolov9.sh
# Then follow the one-time preparation block in Section 9.8. Until the
# Chapter 5 broker exists, set mqtt: enabled: false in config.yml.
```

**6. Deploy Frigate (Chapter 9)** — on the Docker VM:

```bash
cd /opt/modern-smart-home/docker-compose/frigate
sudo docker compose --env-file ../.env up -d
```

## Repository map

| Path | Chapter | Purpose |
| --- | --- | --- |
| [`docker-compose/.env.example`](docker-compose/.env.example) | Intro, Ch. 9 | Shared variables for every Compose stack |
| [`docker-compose/ai-voice/docker-compose.yml`](docker-compose/ai-voice/docker-compose.yml) | Ch. 15 | Ollama + Wyoming Whisper + Piper stack |
| [`docker-compose/frigate/docker-compose.yml`](docker-compose/frigate/docker-compose.yml) | Ch. 9 | Frigate stack |
| [`docker-compose/frigate/frigate.env.example`](docker-compose/frigate/frigate.env.example) | Ch. 9 | Frigate secrets template |
| [`docker-compose/monitoring/alertmanager/alertmanager.yml`](docker-compose/monitoring/alertmanager/alertmanager.yml) | Ch. 14 | Route alerts to the HA webhook |
| [`docker-compose/monitoring/docker-compose.yml`](docker-compose/monitoring/docker-compose.yml) | Ch. 14 | Prometheus, node_exporter, cAdvisor, Alertmanager, Grafana |
| [`docker-compose/monitoring/prometheus/alerts.yml`](docker-compose/monitoring/prometheus/alerts.yml) | Ch. 14 | Alert rules |
| [`docker-compose/monitoring/prometheus/prometheus.yml`](docker-compose/monitoring/prometheus/prometheus.yml) | Ch. 14 | Scrape targets |
| [`docker-compose/postgres/docker-compose.yml`](docker-compose/postgres/docker-compose.yml) | Ch. 12 | PostgreSQL 16 for the HA recorder |
| [`esphome/ble_proxy_node.yaml`](esphome/ble_proxy_node.yaml) | Ch. 6 | Hallway Bluetooth proxy |
| [`esphome/environmental_node.yaml`](esphome/environmental_node.yaml) | Ch. 7 | Kitchen BME280 + SGP30 + PMS5003 node |
| [`esphome/heating_zone_controller.yaml`](esphome/heating_zone_controller.yaml) | Ch. 10 | Two-zone PID heating controller (S-plan) |
| [`esphome/intercom_latch.yaml`](esphome/intercom_latch.yaml) | Ch. 8 | Front-door intercom release relay |
| [`esphome/radar_node.yaml`](esphome/radar_node.yaml) | Ch. 8 | LD2410 mmWave presence node |
| [`esphome/secrets.yaml.example`](esphome/secrets.yaml.example) | Ch. 6 | Credentials template for all ESPHome nodes |
| [`esphome/smart_plug_01.yaml`](esphome/smart_plug_01.yaml) | Ch. 8 | Reflashed ESP8266 smart plug with power metering |
| [`esphome/voice_satellite.yaml`](esphome/voice_satellite.yaml) | Ch. 15 | ESP32-S3 voice satellite (microWakeWord) |
| [`frigate/config.yml`](frigate/config.yml) | Ch. 9 | Frigate 0.17 config: 4x Tapo C310, ONNX on the GPU |
| [`frigate/export-yolov9.sh`](frigate/export-yolov9.sh) | Ch. 9 | Export YOLOv9-t (320) to ONNX for Frigate |
| [`homeassistant/automations.yaml`](homeassistant/automations.yaml) | Ch. 8, 9, 10, 13, 14 | All automations used in the book |
| [`homeassistant/configuration.yaml`](homeassistant/configuration.yaml) | App. C | Consolidated Home Assistant configuration |
| [`homeassistant/dashboards/ground_floor_panel.yaml`](homeassistant/dashboards/ground_floor_panel.yaml) | Ch. 13 | Wall-panel dashboard (YAML mode) |
| [`homeassistant/ollama-tool-call-example.json`](homeassistant/ollama-tool-call-example.json) | Ch. 15 | Direct Ollama /api/chat tool-calling test |
| [`homeassistant/scenes.yaml`](homeassistant/scenes.yaml) | App. C | Scenes file included by configuration.yaml (starts empty) |
| [`homeassistant/scripts.yaml`](homeassistant/scripts.yaml) | Ch. 15 | Scripts exposed to Assist as LLM tools |
| [`homeassistant/secrets.yaml.example`](homeassistant/secrets.yaml.example) | Ch. 12 | HA secrets template |
| [`mosquitto/aclfile`](mosquitto/aclfile) | Ch. 5 | Per-client MQTT access control list |
| [`mosquitto/make-certs.sh`](mosquitto/make-certs.sh) | Ch. 5 | Private CA + broker TLS certificate |
| [`mosquitto/mosquitto.conf`](mosquitto/mosquitto.conf) | Ch. 5 | Hardened broker config (TLS-only listener on 8883) |
| [`mosquitto/provision-users.sh`](mosquitto/provision-users.sh) | Ch. 5 | Create one broker credential per client |
| [`network/Caddyfile`](network/Caddyfile) | Ch. 3 | Hardened reverse proxy for Home Assistant |
| [`network/avahi-daemon.conf`](network/avahi-daemon.conf) | Ch. 3 | mDNS reflector (VLAN 10 <-> VLAN 20 only) |
| [`network/firewall-matrix.md`](network/firewall-matrix.md) | Ch. 3 | Inter-VLAN firewall rules (design summary) |
| [`network/tailscale-subnet-router.sh`](network/tailscale-subnet-router.sh) | Ch. 3 | Tailscale subnet router setup (LXC) |
| [`nvidia/install-driver-and-toolkit.sh`](nvidia/install-driver-and-toolkit.sh) | Ch. 9 | NVIDIA R575+ open driver + Container Toolkit (in VM 101) |
| [`proxmox/100.conf`](proxmox/100.conf) | Ch. 4 | Reference config of the HAOS VM (VM 100) |
| [`proxmox/create-docker-vm.sh`](proxmox/create-docker-vm.sh) | Ch. 4 | Create VM 101 (Docker VM) with the GPU passed through |
| [`proxmox/enable-gpu-passthrough.sh`](proxmox/enable-gpu-passthrough.sh) | Ch. 4 | Bind the GPU to vfio-pci on the host |
| [`proxmox/interfaces`](proxmox/interfaces) | App. B | Proxmox host network and VLAN bridge |
| [`runbooks/backup_sync.sh`](runbooks/backup_sync.sh) | Ch. 11 | Nightly encrypted offsite copy with restic |
| [`runbooks/frigate-gpu-recover.sh`](runbooks/frigate-gpu-recover.sh) | App. D, Ch. 9 | Recover a stalled Frigate GPU detector |
| [`runbooks/modern-smart-home.cron`](runbooks/modern-smart-home.cron) | Ch. 11, 14 | Cron schedule for the host runbooks |
| [`runbooks/nvme-wear-textfile.sh`](runbooks/nvme-wear-textfile.sh) | Ch. 14 | NVMe endurance used -> node_exporter textfile |
| [`runbooks/remediation-authorized_keys.example`](runbooks/remediation-authorized_keys.example) | Ch. 14 | Forced-command SSH key for HA remediation |
| [`runbooks/zfs-health-textfile.sh`](runbooks/zfs-health-textfile.sh) | Ch. 14 | ZFS pool health -> node_exporter textfile |
| [`zfs/pool-creation.sh`](zfs/pool-creation.sh) | Ch. 2 | Create the HDD mirror 'tank' and its Proxmox storages |
| [`zfs/zfs.conf`](zfs/zfs.conf) | Ch. 2 | ZFS ARC limits for the 32 GB reference host |

## Secrets

Real credentials never belong in this repository. Copy each `*.example` file to its real name on the target machine, fill it in, and `chmod 600` it. `.gitignore` blocks the real files.

## License

The original configuration snippets and scripts are released under the MIT License (see `LICENSE`). Third-party projects they install or reference keep their own licences.
