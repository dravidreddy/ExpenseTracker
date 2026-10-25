# Privacy Policy for Expense Tracker

**Last Updated:** October 25, 2026  
**Application:** Expense Tracker: Minimal & Offline (`com.expensetracker.offline`)  
**Developer:** Dravid Reddy  
**Contact:** [dravidreddy on GitHub](https://github.com/dravidreddy/ExpenseTracker)

---

### 1. Overview & Core Philosophy

Expense Tracker is designed from the ground up on the principle of **Zero-Knowledge, Zero-Friction Privacy**. We believe that your personal finances, spending habits, and income should remain completely confidential and strictly under your control.

Unlike conventional financial applications, Expense Tracker:
- **Does not require account creation or registration.**
- **Does not connect to external servers or cloud databases.**
- **Does not collect, sell, or share personal information.**
- **Does not include third-party advertising or telemetry SDKs.**

---

### 2. Information We Collect

**We collect zero personal data.**

When you use Expense Tracker:
- **Financial Entries:** All amounts, notes, categories, and timestamps entered by you are saved **locally on your physical device only**.
- **No Analytics:** We do not track page views, button clicks, session duration, or user interactions.
- **No Crash Diagnostics Telemetry:** We do not collect device identifiers, IP addresses, MAC addresses, or location data.

---

### 3. Local Storage & Encryption

- **On-Device Storage:** All financial records are stored locally using SQLite / SQLCipher encrypted local databases inside the application's isolated sandbox storage.
- **Cryptographic Protection:** Data at rest is encrypted with industry-standard 256-bit AES encryption.
- **Sandboxed Security:** Neither other third-party apps nor unauthorized processes on your device can access your expense database without your explicit operating system authorization.

---

### 4. Biometric Security & Device Permissions

If you choose to enable the Biometric Lock (Face ID, Touch ID, or Android BiometricPrompt):
- Biometric verification is performed exclusively by your device's hardware Secure Enclave / Android Keystore.
- Expense Tracker **never** has access to, nor does it store or transmit your biometric identifiers, facial geometry, or fingerprint data.
- The app only receives an encrypted cryptographic token from the operating system confirming successful authentication.

---

### 5. Third-Party Services & Trackers

Expense Tracker contains **zero** third-party trackers, ad networks, or data brokers. Specifically, the application does not include:
- Google Analytics / Firebase Analytics
- Meta / Facebook SDK
- Crashlytics / Sentry / Datadog
- Any advertising or affiliate SDKs

Network communication is disabled for core application functions. The app operates seamlessly with airplane mode enabled.

---

### 6. Data Portability, Export, & Deletion

- **Export:** You can export your entire transaction history at any time to standard CSV format. Once exported, the file resides in your device's local file manager or chosen share target.
- **Deletion:** Because we maintain no external servers, deleting the Expense Tracker application from your device immediately and permanently deletes all locally stored data.

---

### 7. Children's Privacy

Expense Tracker does not collect any personal information from anyone, including children under the age of 13.

---

### 8. Changes to This Privacy Policy

Because Expense Tracker operates 100% offline and collects no data, updates to this policy are rare. Any revisions will be reflected with an updated "Last Updated" timestamp in the app repository and official documentation.

---

### 9. Contact & Support

If you have any questions or feedback regarding this Privacy Policy, please open an issue on the official project repository:  
👉 **[https://github.com/dravidreddy/ExpenseTracker](https://github.com/dravidreddy/ExpenseTracker)**
