# Healthcare Case Study: Change Healthcare Ransomware Attack (2024)

An interactive, responsive case study focusing on the cybersecurity lessons learned from the **2024 Change Healthcare Ransomware Attack**. Designed as educational material for System Security & Fundamentals.

**Live app:** [https://healthcare-studycase.space/](https://healthcare-studycase.space/)

## 📌 Overview

In early 2024, Change Healthcare (a subsidiary of UnitedHealth Group) suffered a major ransomware attack that disrupted healthcare claim processing and payments nationwide. Attackers gained access via a remote-access portal that lacked Multi-Factor Authentication (MFA), using compromised credentials.

This study examines key architectural vulnerabilities, security risks, and practical countermeasures.

---

## 🔍 Core Security Lessons Analyzed

| # | Weakness | Risk | Recommended Countermeasure |
|---|---|---|---|
| **01** | **Missing MFA** on remote-access portals | Compromised single-factor passwords permit unauthorized external access | Enforce phishing-resistant Multi-Factor Authentication (e.g., FIDO2 security keys) |
| **02** | **Outdated Systems & Legacy Software** | Unsupported systems fail to receive security patches, exposing known CVEs | Establish regular patch testing, vulnerability scanning, and upgrade cycles |
| **03** | **Poor Network Separation / Lack of Micro-segmentation** | Flat network architectures allow lateral movement across systems | Implement zero-trust network segmentation and least-privilege access |

---

## 📂 Repository Contents

- [`lib/main.dart`](lib/main.dart): The Flutter version of the case study.
- [`public/`](public/): The compiled Flutter web build deployed to Vercel.
- [`index.html`](index.html): The original HTML version.
- [`Change_Healthcare_Security.html`](Change_Healthcare_Security.html): The standalone HTML source file.
- [`assets/`](assets/): Font files and images for the Flutter app.
- [`README.md`](README.md): Project overview and vulnerability analysis.

---

## 🚀 Run the Flutter App

```bash
flutter pub get
flutter run -d chrome
```

## 📦 Build and Deploy

```bash
flutter build web --release --base-href /
```

Copy the files from `build/web/` into `public/`, then push the repository. Vercel serves the `public/` folder at
[https://healthcare-studycase.space/](https://healthcare-studycase.space/).

---

## 📚 References & Further Reading

- [CISA Ransomware Guide](https://www.cisa.gov/stopransomware/ransomware-guide)
- [NIST Special Publication 1800-31: Patching Enterprise Systems](https://csrc.nist.gov/pubs/sp/1800/31/final)
