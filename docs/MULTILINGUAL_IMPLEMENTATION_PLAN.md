# BharatPray Flutter App – Multilingual Implementation Plan

**Date**: November 2026  
**Document Version**: 1.0.0  
**Target Architecture**: Flutter Multi-Platform (Android, iOS) & Node.js REST API  
**Supported Locales**: English (`en`), Hindi (`hi`), Gujarati (`gu`), Marathi (`mr`)

---

## Overview

This implementation plan establishes a phased, production-grade roadmap for implementing complete dynamic multi-language localization across the BharatPray Flutter app and standardizing its communication with the backend.

---

## Phase 1: Localization Architecture & Language Configuration

### Objectives
- Solidify the core localization architecture.
- Ensure all 4 supported languages (`en`, `hi`, `gu`, `mr`) are registered in Flutter's `MaterialApp`, `pubspec.yaml`, and `language_model.dart`.
- Ensure font fallback and Unicode text rendering for Gujarati and Devanagari (Hindi/Marathi) scripts.

### Files to Modify
- `pubspec.yaml`
- `lib/core/localization/language_manager.dart`
- `lib/core/localization/language_model.dart`
- `lib/main.dart`

### New Files to Create
- `lib/core/localization/localization_constants.dart` (Centralized spiritual constants and fallback dictionary keys)

### Dependencies
- `flutter_localizations` (SDK)
- `intl: 0.20.2`
- `google_fonts: ^6.1.0`

### Implementation Steps
1. Verify `LanguageModel.supportedLanguages` defines `en`, `hi`, `gu`, and `mr` with exact native names and localized script tags.
2. In `lib/main.dart`, ensure `BharatPrayApp` configures:
   - `locale: LanguageManager.instance.currentLocale`
   - `supportedLocales: LanguageManager.instance.supportedLocales`
   - `localizationsDelegates: const [ AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate ]`
3. Configure `GoogleFonts.config.allowRuntimeFetching = true` with graceful fallback to system sans-serif fonts so that Gujarati and Devanagari scripts render reliably without character dropping.

### Expected Outcome
- App boots with active locale from `LanguageManager`.
- System correctly handles English, Hindi, Gujarati, and Marathi locales without missing-glyph or font-load crashes.

### Testing Requirements
- Launch app on clean simulator/device.
- Verify that `MaterialApp` accepts all 4 locales without throwing assertion errors.

---

## Phase 2: Language Selection & Persistence

### Objectives
- Provide user language selection on initial onboarding, splash, login, and profile screens.
- Guarantee immediate locale application without hard restart.
- Persist selection across app updates, restarts, and sessions.

### Files to Modify
- `lib/features/language_selection/presentation/language_selection_screen.dart`
- `lib/features/language_selection/presentation/widgets/language_card.dart`
- `lib/screens/splash_screen.dart`
- `lib/screens/login_screen.dart`
- `lib/screens/otp_verification_screen.dart`
- `lib/screens/details/profile_screen.dart`

### Implementation Steps
1. Maintain `LanguageSelectionScreen` as a full-screen, dedicated spiritual page.
2. Ensure touch on any language card instantly updates `LanguageManager.instance.changeLanguageByCode(code)`.
3. Animate title, subtitle, top branding badge, and bottom action button in real-time.
4. Save selected locale to `SharedPreferences` keys:
   - `user_preferred_language_code` (`String`)
   - `user_has_selected_language` (`bool`)
5. In `SplashScreen`, inspect `hasUserSelectedLanguage`. If false, route directly to `LanguageSelectionScreen(isFullScreen: true, isDismissible: false)`.

### Expected Outcome
- Smooth onboarding selection flow.
- Changing language immediately switches the active UI throughout the entire application tree.

### Testing Requirements
- Test fresh install: App opens directly to Language Selection Screen.
- Select Gujarati: Title changes to "તમારી પવિત્ર ભાષા પસંદ કરો", button changes to "આગળ વધો".
- Tap "આગળ વધો": User lands on Login/Home screen in Gujarati.
- Kill and restart app: Language remains Gujarati.

---

## Phase 3: Static UI Localization

### Objectives
- Move all user-facing hardcoded strings across all modules into `.arb` translation resource catalogs.
- Support authentic devotional terminology across English, Hindi, Gujarati, and Marathi.

### Files to Modify
- `lib/l10n/app_en.arb`
- `lib/l10n/app_hi.arb`
- `lib/l10n/app_gu.arb`
- `lib/l10n/app_mr.arb`
- `lib/screens/home_screen.dart`
- `lib/screens/details/bhajan_dashboard_screen.dart`
- `lib/screens/details/bhajan_category_screen.dart`
- `lib/screens/details/bhajan_screen.dart`
- `lib/screens/details/bhajan_downloads_screen.dart`
- `lib/screens/details/yatra_screen.dart`
- `lib/screens/details/utsav_screen.dart`
- `lib/screens/details/jap_counter_screen.dart`
- `lib/screens/details/profile_screen.dart`

### Implementation Steps
1. Add missing ARB keys for Bhajan Dashboard, Categories, Downloads, Yatras, Festivals, Jap, and Settings.
2. Run `flutter gen-l10n` to regenerate `AppLocalizations` classes (`app_localizations.dart`, `app_localizations_en.dart`, etc.).
3. Replace hardcoded string literals with `AppLocalizations.of(context)!.<key>`.
4. Provide defensive fallbacks when context is unavailable using `LocalizedApiHelper` or `LanguageManager.instance.currentLanguageCode`.

### Expected Outcome
- Zero hardcoded English strings in primary views.
- Natural, spiritually accurate phrasing across all 4 languages.

### Testing Requirements
- Switch between en, hi, gu, mr and verify that bottom tabs, headings, button labels, and dialogs display the appropriate language.

---

## Phase 4: API Localization & Dynamic Data Translation

### Objectives
- Ensure ALL API calls transmit the active language to the backend via standardized headers.
- Update all model parsing to handle both scalar string fields and localized map payloads `{ en, hi, gu, mr }`.
- Provide robust fallback so data is never blank if a specific language is absent.

### Files to Modify
- `lib/services/api_service.dart`
- `lib/services/utsav_service.dart`
- `lib/core/localization/localized_api_helper.dart`
- `lib/models/darshan_model.dart`
- `lib/models/bhajan_track_item.dart`
- `lib/models/yatra_model.dart`
- `lib/models/god_model.dart`
- `lib/models/notification_model.dart`
- `lib/models/jap_models.dart`
- `lib/models/granth_category.dart`

### Implementation Steps
1. In `ApiService`:
   - Introduce a centralized header resolver `_defaultHeaders()` and `_authHeaders()` that automatically appends:
     ```dart
     'Accept-Language': LanguageManager.instance.currentLanguageCode
     ```
   - Ensure all `_safeGet`, `_safePost`, `_safePut`, and `_safeDelete` invocations automatically include this header.
2. In `UtsavService`:
   - Inject `Accept-Language: LanguageManager.instance.currentLanguageCode` into all HTTP requests.
3. Enhance `LocalizedApiHelper.parse(dynamic value, {String defaultValue = ''})`:
   - Check if `value` is a Map: match current locale -> fallback `en` -> fallback `hi` -> first available string.
   - Check if `value` is a String: return trimmed string.
   - If null or empty: return `defaultValue`.
4. Update `darshan_model.dart`, `bhajan_track_item.dart`, `yatra_model.dart`, etc., to wrap every dynamic text field with `LocalizedApiHelper.parse(...)`.

### Expected Outcome
- Every API request cleanly declares the devotee's active language.
- When the backend returns localized data, models parse it instantly.
- When backend returns unilingual data, app renders it gracefully without crashing.

### Testing Requirements
- Inspect network requests using debug logger: confirm `Accept-Language: gu` (or `hi`, `mr`, `en`) is present in all outgoing headers.
- Verify models correctly parse both `{"name": "Somnath"}` and `{"name": {"en": "Somnath", "gu": "સોમનાથ"}}`.

---

## Phase 5: Cache Management & Language Switching

### Objectives
- Prevent stale, wrong-language data from displaying after a language switch.
- Partition local caches using language-specific cache keys.
- Clear in-memory buffers when language changes.

### Files to Modify
- `lib/services/api_service.dart`
- `lib/services/utsav_service.dart`
- `lib/core/localization/language_manager.dart`

### Implementation Steps
1. Append active language code to SharedPreferences cache keys:
   - `temples_cache_${langCode}`
   - `festivals_cache_${langCode}`
   - `bhajans_cache_${langCode}`
2. In `LanguageManager.changeLanguage(...)`:
   - Notify in-memory caches and services to purge dirty singletons.
   - Trigger UI reload for active view states.

### Expected Outcome
- Switching from English to Gujarati immediately loads Gujarati-cached or freshly requested Gujarati data, never stale English data.

### Testing Requirements
- Load temple list in English -> Verify cache stored as `temples_cache_en`.
- Switch to Gujarati -> Verify app does not read `temples_cache_en`, instead queries `temples_cache_gu` or makes localized API request.

---

## Phase 6: Notifications & Background Content Localization

### Objectives
- Ensure local audio notifications, FCM push notification handlers, and media player status use the active spiritual language.

### Files to Modify
- `lib/services/bhajan_audio_service.dart`
- `lib/services/fcm_notification_service.dart`

### Implementation Steps
1. In `BhajanAudioService`:
   - Localize notification control actions ("Play", "Pause", "Next", "Previous") using active locale strings.
2. In `FcmNotificationService`:
   - Pass active language code during FCM token registration to the backend (`/api/v1/user/fcm-token` or profile update) so the backend targets push notifications in the user's preferred language.

### Expected Outcome
- Devotee receives push notifications and media player alerts in their chosen language.

### Testing Requirements
- Trigger media playback: Verify notification controls and track details correspond to the selected language.

---

## Phase 7: Testing & Production Validation

### Objectives
- End-to-end regression testing across all 4 languages.
- Complete static code analysis (`flutter analyze`) and eliminate any build warnings.

### Validation Checklist
1. Fresh installation and onboarding language selection.
2. Verification of all tabs (Home, Darshan, Jap, Yatra, Profile) in English.
3. Verification of all tabs in Hindi.
4. Verification of all tabs in Gujarati.
5. Verification of all tabs in Marathi.
6. Verify persistence after app force-kill and reboot.
7. Verify API request headers contain `Accept-Language`.
8. Zero crashes on null or unilingual API responses.
