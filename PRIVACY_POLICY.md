# Privacy Policy

**Effective Date:** October 25, 2026  
**Application:** Expense Tracker  
**Developer:** Expense Tracker Team  
**Bundle ID / Package Name:** `com.expensetracker.offline`

---

## 1. Overview
Expense Tracker ("we", "our", or "the app") is designed with a strict **offline-first, zero-knowledge privacy architecture**. We believe your personal financial data belongs exclusively to you. The app does not collect, track, transmit, monetize, or share any of your personal or financial data.

## 2. Information We Handle
All data created or processed within Expense Tracker remains strictly on your physical device:
* **Expense Entries & Financial Ledgers:** Stored locally on your device in an encrypted database.
* **Category Preferences & Settings:** Stored locally via internal operating system preferences.
* **Biometric Data:** If you enable biometric authentication (Face ID, Touch ID, Fingerprint, or screen passcode), authentication is performed solely by the operating system (Android BiometricPrompt / iOS LocalAuthentication). The app never accesses, records, or stores your biometric fingerprints or facial geometry.

## 3. Data Storage & Security
* All transaction records are encrypted on-device using SQLCipher AES-256 encryption.
* Encryption keys are generated and protected locally within the hardware-backed secure enclave (Android Keystore / iOS Keychain).
* The application runs 100% offline and contains zero analytics SDKs, zero advertising libraries, and zero network telemetry trackers.

## 4. Third-Party Sharing
Because we do not operate backend servers or collect user data, **we cannot and do not sell, rent, or share your data with any third parties**.

## 5. User Control & Data Deletion
In accordance with Google Play and Apple App Store User Data policies:
* **Data Portability:** You can export your entire financial history at any time as CSV or structured JSON from the app settings.
* **Complete Data Deletion:** You have the absolute right to delete all data stored by the app. Using the **"Reset All Data"** option in Settings permanently destroys your encrypted database, deletes all local preferences, and resets the app to its factory state. All data is also automatically purged if you uninstall the app.

## 6. Children's Privacy
Expense Tracker does not collect any personal information from any user, including children under the age of 13.

## 7. Contact
If you have questions regarding this Privacy Policy, you may contact:  
`privacy@expensetracker.app`
