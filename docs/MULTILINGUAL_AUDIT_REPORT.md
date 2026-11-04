# BharatPray Flutter App – Multilingual Localization Audit Report

**Date**: November 2026  
**Auditor**: Senior Flutter Architect, Localization Expert, & API Integration Engineer  
**Target Application**: BharatPray Flutter Application (`Bharat_Pray_App 2`) & Node.js Backend (`BharatPray_Backend`)  
**Supported Languages**: English (`en`), Hindi (`hi`), Gujarati (`gu`), Marathi (`mr`)

---

## 1. Executive Summary

A comprehensive architectural and code-level localization audit was conducted across the BharatPray Flutter mobile app and its corresponding Node.js/Express/MongoDB backend.

The objective was to evaluate the readiness of both client and server for production-ready, dynamic multi-language localization covering **both static UI strings and dynamic API-driven content** (Temples, Yatras, Bhajans, Grantha, Poojas, Utsavs, God Categories, Notifications, and CMS data).

### Key Audit Findings:
1. **Language Management Foundation**: 
   - A centralized `LanguageManager` (`lib/core/localization/language_manager.dart`) exists with `ChangeNotifier` architecture and `SharedPreferences` persistence.
   - Flutter's official `flutter_localizations` with `.arb` files exists in `lib/l10n/` (`app_en.arb`, `app_hi.arb`, `app_gu.arb`, `app_mr.arb`).
   - A custom `LocalizedApiHelper` (`lib/core/localization/localized_api_helper.dart`) was introduced but is only used in 4 out of 19 data models.
2. **API & Network Layer Gaps**:
   - `ApiService` (`lib/services/api_service.dart`, 3200+ lines) and `UtsavService` (`lib/services/utsav_service.dart`, 1650+ lines) **do not transmit the `Accept-Language` HTTP header** or language query parameters in outgoing requests.
   - Neither service has centralized interceptors; `http.get`, `http.post`, `_safeGet`, and `_safePost` construct individual header maps omitting locale information.
3. **Backend API Localization Readiness**:
   - Audit of `BharatPray_Backend/models/` (`temple.model.js`, `bhajan.model.js`, `yatra.model.js`, `god_category.model.js`, `festival.model.js`, etc.) reveals that schemas currently store **single unilingual string fields** (mostly English or Hindi transliteration).
   - Backend controllers do not inspect `req.headers['accept-language']` or `req.query.lang`.
   - **Conclusion**: The backend does *not* currently possess localized content tables or translation pipelines. Client-side localization must handle both scalar strings and multilingual maps without breaking, and strict backend API localization requirements must be formally established.
4. **Caching & Stale Data Issues**:
   - Cache keys stored in `SharedPreferences` (e.g. `cached_temples`, `cached_festivals`, `jap_categories`) are un-partitioned by language.
   - Switching language while retaining cached data causes English or Hindi data to persist on screen despite UI language changes.
5. **Static UI Localization Gaps**:
   - Core screens (`home_screen.dart`, `bhajan_dashboard_screen.dart`, `yatra_screen.dart`, `utsav_screen.dart`, `profile_screen.dart`, `jap_counter_screen.dart`) retain numerous hardcoded English strings.

---

## 2. Architecture & Dependency Inspection

### 2.1 Dependencies (`pubspec.yaml`)
- `flutter_localizations`: SDK-pinned
- `intl`: `0.20.2` (properly aligned with Flutter SDK)
- `shared_preferences`: `^2.5.5`
- `http`: `^1.6.0` (direct HTTP calls; no Dio interceptor)
- `google_fonts`: `^6.1.0` (Outfit font used throughout; Gujarati & Devanagari Unicode scripts need reliable font rendering fallback)
- `audioplayers`: `^6.0.0`
- `firebase_messaging` & `flutter_local_notifications`: used for background & push notifications.

### 2.2 State Management & Localization Reactivity
- Root app `BharatPrayApp` in `lib/main.dart` is wrapped in `ListenableBuilder(listenable: LanguageManager.instance)`.
- When `LanguageManager.instance.changeLanguage(locale)` is invoked:
  - `notifyListeners()` triggers rebuilding `MaterialApp` with the new `locale`.
  - Stored in `SharedPreferences` under `user_preferred_language_code` and `user_has_selected_language`.
  - App state remains active without forcing a hard process restart.

---

## 3. Detailed Subsystem Audit

### 3.1 Network Services (`lib/services/`)
| Service File | Functionality | Current Header State | Localization Status |
|---|---|---|---|
| `api_service.dart` | Temples, Darshan, Bhajans, Grantha, Jap, Yatras, Profile | `{'Authorization': 'Bearer ...'}` | ❌ Missing `Accept-Language` header |
| `utsav_service.dart` | Festivals, Mandals, Competitions | Direct `http.get` without auth/locale headers | ❌ Missing `Accept-Language` header |
| `bhajan_audio_service.dart` | Audio streaming & Notification controls | Audio metadata from track item | ⚠️ Notification strings require localization |
| `fcm_notification_service.dart` | Push notifications | Standard FCM payloads | ⚠️ Missing device language tag in user profile |

### 3.2 Data Models (`lib/models/`)
| Model File | Fields Requiring Localization | Current Parsing Logic | Status |
|---|---|---|---|
| `darshan_model.dart` | Temple `name`, `description`, `city`, `state`, `address` | Direct `json['name']?.toString()` | ❌ Raw unlocalized |
| `god_model.dart` | Deity `name`, `description`, `mantra` | `LocalizedApiHelper.parse(json['name'])` | ✅ Localized helper integrated |
| `yatra_model.dart` | Yatra `title`, `description`, checkpoint instructions | Partial `LocalizedApiHelper` on title/desc | ⚠️ Checkpoints unlocalized |
| `yatra_group_models.dart`| Temple `name`, `city`, `state`, `address` | `LocalizedApiHelper.parse(...)` | ✅ Localized helper integrated |
| `bhajan_track_item.dart` | Bhajan `title`, `artist`, `categoryName` | Direct `json['title']?.toString()` | ❌ Raw unlocalized |
| `granth_category.dart` | Category `name`, `description` | `LocalizedApiHelper.parse(...)` | ✅ Localized helper integrated |
| `notification_model.dart`| Notification `title`, `message` | `LocalizedApiHelper.parse(...)` | ✅ Localized helper integrated |
| `utsav` (in `utsav_service.dart`)| Festival `name`, `slogan`, `description`, `timing`, `rewards` | Hardcoded map & raw JSON extraction | ❌ Raw unlocalized |
| `jap_models.dart` | Deity name, mantra, significance | Direct string assignment | ❌ Raw unlocalized |

### 3.3 Screens & Modules Audit
| Screen / Module | Hardcoded Strings Identified | Dynamic Data Points Needing Localization |
|---|---|---|
| `lib/screens/home_screen.dart` | Section titles, greeting subtitles, darshan highlights | Featured temples, live darshan labels, deity names, daily quote |
| `lib/screens/details/bhajan_dashboard_screen.dart` | "Trending Bhajans", "Quick Playlists", "Categories", "All Downloads", "Offline", "Playing Now" | Bhajan titles, artists, god categories, playlist names |
| `lib/screens/details/bhajan_screen.dart` | "All Bhajans", search placeholder, filter tabs | Bhajan list items, duration formats |
| `lib/screens/details/bhajan_category_screen.dart` | "Select Category", "Browse divine songs" | God category names, descriptions |
| `lib/screens/details/yatra_screen.dart` | "Explore Yatras", "Start Journey", "Total Distance", "Completed" | Yatra titles, descriptions, route temple names |
| `lib/screens/details/utsav_screen.dart` | "Festivals & Mahotsav", "Register Mandal", "Rules", "Prizes" | Festival names, slogans, competition criteria |
| `lib/screens/details/profile_screen.dart` | "My Profile", "Total Jap", "Bhajans", "Streak", "Settings", "Language" | User badges, devotional stats labels |
| `lib/screens/details/jap_counter_screen.dart` | "Target Mala", "Chant Count", "Vibration", "Reset" | Mantra titles, deity names, spiritual instructions |
| `lib/screens/login_screen.dart` | "Welcome Back", "Enter mobile number", "Send OTP" | Error messages, snackbars |
| `lib/screens/otp_verification_screen.dart` | "Verify OTP", "Resend in", "Submit" | Dev mode hints, error messages |

---

## 4. Backend API Audit (`BharatPray_Backend`)

### 4.1 Schema Inspection
Inspecting the Mongoose schemas in `BharatPray_Backend/models/`:
```javascript
// models/darshan_management/temple/temple.model.js
let schema = new mongoose.Schema({
    name: { type: String, default: '' },
    shortDescription: { type: String, default: '' },
    description: { type: String, default: '' },
    country: { type: String, default: '' },
    state: { type: String, default: '' },
    city: { type: String, default: '' },
    address: { type: String, default: '' },
    ...
});
```
- There are no localized sub-documents or fields like `name_gu`, `name_hi`, `name_mr`, or `{ en: String, hi: String, gu: String, mr: String }`.
- The database stores data in English or Hindi as supplied by the admin/seeder.

### 4.2 Endpoint Inspection
- Endpoints like `GET /api/v1/temple`, `GET /api/v1/yatra`, `GET /api/v1/bhajan` do not accept or read the `Accept-Language` header.
- The Grantha module (`models/granth/granth.model.js`) has a single `language: String` attribute used as a filter (e.g. `GET /api/v1/granth?language=Gujarati`), not as content translation.

### 4.3 Technical Reality & Strategic Solution
1. **Never inject fake or machine-translated data into Flutter code**: The client must not contain massive hardcoded dictionaries representing API database rows.
2. **Standardized Client Header**: Flutter app must send `Accept-Language: <codeCode>` (`en`, `hi`, `gu`, `mr`) in every request.
3. **Resilient Localized Parser**: Models must use `LocalizedApiHelper.parse()` to safely handle:
   - Full multilingual maps `{ "en": "...", "gu": "..." }` when the backend is upgraded.
   - Standard strings returned by the current backend.
   - Graceful fallback: `selected language` -> `en` -> `hi` -> `first available non-empty` -> `default fallback`.
4. **Backend Blueprint**: Produce `docs/API_LOCALIZATION_REQUIREMENTS.md` detailing the exact database schema updates, middleware, and query param/header contracts needed for full server-side translation.

---

## 5. Cache Architecture & Language Invalidation Audit

### Current Cache State:
- `SharedPreferences` keys in use:
  - `cached_temples`
  - `cached_god_categories`
  - `cached_festivals`
  - `user_saved_bhajans`
  - `jap_session_v2_*`
- **Issue**: None of these keys incorporate language codes.
- **Risk**: If a user loads Temples in Gujarati, closes the app, opens the app, and changes language to Marathi, reading `cached_temples` displays Gujarati data on a Marathi interface.
- **Remedy**: All cache keys storing API content must be parameterized by language:
  `cached_temples_${langCode}`, `cached_festivals_${langCode}`.
  When `LanguageManager.instance.changeLanguage(...)` is called, in-memory caches must be cleared and active screens signaled to refresh.

---

## 6. Audit Conclusion & Gaps Summary

| Domain | Severity | Description | Action Required |
|---|---|---|---|
| **API Header** | High | No `Accept-Language` sent in HTTP requests | Implement central request interceptor/headers in `ApiService` & `UtsavService` |
| **Model Parsing** | High | 15 out of 19 models parse strings directly | Wrap all user-facing model fields with `LocalizedApiHelper.parse()` |
| **Cache Keys** | Medium | Cache keys ignore active language | Implement language-suffixed cache keys and cache invalidation on language change |
| **ARB Files** | Medium | Missing keys for newly added screens (Bhajan Dashboard, Downloads, Utsav tabs) | Expand `app_en.arb`, `app_gu.arb`, `app_hi.arb`, `app_mr.arb` |
| **Static UI** | Medium | Hardcoded English text in 12+ screens | Replace with `AppLocalizations.of(context)` or centralized spiritual localized terms |
| **Backend Integration** | High | Backend lacks multilingual database fields & Accept-Language handling | Formulate comprehensive API localization specifications document |
