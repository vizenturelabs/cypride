# Privacy Policy for CypRide

**Last Updated**: May 5, 2026  
**Effective Date**: May 5, 2026  
**App Version**: 1.0+  
**Developer**: Vizenture (Open Source Project)  
**Contact**: vizenture@gmail.com  
**Hosting**: [Link to policy, e.g., https://vizenture.github.io/cypride/privacy]  

---

## 1. Introduction

CypRide ("the Application") is a community-based ride-sharing service for Cyprus, developed by Vizenture as a free, open-source project. This Privacy Policy explains how we handle your data when you use the Application. By using CypRide, you consent to the practices described herein.

*This policy complies with the EU General Data Protection Regulation (GDPR) and Cyprus national data protection laws.*

---

## 2. Information We Collect

### 2.1 Information You Provide
- **Google Account Data** (when signing in via Firebase Authentication):
  - Google account ID (non-sensitive identifier)
  - Display name and profile photo (optional, for rider/driver profiles)
  - Email address (used for account recovery and notifications)

### 2.2 Information Collected Automatically
- **Precise Location Data** (only when you actively use ride features):
  - GPS coordinates during ride request, matching, and trip tracking
  - Location data is processed in real-time and **not stored permanently** on our servers
  - Background location is **not collected** unless explicitly enabled for driver mode (with separate consent)

- **Device Information** (for security and compatibility):
  - Android OS version, device model, app version
  - Crash logs and performance metrics (via Firebase Crashlytics, anonymized)

### 2.3 Information from Third-Party Integrations
- **Telegram/Viber Deep Links**: When you choose to contact a rider/driver via these apps, CypRide only passes the phone number you explicitly share. We do not access messages or contacts from these platforms.

---

## 3. How We Use Your Information

| Data Type | Purpose | Legal Basis (GDPR) |
|-----------|---------|-------------------|
| Google ID & Email | Account creation, authentication, ride history sync | Contractual necessity (Art. 6(1)(b)) |
| Precise Location | Match riders with nearby drivers, calculate routes, ensure safety | Explicit consent (Art. 6(1)(a)) + Legitimate interest (Art. 6(1)(f)) |
| Device Info | Debug crashes, optimize performance, ensure compatibility | Legitimate interest (Art. 6(1)(f)) |
| Profile Photo/Name | Build trust in the ride-sharing community | Explicit consent (Art. 6(1)(a)) |

---

## 4. Data Sharing & Third Parties

We **do not sell** your personal data. Limited sharing occurs only with:

| Third Party | Data Shared | Purpose | Safeguards |
|-------------|-------------|---------|------------|
| **Google Firebase** | Auth tokens, anonymized crash logs | Authentication, app stability | Google's GDPR-compliant Data Processing Agreement |
| **Google Play Services** | Location (only when app is in foreground) | Map rendering, route calculation | On-device processing where possible |
| **Telegram/Viber** | Phone number (only if you initiate contact) | Enable direct messaging | No data retention by CypRide; governed by respective app policies |

All third parties are contractually required to comply with GDPR and process data only for specified purposes.

---

## 5. Data Retention

- **Location Data**: Deleted immediately after ride completion (max 24-hour temporary cache for dispute resolution)
- **Account Data**: Retained while your account is active; deleted within 30 days of account deletion request
- **Crash Logs**: Anonymized and retained for 18 months for quality improvement

---

## 6. Your Rights (GDPR)

As a user in the EU/Cyprus, you have the right to:
- ✅ **Access**: Request a copy of your personal data
- ✅ **Rectify**: Correct inaccurate information
- ✅ **Erase**: Request deletion of your account and associated data ("right to be forgotten")
- ✅ **Portability**: Receive your data in a structured, machine-readable format
- ✅ **Object**: Opt out of non-essential data processing
- ✅ **Withdraw Consent**: Revoke location or profile permissions anytime via app settings

**To exercise these rights**: Email vizenture@gmail.com with subject "GDPR Request – CypRide". We respond within 30 days.

---

## 7. Data Deletion Process

1. Open CypRide → Contact → Telegram → Request account deletion
2. Confirm via email verification
3. All personal data (profile, ride history, auth tokens) is permanently deleted from our systems within 30 days
4. Anonymized analytics data (non-identifiable) may be retained for aggregate service improvement

*Note: Deleting your account does not affect data processed by third parties (e.g., Google) prior to deletion. Contact them directly for their retention policies.*

---

## 8. Children's Privacy

CypRide is **not intended for users under 16** (GDPR age of consent in Cyprus). We do not knowingly collect data from children. If we become aware of underage usage, we will delete the account and data immediately. Parents/guardians may contact us to request removal.

---

## 9. Security Measures

- All data in transit is encrypted via TLS 1.3
- Firebase Authentication uses industry-standard OAuth 2.0
- Location data is processed on-device where possible; server-side processing uses ephemeral storage
- Regular security audits of open-source dependencies

*No system is 100% secure. We implement reasonable safeguards but cannot guarantee absolute security.*

---

## 10. International Data Transfers

As an open-source project, CypRide's backend infrastructure (Firebase) may process data outside the EU. All transfers comply with GDPR Chapter V via:
- EU-U.S. Data Privacy Framework (for Google services)
- Standard Contractual Clauses (SCCs) where applicable

---

## 11. Changes to This Policy

We may update this policy to reflect app improvements or legal changes. Significant changes will be:
- Notified via in-app banner (for active users)
- Posted with a new "Last Updated" date
- Effective 14 days after posting (unless urgent security/legal need)

Continued use after changes constitutes acceptance.

---

## 12. Contact & Supervisory Authority

**For privacy questions or requests**:  
📧 vizenture@gmail.com  
🌐 https://github.com/vizenture/cypride (open-source code repository)

**Cyprus Data Protection Authority** (for complaints):  
Office of the Commissioner for Personal Data Protection  
🌐 www.dataprotection.gov.cy | 📞 +357 22818456

---

*This Privacy Policy was generated for CypRide, an open-source ride-sharing project. Template adapted from GDPR best practices and Google Play Developer guidelines.*
