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

Screenshots: `evidence/week2/screenshots/ss_task1_*.png` (logtest for each case, brute force alert in the dashboard).

**Persistence:** decoder (`labshop_decoders.xml`) and rules (`local_rules.xml`) live in the manager's custom folders, never in the shipped ones. Rule IDs are in the 100100-100199 range. XML was validated with `wazuh-analysisd -t` before every restart.

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
| **Scheduled** | `/etc` (frequency 3600 s) | Runs on the scheduled scan cycle or at agent restart |
| **Scheduled** | `HKLM\SOFTWARE\LabShop` (frequency 3600 s) | Registry monitoring is scheduled only; alert raised after scan/agent restart |

- **Real-time vs Scheduled Trade-off:** Real-time monitoring provides immediate threat detection but consumes higher CPU and I/O resources. Scheduled checks preserve resources but introduce a latency window between scans.
- **Unanswered Question by FIM:** FIM identifies *what* changed and *when*, but cannot identify the specific **User ID or Process ID (PID)** without Auditd or Sysmon log integration.

---

## Task 3: Suricata NIDS Integration

- **Sensor:** Suricata on `ubuntu-web`, watching the lab interface `ens33`.
- **Custom Suricata rule:** SID `1000001` *LABSHOP Admin Page Access Attempt* alerts on an HTTP request containing `/admin` to the web server.
- **Log forwarding:** `/var/log/suricata/eve.json` is read by the Wazuh agent (`log_format json`, see `evidence/week2/ossec_ubuntu.conf`).
- **Wazuh rule 100110 (Level 10):** child of Wazuh's Suricata alert rule `86601` (default Level 3), matching `alert.signature_id = 1000001`. It raises only my own Suricata alert, not other Suricata events.

### Test results
| Request (from Dell `192.168.56.1`) | Expected | Result |
| :--- | :--- | :--- |
| `curl http://192.168.56.20/admin` | Suricata alert SID 1000001 | Alert visible in the Wazuh dashboard (`ss_task3_dashboard_suricata.png`) |

### Memory footprint
`ubuntu-web` total memory is 3.8 GiB, with **1.2 GiB used** and **2.5 GiB available** while Suricata is running (`ss_task3_ram_usage.png`).

---

## Task 4: SCA and Vulnerability Assessment

### Security Configuration Assessment (SCA)
| Machine | Benchmark Policy | Passed | Failed | Not Applicable | Score |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `ubuntu-web` | CIS Ubuntu Linux 24.04 LTS Benchmark v1.0.0 | 119 | 126 | 34 | 48% |
| `win-client` | CIS Microsoft Windows 10 Enterprise Benchmark v4.0.0 | 117 | 302 | 5 | 27% |

#### `ubuntu-web` hardening
| Failed check fixed | Why it matters |
| :--- | :--- |
| SSH root login disabled (`PermitRootLogin no`) | Blocks direct administrative SSH logins, removing a common credential attack target. |
| IP forwarding disabled (`net.ipv4.ip_forward = 0`) | Stops the host from acting as an unauthorized router between networks. |

- **Lock-out care:** the brief warns against changing SSH and network settings. Only these two single settings were changed, the previous values are in the journal for undo, and SSH was reconnected successfully after `sshd` restarted (one session dropped during the restart).

### Vulnerability Assessment Summary
| Machine | Critical | High | Medium | Low | Pending evaluation | Most affected package |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `ubuntu-web` | 266 | 1,254 | 932 | 161 | 1,134 | `linux-image-7.0.0-*` (2,982), `firefox` (663) |
| `win-client` | 84 | 2,367 | 895 | 11 | 0 | `Microsoft Windows` (3,357) |

Screenshots: `ss_task4_sca_*.png`, `ss_task4_vuln_*.png`.

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

---

## Documentation
- Journal: `journal.md` (five entries, each with purpose and undo, plus a noise tuning note).
- Nothing secret is stored in Git (`ossec_ubuntu.conf` only references the `authd.pass` path, no password).
