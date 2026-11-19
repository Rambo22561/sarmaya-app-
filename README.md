# Sarmaya Market — Business Investment & Product Ownership Marketplace (Flutter + Firebase)

> **Important Regulatory & Demo Mode Notice:**  
> `AppConstants.isDemoMode` in `lib/core/constants/app_constants.dart` is set to `true` by default. Do **not** enable public fund collection until legal and regulatory requirements in Pakistan (e.g., SECP / SBP compliance) have been formally reviewed and approved.

---

## 1. Tech Stack

- **Frontend (Shared Codebase for Android, Web & Desktop Browsers):** Flutter (Material 3), Dart, Riverpod (`flutter_riverpod`), GoRouter (`go_router`), `fl_chart`, `google_fonts`, `image_picker`
- **Backend & Database:** Firebase Authentication, Cloud Firestore, Firebase Storage, Firebase Cloud Functions (Node 20 / TypeScript), Firebase Cloud Messaging
- **Design System:** Navy Blue (`#0B1F3A`), Crisp White (`#FFFFFF`), Emerald Green (`#10B981`), responsive desktop sidebar + mobile drawer/bottom navigation

---

## 2. Project Structure

```text
lib/
  main.dart
  app.dart
  firebase_options.dart
  core/
    constants/app_constants.dart
    theme/app_theme.dart
    routes/app_router.dart
    services/firebase_service.dart
    services/providers.dart
    utils/formatters.dart
    widgets/common_widgets.dart
    widgets/responsive_shell.dart
  models/
    user_model.dart
    project_model.dart
    payment_request_model.dart
    ownership_model.dart
    financial_models.dart
    community_models.dart
  features/
    authentication/ (Splash, Welcome, Login, Register, VerifyEmail)
    dashboard/
    products/ (Browse Projects, Project Details)
    investment_packs/ (Pack Selection)
    payments/ (Payment Instructions, Upload Payment Proof)
    ownership/ (My Products, My Ownership)
    sales/ (Sales History)
    wallet/ (Wallet, Transaction History)
    withdrawals/ (Withdraw Money)
    subscriptions/ (Monthly Shared Expense Subscription)
    referrals/ (Community Cost-Sharing Referrals)
    notifications/
    profile/
  admin/
    dashboard/
    products/
    payments/
    inventory/
    sales/
    subscriptions/
    withdrawals/
    users/
    reports/
functions/
  src/index.ts         # Trusted Cloud Functions (ownership, ledger, sales profit, buybacks, withdrawals, subscriptions)
firestore.rules        # Hardened Firestore security rules
storage.rules          # Firebase Storage rules for payment proofs & product images
firestore.indexes.json # Composite query indexes
android/               # Android Gradle & Manifest configuration
web/                   # Flutter Web index & manifest
```

---

## 3. Beginner-Friendly Setup Guide (VS Code / Android Studio)

### Prerequisites
1. Install **Flutter SDK (stable >= 3.22)**: https://docs.flutter.dev/get-started/install
2. Install **Node.js 20+** and **Firebase CLI**:
   ```bash
   npm install -g firebase-tools
   dart pub global activate flutterfire_cli
   ```
3. Run `flutter doctor` and confirm Chrome and Android toolchain are ready.

### Step 1: Connect Your Firebase Project
1. Create a Firebase project in the [Firebase Console](https://console.firebase.google.com/).
2. Enable:
   - **Authentication** -> Sign-in method -> **Email/Password**
   - **Cloud Firestore** -> Create database
   - **Firebase Storage** -> Enable bucket
   - **Cloud Functions** -> Upgrade to Blaze plan (required for deploying Cloud Functions)
3. In the project root folder, run:
   ```bash
   firebase login
   flutterfire configure
   ```
   Select **Android** and **Web**. This automatically updates `lib/firebase_options.dart` and creates `android/app/google-services.json`.

### Step 2: Deploy Security Rules, Indexes & Cloud Functions
```bash
cd functions
npm install
npm run build
cd ..
firebase deploy --only firestore:rules,firestore:indexes,storage,functions
```

### Step 3: Create Your First Admin Account
1. Register a normal user in the app.
2. In Firebase Console -> **Firestore Database**, open the `users/{your_uid}` document and change `role` from `"user"` to `"admin"`.
3. Also create a document at `admins/{your_uid}` with `{ "active": true }`.
4. Sign out and sign back in—you will now be routed to the **Admin Operations Console**.

### Step 4: Run the Flutter Application

Install Dart/Flutter dependencies:
```bash
flutter pub get
```

Run on Web (Chrome):
```bash
flutter run -d chrome
```

Run on Android Device / Emulator:
```bash
flutter run
```

Build Release Android APK:
```bash
flutter build apk --release
```
The output APK will be at `build/app/outputs/flutter-apk/app-release.apk`.

---

## 4. Financial & Business Rules Enforced by Cloud Functions

- **Manual Payment Verification:** Payments via Easypaisa, JazzCash, or Bank Transfer are stored as `pending`. Only an admin can approve them (`approvePaymentRequest`), which atomically deducts stock, creates an `ownership_records` document, updates `wallets`, and writes double-entry `ledger_entries`.
- **Sales & Profit Distribution:** `recordProductSale` calculates `distributableProfit = grossRevenue - allocatedProductCost - eligibleExpenses`, deducts a **10% platform commission** only when `distributableProfit > 0`, returns original capital separately from realized profit, and distributes proportionally to active ownership records.
- **Buyback Workflow:** User requests buyback (`10%` default deduction) -> Admin confirms price & liquidity -> User accepts or rejects -> Ownership transfers to `bought_back` and wallet is credited.
- **Monthly Expense Sharing:** `recalculateMonthlySubscription` divides total monthly expenses (`office_rent`, `electricity`, `petrol`, `transportation`, `salaries`, `packaging`, `other`) by eligible active paying members, supports promotional Rs. 1 periods with start/end dates, and tracks surplus/shortfall.
- **Referrals (No MLM / No Cash Rewards):** Referrals prevent self-referrals and duplicates, and solely increase the eligible active member count to lower shared monthly operating costs.
