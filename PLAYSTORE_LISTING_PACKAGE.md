# 🚀 Google Play Store Listing & Data Safety Package

**Application Name:** Antigravity: Offline Expense Tracker  
**Package Name:** `com.stormbreaker.expensetracker`  
**Target Category:** Finance / Personal Finance  
**Content Rating:** Everyone (PEGI 3 / ESRB Everyone)  
**Binary Path:** [`build/app/outputs/bundle/release/app-release.aab`](file:///c:/Users/dravi/OneDrive/Desktop/ExpenseTracker/build/app/outputs/bundle/release/app-release.aab)  
**Obfuscation Symbols:** [`build/symbols/`](file:///c:/Users/dravi/OneDrive/Desktop/ExpenseTracker/build/symbols)  

---

## 1. Store Listing Copy

### App Title (30 characters max)
```
Antigravity: Expense Tracker
```
*(28 characters)*

### Short Description (80 characters max)
```
Fast, private offline expense tracker with AES-256 encrypted storage. No ads.
```
*(78 characters)*

### Full Description (4,000 characters max)
```markdown
Antigravity is a lightning-fast, privacy-first personal expense tracker engineered for speed and absolute confidentiality. Log any expense in under 3 seconds with zero ads, zero tracking, and zero cloud lock-in.

🛡️ ZERO-NETWORK PRIVACY & LOCAL ENCRYPTION
Unlike conventional finance apps that sync your confidential spending habits to third-party servers, Antigravity requires NO INTERNET PERMISSION. 
• 100% Offline by Design: Your data never leaves your physical device.
• AES-256 SQLCipher Database: All expense entries and ledger records are locally encrypted using hardware-backed cryptographic keys.
• Biometric Lock & Device PIN: Secure your financial records with fingerprint/face recognition or device passcode.
• Screenshot Protection: Protects your financial history from recent-app task switcher scrapers.

⚡ LOG IN UNDER 3 SECONDS
• Smart Auto-Categorization: Intelligent on-device keyword engine automatically tags expenses as you type (e.g., "starbucks" → Food & Drinks, "uber" → Travel).
• Minimal Friction: Clean, ergonomic number pad tailored for rapid one-handed expense entry.
• Dynamic Visual Feedback: Category badges instantly adapt to provide immediate spending clarity.

📊 TIMELINE & MONTHLY INSIGHTS
• Daily & Monthly Breakdowns: Visualize your spending velocity across customizable calendar views.
• Category Slices: Track where your money goes with detailed percentage breakdowns.
• Multi-Currency Support: Switch seamlessly between USD ($), EUR (€), GBP (£), INR (₹), JPY (¥), and more.

💾 FULL DATA OWNERSHIP & PORTABILITY
• Instant Data Wipe: Google Play-compliant one-tap dual-confirmation ledger reset whenever you want a fresh start.
• Portable Backup: Export encrypted, versioned JSON backups to external storage, SD cards, or your preferred personal drive.
• Seamless Ledger Restore: Easily restore your complete transaction history on a new device with zero cloud dependencies.
• CSV Spreadsheets: Export standard CSV reports for Excel, Google Sheets, or tax accounting.

✨ HIGHLIGHTS
• No registration or account creation required
• No advertising, promotional popups, or telemetry
• Zero background battery drain
• Sleek, dark-mode optimized interface
• Built for speed, security, and financial peace of mind

Take control of your personal finances with Antigravity.
```

---

## 2. Google Play Console Data Safety Questionnaire Answers

When completing the **App Content → Data Safety** section in the Google Play Console, use the following exact responses:

### Step 1: Data Collection & Sharing
- **Does your app collect or share any of the required user data types?**  
  👉 **Select: NO**
- **Is all of the user data collected by your app encrypted in transit?**  
  👉 **Select: NOT APPLICABLE (No data is transmitted over a network)**
- **Do you provide a way for users to request that their data be deleted?**  
  👉 **Select: YES** (Users can wipe all data directly via Settings → Reset All Data, and all data is permanently erased upon app uninstall).

### Step 2: Specific Data Categories
All checkboxes (Location, Personal Info, Financial Info, Health, Messages, Photos, Audio, Files, Calendar, Contacts, App Activity, Web Browsing, App info, Device/Other IDs) should be **UNCHECKED**.

---

## 3. App Content & Policy Declarations

| Section | Declaration | Notes |
|---|---|---|
| **Privacy Policy** | Enter URL hosting [`PRIVACY_POLICY.md`](file:///c:/Users/dravi/OneDrive/Desktop/ExpenseTracker/PRIVACY_POLICY.md) | Can be hosted on GitHub Pages or personal domain. |
| **Ads** | Select **"No, my app does not contain ads"** | Verified: Zero ad SDKs bundled. |
| **App Access** | Select **"All functionality is available without restrictions"** | No login, signup, or subscription required. |
| **Financial Features** | Select **"Personal Finance Management"** | Note: Offline manual logging only; no banking credentials or payments processed. |
| **Target Audience** | Select **Age 18 and over** (or 13+) | Not directed at children under 13. |
| **News / COVID-19 / Govt** | Select **"No"** for all | N/A |

---

## 4. Store Graphics & Media Specifications

| Asset | Dimensions | Format | Requirement |
|---|---|---|---|
| **App Icon** | 512 x 512 px | 32-bit PNG (max 1024 KB, no transparency) | High-res version of the emerald delta logo. |
| **Feature Graphic** | 1024 x 500 px | PNG or JPEG (max 15 MB, no transparency) | Dark gradient banner featuring app name and headline. |
| **Phone Screenshots** | Min 2, Max 8 (e.g. 1080 x 2400 px or 1080 x 1920 px) | PNG or JPEG | Recommended screens: (1) Home Screen quick entry, (2) Timeline breakdown, (3) Settings & Security. |

---

## 5. Google Play Closed Testing Checklist (14-Day Tester Requirement)

> [!IMPORTANT]
> If your Google Play Console developer account was registered as a personal account after **November 13, 2023**, Google requires **at least 12 testers opted in for at least 14 days** before you can apply for Production access.

1. In Play Console, navigate to **Testing → Closed testing**.
2. Click **Create track** (e.g., named "Alpha" or "Closed Beta").
3. Under **Testers**, create an email list with at least 12 Google accounts (friends, colleagues, or test devices).
4. Upload [`build/app/outputs/bundle/release/app-release.aab`](file:///c:/Users/dravi/OneDrive/Desktop/ExpenseTracker/build/app/outputs/bundle/release/app-release.aab).
5. In **App Bundle Explorer**, upload the de-obfuscation symbol files from [`build/symbols/`](file:///c:/Users/dravi/OneDrive/Desktop/ExpenseTracker/build/symbols).
6. Copy the **Opt-in link** and share it with your 12 testers.
7. Ensure all 12 testers accept the invite and keep the app installed for 14 continuous days.
8. On Day 15, click **Apply for Production** in the dashboard!
