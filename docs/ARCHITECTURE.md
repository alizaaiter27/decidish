# DeciDish — Architecture Diagrams

DeciDish is a meal‑recommendation and food‑social application built as a full‑stack
system:

- **Mobile client** — Flutter (Dart), iOS + Android.
- **Backend API** — Node.js + Express, JWT auth, RESTful.
- **Database** — MongoDB (via Mongoose ODM).
- **Push notifications** — Firebase Cloud Messaging (FCM).
- **External recipe sources** — TheMealDB, Spoonacular, Open Cookbook (offline import scripts).

All diagrams use [Mermaid](https://mermaid.js.org/) and render directly in Cursor's
Markdown preview, on GitHub, and in most Markdown viewers.

## Contents

1. [System Architecture Diagram](#1-system-architecture-diagram)
2. [Frontend / Backend Flow](#2-frontend--backend-flow)
3. [Database Schema](#3-database-schema)
4. [Localization Workflow](#4-localization-workflow)
5. [Recommendation Flow](#5-recommendation-flow)

---

## 1. System Architecture Diagram

End‑to‑end view of all components, their layers, and the external systems they
depend on.

```mermaid
flowchart TB
    user([User])

    subgraph client[Flutter Mobile App - iOS / Android]
        direction TB
        ui[Presentation<br/>Screens and Widgets]
        svc[Service Layer<br/>Domain API services]
        http[ApiService<br/>HTTP client + JWT]
        store[(SharedPreferences<br/>token, user, locale)]
        ui --> svc --> http
        http --> store
    end

    subgraph server[Backend - Node.js / Express :3000]
        direction TB
        routes[Route Layer<br/>auth, users, meals, recommendations,<br/>favorites, history, friends, messages,<br/>posts, feed]
        mw[Auth Middleware<br/>JWT verify]
        services[Service Layer<br/>mealScoring, candidatePool,<br/>preferenceUtils, mealLocale]
        models[Mongoose Models]
        routes --> mw
        routes --> services
        routes --> models
        services --> models
    end

    db[(MongoDB)]
    fcm[[Firebase Cloud Messaging]]
    ext[[External Recipe APIs<br/>TheMealDB / Spoonacular / Open Cookbook]]
    importers[Import Scripts<br/>offline jobs]

    user --> ui
    http -- HTTPS / JSON<br/>Bearer JWT --> routes
    models -- Mongoose driver --> db
    client <-. push token / messages .-> fcm
    importers -- fetch recipes --> ext
    importers -- upsert meals --> db
```

---

## 2. Frontend / Backend Flow

How a request travels from a screen, through the client's layered services, over
HTTP to Express, and back. The client never calls HTTP from the UI directly — it
always goes through a domain service and the shared `ApiService` wrapper.

```mermaid
flowchart LR
    subgraph FE[Flutter Client]
        direction TB
        screen[Screen / Widget]
        dsvc["Domain Service<br/>e.g. AuthApiService,<br/>MealApiService,<br/>FavoritesApiService"]
        api["ApiService<br/>get / post / put / delete"]
        auth["AuthService<br/>getToken()"]
        locale["ApiLocaleParams<br/>Accept-Language header"]
        model["Models.fromJson()"]

        screen -->|call| dsvc
        dsvc -->|build request| api
        api -->|attach Bearer token| auth
        api -->|attach language| locale
        api -->|parse JSON| model
        model -->|typed object| dsvc
        dsvc -->|state / Future| screen
    end

    subgraph BE[Express Backend]
        direction TB
        route[Route handler]
        protect[protect middleware<br/>verify JWT]
        logic[Business logic /<br/>Service layer]
        odm[Mongoose Model]
        route --> protect --> logic --> odm
    end

    db[(MongoDB)]

    api == "HTTPS request<br/>Authorization: Bearer JWT" ==> route
    odm == "documents" ==> db
    route == "JSON { success, data }" ==> api

    note["Error path: non-2xx -> ApiException<br/>thrown in ApiService, surfaced to UI"]
    api -.-> note
```

---

## 3. Database Schema

MongoDB collections, their fields, and references. `||--o{` = one‑to‑many,
`}o--o{` = many‑to‑many, `UK` = unique key, `FK` = reference to another document.

```mermaid
erDiagram
    USER ||--o{ FAVORITE : "has"
    USER ||--o{ HISTORY : "has"
    USER ||--o{ POST : "authors"
    USER ||--o{ MEALRATING : "writes"
    USER ||--o{ MESSAGE : "sends / receives"
    USER ||--o{ FRIENDREQUEST : "sends / receives"
    USER }o--o{ USER : "friends (mutual)"

    MEAL ||--o{ FAVORITE : "favorited in"
    MEAL ||--o{ HISTORY : "eaten in"
    MEAL ||--o{ MEALRATING : "rated in"
    MEAL ||--o{ POST : "referenced in"

    USER {
        ObjectId _id PK
        string name
        string email UK
        string password "hashed, select:false"
        string dietType "enum"
        object preferences "taste, cuisines, calories, etc."
        bool onboardingCompleted
        object streak "current, longest, checkInDates"
        ObjectId-array friends FK
        object surveyInsights "recent picks"
        date createdAt
    }
    MEAL {
        ObjectId _id PK
        string name
        object nutrition "calories, protein, carbs, fat"
        string-array dietTypes "enum"
        string cuisine
        string-array ingredients
        string mealType "enum, required"
        object tasteProfile "sweet..umami 0-5"
        string-array cookingMethod "enum"
        number preparationTime
        string difficulty "enum"
        number estimatedCost
        object localeTr "Turkish copy"
        string themealdbId UK
        string spoonacularId UK
        string openCookbookUrl UK
    }
    FAVORITE {
        ObjectId user FK
        ObjectId meal FK
        date createdAt
    }
    HISTORY {
        ObjectId user FK
        ObjectId meal FK
        string mealType "enum"
        number recommendationScore
        number rating "1-5"
        string notes
        date date
    }
    MEALRATING {
        ObjectId user FK
        ObjectId meal FK
        number rating "1-5, required"
        string review "max 2000"
        date updatedAt
    }
    POST {
        ObjectId user FK
        string content
        ObjectId meal FK "optional"
        ObjectId-array likes FK
        date createdAt
    }
    MESSAGE {
        ObjectId sender FK
        ObjectId recipient FK
        string content
        bool read
        date createdAt
    }
    FRIENDREQUEST {
        ObjectId from FK
        ObjectId to FK
        string status "pending/accepted/declined"
    }
```

**Unique constraints:** `User.email`; `Favorite (user, meal)`;
`FriendRequest (from, to)`; `Meal.themealdbId / spoonacularId / openCookbookUrl`
(sparse). `MealRating (user, meal)` is intentionally **non‑unique** so a user can
post multiple reviews of the same meal over time.

---

## 4. Localization Workflow

DeciDish localizes two distinct things, each with its own pipeline.

### 4a. UI strings + locale selection

Static UI text is fully translated via `AppStrings`; the active locale is held in a
`ValueNotifier` and persisted, so the whole app rebuilds when the user switches
languages.

```mermaid
flowchart TB
    start([App start / user changes language])
    load["LocaleController.loadSavedLocale()<br/>read 'app_locale' from SharedPreferences"]
    notifier["localeNotifier : ValueNotifier&lt;Locale?&gt;"]
    builder["main.dart<br/>ValueListenableBuilder rebuilds MaterialApp"]
    delegate["AppStrings.delegate<br/>+ GlobalMaterialLocalizations"]
    text["AppStrings.of(context).someKey<br/>localized UI text"]
    save["LocaleController.setLocale(locale)<br/>persist languageCode"]

    start --> load --> notifier
    notifier --> builder --> delegate --> text
    start -. manual switch .-> save --> notifier
```

### 4b. Meal content (data) localization — two-tier

Meal text (names, descriptions, ingredients) is localized server‑first, with an
on‑device machine‑translation fallback.

```mermaid
flowchart TB
    req["Client builds meal request"]
    wants{"ApiLocaleParams<br/>wantsTurkishMealContent?"}
    addLang["Add Accept-Language: tr<br/>and/or ?lang=tr"]
    plain["No language hint (English)"]

    req --> wants
    wants -- yes --> addLang
    wants -- no --> plain

    subgraph server[Backend - mealLocale.js]
        getlang["getMealContentLang(req)<br/>query ?lang -> header -> default 'en'"]
        resolve["resolveMealPlain(meal, lang)"]
        hasTr{"meal has localeTr<br/>for lang=tr?"}
        merge["Merge localeTr into<br/>name/description/ingredients<br/>set displayLocale='tr'"]
        en["Keep English<br/>set displayLocale='en'"]
        getlang --> resolve --> hasTr
        hasTr -- yes --> merge
        hasTr -- no --> en
    end

    addLang --> getlang
    plain --> getlang

    payload["JSON meal + displayLocale"]
    merge --> payload
    en --> payload

    subgraph client[Client - MealDisplayTranslation]
        check{"wantsTurkish AND<br/>displayLocale != 'tr'?"}
        usetr["Use server Turkish text as-is"]
        translate["GoogleTranslator fallback<br/>dedup batch prefetch + in-memory cache"]
        check -- no, server already returned tr --> usetr
        check -- yes, gap to fill --> translate
    end

    payload --> check
    usetr --> show([Display to user])
    translate --> show
```

---

## 5. Recommendation Flow

The "Decide for me" path: an authenticated request that filters candidate meals,
scores them with a weighted engine, and returns the best match with a transparent
score breakdown.

```mermaid
sequenceDiagram
    actor U as User
    participant App as Flutter App
    participant API as ApiService (Bearer JWT)
    participant R as GET /api/recommendations
    participant MW as protect (JWT)
    participant DB as MongoDB
    participant Score as mealScoring service

    U->>App: Tap "Decide for me"
    App->>API: GET /recommendations?mealType=&saveHistory=1
    API->>R: HTTPS + Authorization header
    R->>MW: verify JWT
    MW->>DB: User.findById(decoded.id)
    DB-->>MW: user
    MW-->>R: req.user

    Note over R: Determine meal type from time of day (or query)
    R->>DB: load preferences + recent History (to exclude)
    R->>DB: Meal.find(filter)

    loop Progressive relaxation until candidates found
        R->>DB: widen filter (drop mealType, method,<br/>difficulty, ... down to {})
        DB-->>R: candidate meals
    end

    R->>Score: loadScoringContext(user, candidateIds)
    Score->>DB: Favorite counts + liked/eaten profile
    DB-->>Score: context (popularity, taste profile, recent set)

    loop For each candidate meal
        R->>Score: computeMealScore(meal, user, ctx)
        Note right of Score: preferences + taste +<br/>similarity + popularity<br/>- recentPenalty + tieBreak
    end
    Score-->>R: scored & ranked meals

    R->>R: pick top (randomized top-N if no cuisine prefs)
    opt saveHistory = true
        R->>DB: History.create(meal, score, mealType)
    end
    R-->>API: { meal, recommendationContext, scoreBreakdown }
    API-->>App: recommended meal
    App-->>U: Show meal card + reasoning
```

### Scoring weights (from `services/mealScoring.js`)

| Signal | Source | Max contribution |
| --- | --- | --- |
| Meal type match | current time / preferred types | +26 (exact) / +12 (preferred) |
| Diet type match | `user.dietType` | +28 |
| Preferred cuisine | match +40, **mismatch −48** | ±40/48 |
| Taste compatibility | profile vs meal taste | +38 |
| Calorie range | within min/max | +16 |
| Prep time / difficulty / method / season | preferences | +12 / +10 / +12 / +8 |
| Similarity to likes & history | cuisine, tags, ingredients (Jaccard), taste | up to +55 |
| Community popularity | favorite count (log‑scaled) | up to +24 |
| Recently seen penalty | last ~20 history meals | −14 |
| Tie‑break | random | +0…1.8 |

---

### Key design notes

- **Stateless auth:** the JWT (signed with `JWT_SECRET`, ~7‑day expiry) is the only
  session artifact, stored client‑side in `SharedPreferences`.
- **Layered client:** UI → domain service → `ApiService` → HTTP; errors become a
  typed `ApiException`.
- **Server‑first localization** with an on‑device translation fallback keeps
  payloads small while still covering meals that lack a stored Turkish variant.
- **Progressive query relaxation** guarantees the recommender always returns a meal,
  even when strict preferences match nothing.
