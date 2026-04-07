# DeciDish — Supervisor Project Report

**Document type:** Status and technical summary for supervision review  
**Project:** DeciDish — cross-platform meal decision and social food application  
**Date:** 30 March 2026  

---

| Field | Details |
|--------|---------|
| **Student / developer** | *[Name]* |
| **Student ID** | *[If applicable]* |
| **Programme / course** | *[e.g. BSc Computer Science — Final Year Project]* |
| **Supervisor** | *[Name]* |
| **Institution** | *[Name]* |

---

## Executive summary

DeciDish is a **Flutter** mobile client with a **Node.js, Express, and MongoDB** backend. The application supports **account creation and login**, **personalized meal recommendations**, **preferences and dietary constraints**, **favorites and meal history**, **daily engagement features (e.g. streaks/check-ins)**, **a browsable meal library**, **social features** (feed, friends, messaging), and **push notifications** via **Firebase Cloud Messaging**.  

Substantial implementation exists on both client and server. The product is **not yet configured for public production**: the mobile app’s API base URL is set for **local development**, and **store deployment** (signing, listings, privacy compliance) remains to be completed. A separate technical report in this repository (`docs/ACADEMIC_REPORT.md`) documents specific UX and algorithmic refinements (survey flow, meal-type consistency, cuisine diversity, library, external links).  

This report is intended for **supervisor review**: it summarizes scope, deliverables, gaps, and a clear path to **Android and iOS release**.

---

## 1. Introduction and objectives

### 1.1 Problem statement

Many people struggle to decide what to cook or eat while respecting **health goals, allergies, and taste**. DeciDish aims to reduce that friction through **preference-aware recommendations**, **structured “help me decide” flows**, and **optional social discovery** (friends and feed).

### 1.2 Project objectives (as implemented in scope)

1. Deliver a **cross-platform mobile client** (Flutter) consuming a **REST API**.  
2. Provide **secure authentication** (registration, login, session token storage on device).  
3. Expose **meal discovery and recommendations** aligned with user and dietary data.  
4. Support **favorites**, **history**, and **profile/preferences** backed by persistent storage.  
5. Extend the system with **social and messaging** features where the backend and UI exist.  
6. Prepare a **documented path** to production deployment and app store submission.

---

## 2. System architecture

| Layer | Technology | Role |
|--------|------------|------|
| Mobile app | Dart / Flutter | UI, navigation, local token storage (`shared_preferences`), HTTP clients to API |
| API | Node.js, Express | REST endpoints, JWT-protected routes, business logic |
| Data | MongoDB, Mongoose | Users, meals, favorites, history, friends, messages, posts, feed, etc. |
| Push | Firebase (FCM) | Device messaging; Android `google-services.json` and iOS `GoogleService-Info.plist` are present |

**Configuration note:** `lib/config/api_config.dart` resolves the API to **localhost** (and **10.0.2.2** on Android emulator) for development. A **production HTTPS URL** must replace this before end users can use a hosted backend.

---

## 3. What has been delivered (deliverables)

### 3.1 Flutter application

- **Onboarding and authentication:** welcome, login, signup, onboarding; route-based navigation with transitions (`lib/main.dart`, `lib/screens/`).  
- **Main shell:** bottom navigation with **Home**, **Feed**, **Chats**, **Favorites**, **Profile** (`lib/screens/main_navigation_screen.dart`).  
- **Meal features:** home, recommendations, meal library, pantry, preferences (including enhanced preferences), survey widgets (“help me decide”).  
- **User data:** favorites and history screens wired to API services; profile and related flows.  
- **Social:** friends, friend requests, add friend, friend posts, feed, chat, notifications screen.  
- **Services layer:** dedicated API modules under `lib/services/` (auth, meals, favorites, history, users, feed, posts, messages, friends, streaks, surveys, push notifications, etc.).  
- **Shared UI:** colors, transitions, streak widget, meal images, review sheet, app logo (`lib/widgets/`, `lib/utils/`).

### 3.2 Backend application

- **REST API** mounted in `backend/server.js`, including:  
  `/api/auth`, `/api/users`, `/api/meals`, `/api/recommendations`, `/api/favorites`, `/api/history`, `/api/friends`, `/api/messages`, `/api/posts`, `/api/feed`, and `/api/health`.  
- **Data models and routes** under `backend/models/` and `backend/routes/`.  
- **Supporting services** (e.g. meal scoring, preferences, pantry matching, survey meals) under `backend/services/`.  
- **Scripts and documentation** for MongoDB connection, seeding, and imports (`backend/scripts/`, `backend/*.md`).

### 3.3 Documentation in the repository

| Document | Purpose |
|----------|---------|
| `PUBLISHING_GUIDE.md` | End-to-end checklist: production DB, API deployment, Flutter config, signing, Play Store and App Store steps |
| `COMPLETE_IMPLEMENTATION_SUMMARY.md` | Feature-oriented summary of connected screens and data storage |
| `docs/ACADEMIC_REPORT.md` | Detailed report on specific engineering changes (survey navigation, meal-type integrity, diversity, library, links, navigation order) |
| `API_CONNECTION_STATUS.md` | **Note:** may be outdated relative to current code; verify against `lib/services/` before citing in assessment |

Root `README.md` is still a **default Flutter template** and should be updated for external readers.

---

## 4. Recent and notable technical work (summary)

For **examiner- or supervisor-level detail** on specific design decisions (survey stack behaviour, backend meal-type constraints, cuisine diversity when preferences are empty, food library, URL handling, list imagery, tab order), refer to **`docs/ACADEMIC_REPORT.md`** Sections 4–7. That document also provides a **verification table** and **limitations**.

---

## 5. Current limitations and risks

1. **Environment:** Client points to **development** hosts unless `api_config.dart` is updated for production.  
2. **Operations:** Backend must be **deployed**, **secured (HTTPS)**, and **monitored**; MongoDB must be **backed up**.  
3. **Testing:** `test/widget_test.dart` still reflects the **default counter template** and does not reflect the real app; automated tests need alignment with project policy.  
4. **Stores:** **Privacy policy**, **terms**, data safety disclosures, and **store assets** (screenshots, descriptions) are required for public listing.  
5. **Third-party data:** Meal corpus size depends on import sources; scalability of client-side library search is discussed in `ACADEMIC_REPORT.md`.

---

## 6. Roadmap: from current state to “live” Android and iOS

The following is the **minimum coherent sequence** for a production-capable release (expanded in `PUBLISHING_GUIDE.md`).

### Phase A — Backend production

1. Provision **production MongoDB** (e.g. Atlas) and **secrets** (`MONGODB_URI`, `JWT_SECRET`, etc.).  
2. Deploy the API to a **hosted environment** with **HTTPS** and appropriate **CORS** for the app.  
3. Verify `/api/health` and critical authenticated flows against the production URL.

### Phase B — Mobile app configuration

1. Set **`lib/config/api_config.dart`** `baseUrl` to the **production API** (HTTPS).  
2. Confirm **push notifications** on physical **Android** and **iOS** devices (APNs setup for iOS).  
3. Update **app metadata:** `pubspec.yaml` version/build, display names, icons (Android mipmaps, iOS asset catalog).

### Phase C — Release builds and distribution

1. **Android:** configure **release signing**; build **AAB** (`flutter build appbundle --release`); upload to **Google Play Console**.  
2. **iOS:** **Apple Developer** membership, **signing & capabilities** in Xcode; build and **archive**; distribute via **TestFlight** then **App Store Connect**.  
3. Complete **store questionnaires**, **content rating**, and **privacy** sections.

### Phase D — Post-launch (recommended)

- Error reporting (e.g. Crashlytics), analytics, staged rollouts, and user feedback channels.

---

## 7. Conclusion

DeciDish exists as a **functionally broad** student or capstone-scale system: **client and server codebases are in place**, **major features are implemented**, and **written guides** describe publishing. The remaining work to present the application as **“live” to end users** is primarily **infrastructure and release engineering** (production API URL, hosted backend, signing, store compliance), plus **documentation cleanup** and **testing** aligned with module requirements.

For **deep-dive technical narrative**, use **`docs/ACADEMIC_REPORT.md`**. For **operational checklists**, use **`PUBLISHING_GUIDE.md`**.

---

## 8. References (internal)

1. `docs/ACADEMIC_REPORT.md` — detailed implementation and limitations.  
2. `PUBLISHING_GUIDE.md` — store and deployment procedures.  
3. `COMPLETE_IMPLEMENTATION_SUMMARY.md` — feature and storage overview.  

*[Add external references and course-required citations as directed by your institution.]*

---

## Appendix A — Suggested slides (if presenting orally)

1. Title: project name, your name, supervisor, date.  
2. Problem and goals (1 slide).  
3. Architecture diagram: Flutter → HTTPS API → MongoDB; Firebase for push.  
4. Screenshots: Home, recommendation, library, feed or friends (choose 3–4).  
5. What is done vs what remains (two columns).  
6. Roadmap: production API → configure app → build AAB/IPA → stores.  
7. Risks: dev URL, testing, privacy.  
8. Q&A.

---

## Appendix B — Exporting this report to PDF

- **Option A (repository script):** From the project root, with Python 3 and `fpdf2` installed (`pip install fpdf2`), run:  
  `python3 docs/render_supervisor_pdf.py`  
  This writes **`docs/DeciDish_Supervisor_Report.pdf`** (fonts are downloaded automatically on first run).  
- **Option B:** Open this file in **VS Code / Cursor**, use a Markdown PDF extension, or paste into **Google Docs** / **Word** and export PDF.  
- **Option C:** Use **Pandoc** (if installed):  
  `pandoc docs/SUPERVISOR_PROJECT_REPORT.md -o docs/DeciDish_Supervisor_Report.pdf`  
- **Option D:** For the technical deep-dive, the repo references printing from `docs/ACADEMIC_REPORT_PRINT.html` (see `ACADEMIC_REPORT.md` end matter).

---

*End of supervisor report.*
