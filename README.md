# Healthcare Case Study: Change Healthcare Ransomware Attack (2024)

An interactive, responsive case study focusing on the cybersecurity lessons learned from the **2024 Change Healthcare Ransomware Attack**. Designed as educational material for System Security & Fundamentals.

**Live app:** [https://healthcare-studycase.space/](https://healthcare-studycase.space/)

## 📌 Overview

In early 2024, Change Healthcare (a subsidiary of UnitedHealth Group) suffered a major ransomware attack that disrupted healthcare claim processing and payments nationwide. Attackers gained access via a remote-access portal that lacked Multi-Factor Authentication (MFA), using compromised credentials.

This study examines key architectural vulnerabilities, security risks, and practical countermeasures.

---

## 🧭 App Structure

- **Home:** A welcome banner card and the quick-question card.
- **Missing MFA**, **Outdated Systems**, and **Poor Network Separation:** One page per vulnerability.
- A fixed bottom navigation links every page. Each lesson page also has **Back to home** and **Previous / Next lesson** links.
- A floating **AI study assistant** button sits above the bottom navigation. It opens a chat panel that answers questions about the case study.

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
- [`api/chat.js`](api/chat.js): Vercel serverless function for the AI study assistant.
- [`public/`](public/): The compiled Flutter web build deployed to Vercel.
- [`index.html`](index.html): The original HTML version.
- [`Change_Healthcare_Security.html`](Change_Healthcare_Security.html): The standalone HTML source file.
- [`assets/`](assets/): Font files and images for the Flutter app.
- [`test/navigation_test.dart`](test/navigation_test.dart): Checks the home and lesson navigation.
- [`README.md`](README.md): Project overview and vulnerability analysis.

---

## AI Study Assistant

The floating bubble above the bottom navigation opens a chat panel. Requests go to
`/api/chat`, which tries the providers in this order:

1. **OpenCode Zen** — `OPENCODE_API_KEY`
2. **OpenRouter** — `OPENROUTER_API_KEY`

Both keys are configured in the Vercel project settings. Never put either key in
`lib/main.dart` or any other client-side file.

OpenCode uses `deepseek-v4.1-flash-free`. If it is unavailable, OpenRouter tries
the same model list as the earlier project: `openai/gpt-oss-120b:free`,
`anthropic/claude-opus-4.8:fast`, then `openai/gpt-5.4-nano`.

For local web development, point the app at a running deployment of the API:

```bash
flutter run -d chrome \
  --dart-define=AI_CHAT_ENDPOINT=https://healthcare-studycase.space/api/chat
```

On Android or iOS the endpoint cannot be relative, so always pass a full
`AI_CHAT_ENDPOINT` URL when building a native app.

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
