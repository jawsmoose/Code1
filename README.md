# PaycheckPilot 💸

A clean, modern iOS app that reads your bank, card and investment statements and gives **every dollar of every paycheck a job** — covering essentials, paying down debt (mortgage, loans, credit cards), funding savings goals (vacations, remodels), and investing the rest. The plan and a personalized money-saving tip refresh **automatically every day** based on your recent spending habits.

## Features

### 📥 Statement import
- Import **CSV, OFX and QFX** files from any bank, credit card or brokerage (Files app / iCloud Drive picker).
- Robust CSV parsing: quoted fields, `Amount` or split `Debit`/`Credit` columns, many date formats.
- Every transaction is **auto-categorized** by a rules engine (groceries, dining, utilities, subscriptions, debt payments, investing, …) and can be recategorized with a tap.
- Duplicate detection means you can re-import overlapping statements safely.

### 🧮 Every-dollar paycheck allocation
The allocation engine builds a plan for your next paycheck, in priority order:
1. **Essentials** — sized from your actual last-90-day spending (housing, groceries, utilities, transport, insurance, …), normalized to your pay frequency.
2. **Debt minimums** — required payments for every debt you track (mortgage, auto loan, cards), with APRs shown.
3. **Guilt-free spending** — a discretionary budget deliberately trimmed a configurable % below your recent pace.
4. **Free dollars** — split by adjustable weights across:
   - **Extra debt paydown** using **Avalanche** (highest APR first) or **Snowball** (smallest balance first),
   - **Savings goals**, funded by urgency (amount remaining ÷ paychecks until the target date), and
   - **Investing** into your brokerage/retirement account.
5. **Cash buffer** — rounding leftovers, so the lines always sum to the exact paycheck.

No paycheck configured? The app estimates one from your imported payroll deposits. No history yet? It falls back to the 50/30/20 guideline until data arrives.

### 🌅 Daily updates & spending tips
- A **BGTaskScheduler** background refresh regenerates the plan each morning; a foreground fallback runs it on first open each day.
- A **new tip every day**, chosen from the discretionary categories you actually overspend in, quantified with your real 30-day numbers ("You've spent $214 on dining out…"), and always pointing the freed-up dollars at your **highest-APR debt or most urgent goal**.

### 📊 Reports & trends
- Donut chart of where the money went (last 30 days).
- 6-month stacked bars: essentials vs. discretionary vs. debt & saving.
- Discretionary trend line vs. your 6-month average, with plain-English coaching.
- One-tap **shareable Markdown report**: cash flow, category breakdown, top merchants, debt snapshot, goal progress and the current plan.

### 💾 Storage & sync
- All data is persisted locally in **SwiftData** (Core Data-backed) — works fully offline.
- Optional **Firebase Cloud Firestore** mirroring of a JSON snapshot on every plan update (see below), plus a local JSON backup and a full JSON export via the share sheet.

## Project layout

```
PaycheckPilot/
├── PaycheckPilotApp.swift        # App entry, SwiftData container, BG task registration
├── Models/Models.swift           # SwiftData models + enums (accounts, transactions, goals, plans, settings)
├── Services/
│   ├── AllocationEngine.swift    # Every-dollar paycheck allocation
│   ├── CategorizationEngine.swift# Rules-based transaction categorization
│   ├── CSVStatementParser.swift  # Bank/brokerage CSV exports
│   ├── OFXStatementParser.swift  # OFX/QFX (Quicken) downloads
│   ├── StatementImportService.swift # File import + dedupe pipeline
│   ├── InsightsEngine.swift      # Rolling totals, trends, savings rate
│   ├── TipsEngine.swift          # Personalized daily tip rotation
│   ├── PlanService.swift         # Orchestrates the daily plan cycle
│   ├── DailyRefreshManager.swift # BGTaskScheduler daily refresh
│   ├── SyncService.swift         # JSON snapshot + local backup + Firestore mirror
│   ├── ReportGenerator.swift     # Shareable Markdown reports
│   └── SampleData.swift          # Deterministic demo dataset
└── Views/                        # SwiftUI: Dashboard, Activity, Debts & Goals, Reports, Settings
```

## Getting started

1. Open `PaycheckPilot.xcodeproj` in **Xcode 16+** (iOS 17 deployment target).
2. Select your signing team under *Signing & Capabilities*.
3. Run on a simulator or device.
4. Tap **"Or explore with sample data"** on the Activity tab (or Settings → Load sample data) to see the full experience immediately, then erase it and import your own statements.

> Note: iOS decides when background refresh actually runs (and the simulator never fires it). The app also refreshes the plan on the first foreground each day, so the daily update works regardless.

## Enabling Firebase sync (optional, two steps)

The app compiles and runs without Firebase; backups are then written to a local JSON file. To mirror backups to Cloud Firestore:

1. In Xcode: *File → Add Package Dependencies…* → `https://github.com/firebase/firebase-ios-sdk` → add **FirebaseFirestore** (and FirebaseCore) to the PaycheckPilot target.
2. Create an iOS app in the [Firebase console](https://console.firebase.google.com), download `GoogleService-Info.plist`, and drop it into the `PaycheckPilot/` folder in Xcode.

That's it — the sync code is behind `#if canImport(FirebaseFirestore)` and activates automatically. Turn on *Settings → Backup & cloud sync* in the app. Remember to lock down your Firestore security rules before shipping.

## Roadmap ideas

- Direct bank connections (Plaid/Finicity) instead of file import
- Push notification for the daily tip
- Widgets for the current plan and debt-free countdown
- Multi-device merge sync (current Firestore sync is a one-way backup snapshot)

## Disclaimer

PaycheckPilot is a personal-finance organizer. It provides informational suggestions only — not financial advice.
