# VLAN Firewall Matrix - Reference Build
## Designing and Building the Modern Smart Home (HP Z440 + RTX 5060 Ti)

This matrix defines the intended firewall policy for the segmented network described in Chapter 3. Default policy is DENY all inter-VLAN. Only explicitly allowed traffic is permitted. OPNsense is stateful, so return traffic is automatic.

**Test goal:** Verify that each rule does what it says — can a device on IOT actually NOT reach TRUSTED, etc.

### 1. VLAN Definitions (Reference)

| VLAN ID | Name | Subnet (Example) | Purpose | Example Clients |
| :--- | :--- | :--- | :--- | :--- |
| 10 | MGMT | 10.10.10.0/24 | Proxmox, OPNsense, Switches, APs, ZFS management | Proxmox host, managed switches |
| 20 | TRUSTED | 10.10.20.0/24 | User devices, Home Assistant, NAS | PCs, phones, Home Assistant VM |
| 30 | IOT | 10.10.30.0/24 | General IoT, cloud-capable devices | Tasmota plugs, bulbs, ESPHome |
| 40 | GUEST | 10.10.40.0/24 | Guest WiFi, isolated, internet only | Guest phones |
| 50 | CAM | 10.10.50.0/24 | IP Cameras, NO internet | Reolink, Amcrest cams |
| 60 | IOT_RESTRICTED | 10.10.60.0/24 | No-internet IoT, local only | Cheap sensors, vacuums |

DNS for all VLANs: Redirect to OPNsense / AdGuard Home on 10.10.10.1
NTP for all VLANs: Allow to OPNsense only

### 2. Core Principles

1.  Guest and Cameras can NEVER initiate to other VLANs.
2.  IOT can NEVER initiate to Trusted or MGMT.
3.  Trusted can initiate to ALL (for management).
4.  Cameras have NO internet access. Frigate pulls RTSP.
5.  All VLANs DNS is forced to firewall, not 8.8.8.8.

### 3. Firewall Matrix

| # | Source | Destination | Port / Proto | Action | Reason / Notes |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **MGMT (10)** | | | | | |
| 1 | MGMT | ANY | ANY | ALLOW | Management network is god mode |
| **TRUSTED (20)** | | | | | |
| 2 | TRUSTED | MGMT | 8006 TCP, 22 TCP, 443 TCP, 80 TCP | ALLOW | Access Proxmox, OPNsense, switches |
| 3 | TRUSTED | IOT | ANY | ALLOW | Control IoT devices, Home Assistant to devices |
| 4 | TRUSTED | CAM | 554 TCP, 8000 TCP, 80 TCP | ALLOW | View camera streams directly if needed |
| 5 | TRUSTED | GUEST | ANY | ALLOW | Optional, can set to DENY if you want strict |
| 6 | TRUSTED | Internet | ANY | ALLOW | Normal browsing |
| **IOT (30)** | | | | | |
| 7 | IOT | TRUSTED | ALL | BLOCK | IoT must never reach user PCs |
| 8 | IOT | MGMT | ALL | BLOCK | IoT must never reach Proxmox/switches |
| 9 | IOT | CAM | ALL | BLOCK | Cameras isolated from IoT |
| 10 | IOT | IOT | ANY | ALLOW | Allow mDNS / local within VLAN - Avahi reflector handles cross VLAN |
| 11 | IOT | TRUSTED - Home Assistant IP | 8123 TCP, 1883 TCP, 8883 TCP | ALLOW | ONLY to HA for MQTT/API. Replace with your HA IP: 10.10.20.10 |
| 12 | IOT | Internet | 443 TCP, 80 TCP, 123 UDP | ALLOW | For firmware updates and NTP fallback |
| **GUEST (40)** | | | | | |
| 13 | GUEST | RFC1918 (10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16) | ALL | BLOCK | Guest isolation - no local network access |
| 14 | GUEST | Internet | ANY | ALLOW | Guest internet only |
| **CAM (50)** | | | | | |
| 15 | CAM | ANY RFC1918 | ALL | BLOCK | Cameras cannot initiate anywhere |
| 16 | CAM | Internet | ALL | BLOCK | Cameras have zero internet - Frigate is local with TensorRT |
| 17 | CAM exception | TRUSTED - Frigate NVR IP | 554 TCP (if cam needs to push) | BLOCK in ref build | In our build Frigate PULLS, cams do not push. Leave blocked. |
| **IOT_RESTRICTED (60)** | | | | | |
| 18 | IOT_RESTRICTED | Internet | ALL | BLOCK | Totally offline IoT |
| 19 | IOT_RESTRICTED | TRUSTED - HA IP | 1883 TCP | ALLOW | MQTT only to HA |
| **Common Services (All VLANs)** | | | | | |
| 20 | ALL VLANs | OPNsense | 53 TCP/UDP | ALLOW + NAT REDIRECT | Force DNS to AdGuard. Add NAT port forward: redirect all 53 to 10.10.10.1 |
| 21 | ALL VLANs | OPNsense | 123 UDP | ALLOW | NTP |
| 22 | IOT, CAM, IOT_RESTRICTED | OPNsense | 67/68 UDP | ALLOW | DHCP if OPNsense is DHCP server |

### 4. OPNsense Implementation Notes

*   Create aliases: `RFC1918`, `HA_IP (10.10.20.10)`, `Frigate_IP (10.10.20.30)`, `DNS_Server`
*   Rules are applied per interface (VLAN). The CAM interface should have final BLOCK all to RFC1918 + BLOCK all to Internet.
*   For mDNS: Enable Avahi plugin on OPNsense and allow reflection between TRUSTED and IOT only, not GUEST or CAM.
*   For Home Assistant discovery: Allow UDP 5353 mDNS from IOT to HA_IP.

### 5. How To Test (For Contributor)

Test from a device on each VLAN. Log results like this:

`[TEST] 2026-09-29 | Source: IOT (10.10.30.50) > Dest: TRUSTED (10.10.20.10:8123) | Expected: ALLOW | Result: PASS | Notes: HA reachable`

`[TEST] 2026-09-29 | Source: IOT (10.10.30.50) > Dest: TRUSTED (10.10.20.5:445) | Expected: BLOCK | Result: FAIL | Notes: Could ping laptop, rule 7 not working`

Checklist:

- [ ] IOT cannot ping TRUSTED PC
- [ ] IOT CAN ping Home Assistant on 8123 and 1883
- [ ] CAM cannot ping 8.8.8.8
- [ ] CAM cannot ping IOT or TRUSTED (Frigate should still get stream)
- [ ] GUEST cannot ping any 10.10.x.x
- [ ] TRUSTED can ping everything
- [ ] DNS leak test: set device DNS to 8.8.8.8 on IOT, does it still resolve via AdGuard? Should.

Please open a PR with results in `/tests/fw-matrix-results.md`

### 6. Acknowledgments

Contributors to this matrix will be credited in the next edition of the book.

---
Maintained by Alan Cuzen - Reference build HP Z440 + RTX 5060 Ti - Proxmox VE 8.x / OPNsense 24.x / Frigate 0.14 + TensorRT
