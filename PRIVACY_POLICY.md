# Privacy Policy

**Effective Date:** October 21, 2026  
**Application:** Antigravity (Expense Tracker)  
**Package Name:** `com.stormbreaker.expensetracker`

---

## 1. Overview
Antigravity ("we", "our", or "the app") is designed with a strict **offline-first and zero-knowledge privacy architecture**. We believe your financial data belongs exclusively to you. The app does not collect, track, transmit, or monetize any of your personal or financial data.

## 2. Information We Handle
All data created or processed within Antigravity remains strictly on your local device:
* **Expense Entries & Financial Ledgers:** Stored locally in an encrypted database on your device.
* **Category Preferences & Settings:** Stored locally via Android internal preferences.
* **Biometric Data:** If you enable biometric authentication (fingerprint / face unlock), authentication is managed entirely by Android's native BiometricPrompt API and hardware Keystore. The app never accesses, records, or stores your biometric fingerprints or facial geometry.

## 3. Data Storage & Security
* All transaction records are encrypted on-device using SQLCipher AES-256 encryption.
* Encryption keys are generated and protected locally within the hardware-backed Android Keystore.
* The application runs 100% offline and contains no analytics SDKs, advertising libraries, or telemetry trackers.

## 4. Third-Party Sharing
Because we do not operate backend servers or collect user data, **we cannot and do not sell, rent, or share your data with any third parties**.

## 5. User Control & Data Deletion
In accordance with Google Play User Data policies:
* **Data Portability:** You can export your entire financial history at any time as CSV or JSON from the app settings.
* **Complete Data Deletion:** You have the absolute right to delete all data stored by the app. Using the **"Reset All Data"** option in Settings permanently wipes your database, deletes all local preferences, and resets the app to its factory state.

## 6. Children's Privacy
Antigravity does not collect any personal information from any user, including children under the age of 13.

## 7. Contact & Changes
If you have questions regarding this Privacy Policy, you may contact the development team at:  
`support@stormbreaker.dev`
