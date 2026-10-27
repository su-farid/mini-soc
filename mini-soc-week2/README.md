# Week 2 - Mini-SOC in a Box

## Overview & File Locations
This repository documents the deployment of a Mini-SOC environment using Wazuh SIEM, custom decoders/rules, File Integrity Monitoring (FIM), Suricata NIDS integration, and SCA/Vulnerability Assessment.

- **Custom Rules:** `rules/custom_labshop_rules.xml`
- **Custom Decoders:** `decoders/labshop_decoders.xml`
- **Agent Configurations:** `evidence/week2/ossec_ubuntu.conf`, `evidence/week2/ossec_win.conf`

---

## Task 1: LabShop Log Analysis (Custom Decoder & Rules)

### Test Results Table
| Test Case | Expected Result | `wazuh-logtest` Output | Dashboard Output |
| :--- | :--- | :--- | :--- |
| **1 Failure** | Rule 100101 (Level 5) triggers | Decoded `LOGIN_FAILED`, Rule 100101 matched | Alert generated (Level 5) |
| **6 Failures (1 IP)** | Rule 100102 (Level 10, MITRE T1110) fires within 60s | Six `LOGIN_FAILED` lines from 10.10.10.50 appended to `app.log`; Rule 100102 fired | Brute Force Alert (Level 10, T1110): "LabShop: Brute force attack detected from IP 10.10.10.50" |
| **3 Failures (2 IPs)** | Only Rule 100101 triggers per IP separately | Rule 100101 matched for both IPs independently | Two separate Level 5 alerts |
| **Failure by Monitor** | Rule 100100 (Level 0, Ignored) | Rule 100100 matched (expected noise, ignored) | No alert generated (Filtered) |
| **LOGIN_OK** | Rule 100103 (Level 3) | Decoded `LOGIN_OK`, Rule 100103 matched | Alert generated (Level 3) |
| **Wrong format line** | Only the parent decoder matches, no rule fires | Phase 2: decoder `labshop` only, no fields extracted; no Phase 3 rule | No alert generated |

---

## Task 2: File Integrity Monitoring (FIM)

### Alert Summary Table
| Machine / Object | Alert Type | Rule ID | Level | Description / Meaning |
| :--- | :--- | :--- | :--- | :--- |
| `ubuntu-web` (`/var/www/html/`) | File added / modified / deleted | 554 / 550 / 553 | 5 / 7 / 7 | Real-time web root file change with diff content |
| `ubuntu-web` (`/etc/`) | File added | 554 | 5 | Scheduled check detected configuration file addition |
| `win-client` (`C:\LabShopData`) | File added / modified / deleted | 554 / 550 / 553 | 5 / 7 / 7 | Real-time file addition, modification, and deletion |
| `win-client` (`HKLM\SOFTWARE\LabShop`) | Registry value modified | 750 | 5 | Scheduled check detected registry key value modification |

### Timing & Performance Table
| Monitoring Mode | Target Directory / Object | Measured Alert Time |
| :--- | :--- | :--- |
| **Real-time** | `/var/www/html`, `C:\LabShopData` | ~1–3 seconds |
| **Scheduled** | `/etc`, Windows Registry | Triggered during scheduled scan cycle / Agent restart |

- **Real-time vs Scheduled Trade-off:** Real-time monitoring provides immediate threat detection but consumes higher CPU and I/O resources. Scheduled checks preserve resources but introduce a latency window between scans.
- **Unanswered Question by FIM:** FIM identifies *what* changed and *when*, but cannot identify the specific **User ID or Process ID (PID)** without Auditd or Sysmon log integration.

---

## Task 3: Suricata NIDS Integration

- **Triggered Rule ID:** 100110 (Level 10) / Custom SID 1000001 (*Suricata: High Severity Admin Page Access Attempt*)
- **Memory Footprint:** `ubuntu-web` total memory is 3.8 GiB, with **1.2 GiB used** and **2.5 GiB available** while Suricata is running actively.

---

## Task 4: SCA and Vulnerability Assessment

### Security Configuration Assessment (SCA)
| Machine | Benchmark Policy | Passed | Failed | Not Applicable | Score |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `ubuntu-web` | CIS Ubuntu Linux 24.04 LTS Benchmark v1.0.0 | 119 | 126 | 34 | 48% |
| `win-client` | CIS Microsoft Windows 10 Enterprise Benchmark v4.0.0 | 117 | 302 | 5 | 27% |

#### `ubuntu-web` Hardening Remediation:
1. **Disable SSH Root Login (`PermitRootLogin no`):** Blocks direct administrative SSH connections to prevent credential attack vectors.
2. **Disable IP Forwarding (`net.ipv4.ip_forward = 0`):** Prevents the web server host from functioning as an unauthorized network router.

### Vulnerability Assessment Summary
| Machine | Critical | High | Top CVE Examples | Top Affected Package |
| :--- | :--- | :--- | :--- | :--- |
| `ubuntu-web` | 266 | 1,254 | CVE-2026-101258, CVE-2026-103226, CVE-2026-107705 | `linux-image` (2,982 vulnerabilities) |
| `win-client` | 84 | 2,367 | CVE-2022-41049, CVE-2022-41073, CVE-2022-41091 | `Microsoft Windows` (3,357 vulnerabilities) |

---

## Restoration Instructions
If the Wazuh Manager container is rebuilt or reset, restore custom rules and decoders using:
```bash
docker cp decoders/labshop_decoders.xml single-node-wazuh.manager-1:/var/ossec/etc/decoders/labshop_decoders.xml
docker cp rules/custom_labshop_rules.xml single-node-wazuh.manager-1:/var/ossec/etc/rules/local_rules.xml
docker exec single-node-wazuh.manager-1 chown wazuh:wazuh /var/ossec/etc/decoders/labshop_decoders.xml /var/ossec/etc/rules/local_rules.xml
docker exec single-node-wazuh.manager-1 /var/ossec/bin/wazuh-analysisd -t
docker exec single-node-wazuh.manager-1 /var/ossec/bin/wazuh-control restart
```
