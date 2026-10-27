<div align="center">

# 🛡️ Mini-SOC in a Box

**A 12-week Blue Team capstone project**
Building a small Security Operations Center from the ground up.

![Status](https://img.shields.io/badge/Status-In%20progress-yellow)
![Focus](https://img.shields.io/badge/Focus-Blue%20Team-blue)
![Duration](https://img.shields.io/badge/Duration-12%20weeks-green)

</div>

---

## 🎯 About the Project

Mini-SOC in a Box is a hands-on learning project where I build a miniature SOC step by step: setting up the lab, deploying a SIEM, detecting suspicious activity, and responding to it. Every week is documented with notes and evidence.

## 🖥️ Lab Overview

| Machine | Role | IP Address |
|---------|------|------------|
| `siem-host` | Security monitoring server | 192.168.56.10 |
| `ubuntu-web` | Monitored Linux machine | 192.168.56.20 |
| `win-client` | Monitored Windows machine | 192.168.56.30 |

All machines run in an isolated virtual network (`192.168.56.0/24`).

## 🗓️ Progress

| Week | Topic | Status |
|------|-------|--------|
| 1 | Lab setup and SIEM deployment | ✅ Done → [`mini-soc-week1`](./mini-soc-week1) |
| 2 | Custom detection rules | ✅ Done → [`mini-soc-week2`](./mini-soc-week2) |
| 3 | Coming soon | ⏳ Planned |
| 4–12 | Coming soon | ⏳ Planned |

## 📂 Repository Structure

```
mini-soc/
├── mini-soc-week1/   # Week 1 – technical details & evidence
├── mini-soc-week2/   # Week 2 – technical details & evidence
└── docker-labs/      # Separate Docker practice labs
```

> Technical details, configurations and screenshots live inside each week's folder.

## 👤 Author

**Farid** · Cybersecurity student
GitHub: [@su-farid](https://github.com/su-farid)

---

<div align="center"><i>Built for learning purposes in an isolated lab environment.</i></div>
