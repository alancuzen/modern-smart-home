# Firewall Matrix - Foxglove Lane Reference Design

Default policy: DENY all inter-VLAN traffic. The rules below are explicit,
stateful ALLOW/DENY entries, evaluated top-down per interface; return traffic
for allowed connections is permitted automatically. Implement them by hand in
OPNsense/pfSense (Chapter 3). mDNS between VLAN 10 and VLAN 20 is handled by
the reflector in network/avahi-daemon.conf, not by these rules.

| Source | Destination | Port/Protocol | Action | Rationale |
| --- | --- | --- | --- | --- |
| VLAN 10 (Trusted) | VLAN 20 (IoT) | ANY | ALLOW | Admin access to device UIs, ESPHome API (TCP 6053), HA and Frigate to the broker (TCP 8883). |
| VLAN 20 (IoT) | 10.0.10.50 (HA) | TCP 8123 | ALLOW | Device callbacks and webhooks to Home Assistant. |
| VLAN 20 (IoT) | 10.0.20.1 (gateway) | UDP 53, UDP 123 | ALLOW | Local DNS and NTP. |
| VLAN 20 (IoT) | WAN | ANY | DENY | Drops outbound telemetry and phone-home requests. |
| 10.0.10.55 (NVR) | VLAN 30 (Cams) | TCP 554, TCP 80/443 | ALLOW | Frigate pulls RTSP streams; camera admin UI. |
| VLAN 30 (Cams) | 10.0.30.1 (gateway) | UDP 123 | ALLOW | Keeps camera clocks and footage timestamps correct. |
| VLAN 30 (Cams) | ANY | ANY | DENY | Cameras cannot reach other internal devices or the Internet. |
| VLAN 40 (Guest) | RFC 1918 ranges | ANY | DENY | Guests cannot reach any internal VLAN. |
| VLAN 40 (Guest) | WAN | ANY | ALLOW | Internet-only access; enable client isolation on the guest SSID. |
