# DeciDish Application: Implementation Report

**Document type:** Technical and academic implementation report  
**Subject:** Software changes and feature additions to the DeciDish meal-decision system  
**Date:** 26 March 2025  

---

**Author:** *[Student / developer name]*  
**Institution / course:** *[Institution and course code, if applicable]*  
**Supervisor:** *[Optional]*  

---

## Abstract

This report documents a coherent set of modifications to the DeciDish cross-platform application (Flutter client, Node.js/MongoDB backend) undertaken to improve user experience, recommendation integrity, and content discoverability. The work addressed survey navigation and meal-type consistency in the “Help me decide” flow; introduced stochastic diversification of ranked content when users have not specified cuisine preferences; implemented a browsable “Food library” with search; corrected external hyperlink behaviour for recipe sources and videos; aligned list interfaces for favorites and history with network-backed imagery; reordered primary navigation; and augmented import-script documentation regarding third-party data limits. The report describes objectives, design rationale, implementation scope, and suggested verification steps. Limitations inherent to external recipe APIs and client-side search are discussed.

**Keywords:** human–computer interaction; meal recommendation; mobile applications; personalization; software engineering; REST APIs.

---

## 1. Introduction

DeciDish is designed to assist users in choosing what to cook or eat by combining preference-aware scoring, social and feed features, and structured surveys. Prior to the reported changes, several interaction gaps were observed: users could not preview a survey result and return to the same list without dismissing the survey; relaxed database queries could mix incompatible meal types; users without explicit cuisine preferences often saw homogeneous top-ranked lists; recipe-related URLs failed silently on some devices; and certain list views did not reflect visual content already available in the data model. This report synthesizes the engineering response to those issues and the addition of a dedicated library experience.

The report is organized as follows: Section 2 states objectives; Section 3 outlines methodology and technology context; Section 4 details implementations by subsystem; Section 5 summarizes outcomes and testing guidance; Section 6 discusses limitations; Section 7 concludes; Section 8 lists references.

---

## 2. Objectives

The following objectives guided the implementation work:

1. **Survey–detail navigation:** Preserve the modal survey context while allowing full-screen meal inspection with predictable back-stack behaviour.
2. **Semantic consistency:** Constrain survey-derived meal suggestions so that user-selected meal types (e.g., breakfast vs. dessert) are not diluted by query relaxation or empty fallbacks.
3. **Preference-aware diversity:** When no cuisine preferences are set, increase perceived variety without discarding the underlying scoring model when preferences are present.
4. **Content discovery:** Provide an alphabetical, countable catalog of meals with local search affordances.
5. **Reliability of external links:** Make “original recipe” and “watch video” actions succeed across common URL formats and mobile platform policies.
6. **Visual fidelity:** Display meal imagery in favorites and history where the API supplies image URLs.
7. **Information architecture:** Place “Home” and “Feed” in a conventional order in the bottom navigation bar.

---

## 3. Methodology and Technical Context

### 3.1 Architecture

The system follows a **client–server** pattern. The mobile client is implemented in **Dart/Flutter**; the server uses **Node.js** with **Express**, **Mongoose**, and **MongoDB**. Authentication-protected routes supply personalized data; public routes support catalog reads where configured.

### 3.2 Approach

Changes were implemented incrementally by subsystem (backend services, HTTP routes, Flutter screens, and platform manifests). Personalization logic reused existing helpers (`preferenceUtils`, `mealScoring`) to avoid duplicating cuisine-matching rules. Where behaviour depended on platform capabilities (e.g., Android 11 package visibility for intent resolution), native configuration files were updated alongside Dart code.

### 3.3 Data sources

Meal records may originate from imports aligned with **TheMealDB**-style fields (e.g., `themealdbId`, image URLs, ingredient lists). The public catalog size is finite; this constraint is acknowledged in documentation and affects expectations for library cardinality.

---

## 4. Implementation Details

### 4.1 “Help me decide” survey flow

**Problem.** Tapping a survey result previously closed the bottom sheet and returned a meal to the parent route, which then navigated to the recommendation screen—preventing a simple “preview then return to list” pattern.

**Solution.** The survey widget now pushes the recommendation route on the **root navigator** and awaits return, without popping the sheet with the selected meal. The home screen no longer performs a redundant navigation when the survey completes. User-facing copy clarifies that the system back gesture or in-app back control returns to the suggestion list, and that the sheet may be dismissed when the user is finished.

**Outcome.** Navigation semantics align with stacked routes: detail above sheet, list state preserved below.

### 4.2 Survey meal-type integrity (backend)

**Problem.** Query relaxation previously removed `mealType`, and broad fallbacks could omit type filters, allowing cross-type contamination (e.g., lunch items in a breakfast survey).

**Solution.** Relaxation steps were limited to preparation time, estimated cost, and calorie constraints. A dedicated fallback query retains `mealType` when the primary query returns no documents. A final in-memory filter enforces `meal.mealType === answers.mealType` when a type is specified.

**Outcome.** Stronger alignment between user intent and retrieved candidates, at the cost of potentially empty results if the database lacks matching rows—a trade-off noted under limitations.

### 4.3 Cuisine diversity without explicit preferences (backend)

**Problem.** With no cuisine filter, ranking by score and popularity can concentrate results in a single cuisine.

**Solution.** New utilities (`hasPreferredCuisines`, `pickRandomizedTopFromSorted`, `randomizeTopPortion`) apply **only** when the user’s preferred-cuisine list is empty. Affected surfaces include feed sections, the primary recommendation endpoint’s selection policy, personalized meal listing order (with exceptions when a cuisine query parameter is used), and survey suggestion ordering.

**Outcome.** Improved variety for users who have not committed to cuisine preferences; unchanged strict behaviour for users who have.

### 4.4 Food library (client)

**New functionality.** A dedicated screen loads all meals via the existing catalog API, sorts them alphabetically by name, displays a total count, and lists items with thumbnail, title, and secondary metadata. Navigation is registered in the application router; the home screen exposes entry via a dedicated card.

**Search.** A text field filters the loaded list **client-side** by substring match against name, cuisine, meal type, and tags, with result counts and empty-state messaging.

**Outcome.** Improved transparency of corpus size and faster ad hoc lookup without additional server endpoints for search.

### 4.5 Recipe and video hyperlinks (client and native config)

**Problem.** URLs lacking schemes failed parsing; Android 11+ restricted visibility of handlers for generic `http`/`https` intents; iOS may require declared query schemes for certain targets.

**Solution.** URI normalization prepends `https://` where appropriate while preserving `mailto:` and `tel:`. Launch uses `canLaunchUrl` and `launchUrl` with external application mode and a platform-default fallback. The recommendation screen hydrates the full meal document when both recipe URLs are absent from the initial payload. Android `AndroidManifest.xml` declares `VIEW` intents for `http` and `https`; iOS `Info.plist` includes `youtube` in `LSApplicationQueriesSchemes` alongside existing `http`/`https` entries.

**Outcome.** More predictable success rates for opening external resources after a full native rebuild.

### 4.6 Favorites and history list imagery (client)

**Problem.** Rows used generic icons despite `imageUrl` being present in populated meal objects.

**Solution.** Replaced placeholders with the shared `MealNetworkImage` component, consistent with other screens.

**Outcome.** Visual continuity with the rest of the application and clearer scanability of lists.

### 4.7 Bottom navigation order (client)

**Change.** The `PageView` and tab order were updated so **Home** is the first tab and **Feed** the second; default landing index remains zero, now corresponding to Home.

**Outcome.** Alignment with common expectations for primary “hub” placement.

### 4.8 Import script documentation (backend)

**Change.** Comments in the TheMealDB import script state that the public API exposes on the order of **hundreds** of recipes, not an unbounded catalog.

**Outcome.** Sets realistic expectations for stakeholders and future maintainers.

---

## 5. Results and Verification

Table 1 summarizes expected behaviours for manual or automated verification.

| Area | Expected behaviour |
|------|---------------------|
| Survey | After opening a result, back navigation returns to the same suggestion list inside the sheet. |
| Survey | Meal type selected in the survey matches types of suggested meals (subject to data availability). |
| No cuisine prefs | Feed and recommendations exhibit varied cuisines relative to strict score-only ordering. |
| With cuisine prefs | Ordering and filtering respect preferences; no unintended shuffle of the strict ranked list beyond defined logic. |
| Food library | Count reflects loaded meals; list A–Z; search filters locally; tap opens detail. |
| Links | Normalized URLs open in an external browser or relevant app where permitted. |
| Favorites / history | Meal images render when URLs are valid. |
| Navigation | First tab: Home; second: Feed. |

Automated test coverage for these behaviours is left to project policy; the table supports structured manual QA.

---

## 6. Limitations and Future Work

1. **Corpus size.** TheMealDB and similar sources impose an upper bound on imported meals; scaling beyond that requires additional ingestion pipelines or partnerships.
2. **Survey empty sets.** Strict `mealType` filtering may yield no suggestions if the database is sparse for a type—future work could include graceful messaging or controlled relaxation with explicit user consent.
3. **Library search.** Current search is **client-side** and loads the full list first; very large corpora may require server-side pagination and indexed search.
4. **Link availability.** Many imported meals lack non-empty “original source” URLs; video links depend on provider fields—UX cannot compensate for missing data.
5. **Platform rebuilds.** Native manifest and plist changes require full application rebuilds, not hot reload alone.

---

## 7. Conclusion

The reported work tightens alignment between user actions (survey choices, navigation, and preferences) and system behaviour, improves transparency via a searchable food library, and addresses practical mobile constraints for external links and list imagery. Backend changes favour correctness of meal-type constraints and controlled diversity; client changes favour navigation clarity and visual consistency. Together, these updates constitute a coherent increment toward a more dependable and usable DeciDish experience. Continued evaluation with real users and expanded test automation would further validate the design decisions described herein.

---

## 8. References

1. Flutter Team. (2024). *Flutter documentation: Navigation and routing.* Retrieved from https://docs.flutter.dev/  
2. Google LLC. *url_launcher package.* Pub.dev. Retrieved from https://pub.dev/packages/url_launcher  
3. Android Open Source Project. (n.d.). *Package visibility filtering on Android 11+.* Retrieved from https://developer.android.com/training/package-visibility  
4. Apple Inc. (n.d.). *Information Property List Key Reference: LSApplicationQueriesSchemes.* Retrieved from https://developer.apple.com/documentation/bundleresources/information_property_list/lsapplicationqueriesschemes  
5. TheMealDB. (n.d.). *TheMealDB API.* Retrieved from https://www.themealdb.com/api.php  
6. Mongoose. (n.d.). *Mongoose documentation.* Retrieved from https://mongoosejs.com/docs/guide.html  

*[Add course materials, textbooks, or supervisor-specified sources as required.]*  

---

## Appendix A. File index (non-exhaustive)

| Component | Representative paths |
|-----------|-------------------------|
| Survey UI | `lib/widgets/help_me_decide_survey.dart` |
| Home | `lib/screens/home_screen.dart` |
| Survey backend | `backend/services/surveyMeals.js` |
| Preferences utilities | `backend/services/preferenceUtils.js` |
| Feed / recommendations / meals routes | `backend/routes/feed.js`, `recommendations.js`, `meals.js` |
| Food library | `lib/screens/meal_library_screen.dart` |
| App routing | `lib/main.dart` |
| Recommendation / links | `lib/screens/recommendation_screen.dart` |
| Favorites / history | `lib/screens/favorites_screen.dart`, `history_screen.dart` |
| Tab shell | `lib/screens/main_navigation_screen.dart` |
| Android / iOS config | `android/app/src/main/AndroidManifest.xml`, `ios/Runner/Info.plist` |
| Import script | `backend/scripts/importTheMealDB.js` |

---

*End of report.*

---

## Generating a PDF (submission-ready)

Open **`docs/ACADEMIC_REPORT_PRINT.html`** in **Chrome** or **Safari** → **Print** (Ctrl/Cmd+P) → **Save as PDF** / **Microsoft Print to PDF**. Choose paper **A4** and, if needed, enable **Background graphics** so tables print clearly. The HTML version includes print styles and a short on-screen reminder; the yellow hint box is hidden when printing.
