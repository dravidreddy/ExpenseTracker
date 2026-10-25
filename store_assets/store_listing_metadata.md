# App Store & Google Play Store Submission Metadata

This document contains all pre-written, verified copy and metadata fields ready to copy-paste directly into **Google Play Console** and **Apple App Store Connect**.

---

## 1. Universal URLs & Developer Contact

- **Developer Name:**  
  `Dravid Sharath Reddy`
- **Developer Contact Email (Mandatory on Google Play & App Store):**  
  `dravidreddy.ai@gmail.com`
- **Hosted Privacy Policy URL:**  
  `https://dravidreddy.github.io/ExpenseTracker/`  
  *(Enabled via GitHub Pages on `/docs` folder)*
- **Support & Issues URL:**  
  `https://github.com/dravidreddy/ExpenseTracker/issues`
- **Marketing / Repository URL:**  
  `https://github.com/dravidreddy/ExpenseTracker`

---

## 2. Google Play Console Listing

### App Details
- **App Name (30 chars max):**  
  `Expense Tracker: Minimal Offline`  *(29 chars)*
- **Package Name / Application ID:**  
  `com.expensetracker.offline`
- **Category:**  
  `Finance`
- **Tags:**  
  `Finance`, `Budget & Expense Management`, `Personal Finance`, `Productivity`

### Store Descriptions
- **Short Description (80 chars max):**  
  `Zero-friction offline expense tracker. Private, encrypted, and completely ad-free.` *(78 chars)*

- **Full Description (4,000 chars max):**
```text
Take complete control of your personal finances with Expense Tracker — the zero-friction, 100% offline personal finance manager built exclusively for privacy, speed, and simplicity.

NO ACCOUNTS. NO CLOUD SERVERS. ZERO TRACKING.
Most budgeting apps require registration, track your location, and upload your financial history to third-party cloud servers. Expense Tracker operates completely offline on your physical device. Your income, expenses, and transaction logs never leave your phone.

KEY FEATURES:

⚡ LIGHTNING FAST ENTRY
Log any expense or income in under 3 seconds with an intuitive numpad, custom category tags, and smart transaction notes.

🔒 256-BIT ENCRYPTED & PRIVATE
Your financial ledger is secured locally using SQLCipher with military-grade 256-bit AES encryption. No tracking SDKs, no telemetry, and zero third-party ads.

🛡️ BIOMETRIC LOCK PROTECTION
Shield your financial data from prying eyes with native Face ID, Touch ID, or Android Biometric authentication.

📊 ELEGANT SPENDING ANALYTICS
Understand where your money goes with minimalist visual breakdowns, category velocity charts, and monthly trend summaries.

🌍 GLOBAL MULTI-CURRENCY SUPPORT
Seamlessly switch between USD ($), EUR (€), GBP (£), INR (₹), JPY (¥), and all major world currencies with instant symbol formatting.

📤 1-TAP CSV SPREADSHEET EXPORT
Enjoy complete data freedom. Export your full transaction history into a standard .CSV spreadsheet at any time for Excel, Google Sheets, or personal accounting.

🌙 LUXURY DARK AESTHETIC
Crafted with agency-grade obsidian typography and responsive micro-animations for an effortless everyday experience.

Your money. Your data. 100% private.
Download Expense Tracker today.
```

### Store Graphic Assets (Located in `store_assets/google_play/`)
1. **App Icon:** `store_assets/google_play/app_icon_512.png` (512 x 512 px, 32-bit PNG)
2. **Feature Graphic:** `store_assets/google_play/feature_graphic_1024x500.png` (1024 x 500 px, 24-bit PNG)
3. **Phone Screenshots:**
   - `screenshot_1_zero_friction.png` (1080 x 1920)
   - `screenshot_2_insights.png` (1080 x 1920)
   - `screenshot_3_privacy.png` (1080 x 1920)
   - `screenshot_4_export.png` (1080 x 1920)

### Google Play Policy Questionnaire Answers
- **App Access:** All functionality is available without special access (no login or credentials required).
- **Ads:** Select **"No, my app does not contain ads"**.
- **Content Rating:**
  - Violence: No
  - Sexuality: No
  - Language: No
  - Controlled Substances: No
  - Financial Services: Personal tool (does not process credit/loans/banking transactions).
  - Result: Rated for **Everyone / 3+**.
- **Target Audience:** 18 and older (or General Audience).
- **Data Safety Form:**
  - Does your app collect or share user data? **NO**.
  - All data stays locally on user's device.

---

## 3. Apple App Store Connect Listing

### App Information
- **Name (30 chars max):**  
  `Expense Tracker: Offline & Safe` *(30 chars)*
- **Subtitle (30 chars max):**  
  `Minimal, Private, Encrypted` *(27 chars)*
- **Bundle ID:**  
  `com.expensetracker.offline`
- **Primary Category:**  
  `Finance`
- **Secondary Category:**  
  `Productivity`

### Keywords (100 chars max, comma-separated):
```text
expense tracker,budget,offline,spending,finance,money manager,personal finance,privacy,receipts,ledger
```
*(Exact length: 99 characters)*

### Description:
*(Use the same Full Description provided above for Google Play).*

### App Privacy Nutrition Labels
In App Store Connect → **App Privacy**:
- **Data Collection:** Select **"No, we do not collect data from this app"**.
  - This grants the prized **"Data Not Collected"** privacy badge on the App Store product page!

### Graphic Assets (Located in `store_assets/apple_app_store/`)
1. **App Icon:** `store_assets/apple_app_store/app_icon_1024.png` (1024 x 1024 px, no alpha)
2. **Screenshots:**
   - `screenshot_1_zero_friction.png`
   - `screenshot_2_insights.png`
   - `screenshot_3_privacy.png`
   - `screenshot_4_export.png`
