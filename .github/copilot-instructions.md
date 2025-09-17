# Copilot Instructions for AI Coding Agents

## Project Overview
- **MELODY** is a cross-platform Flutter music app with advanced transitions, ultra-dark UI, and comprehensive music management.
- Major features: 3D transitions, glass morphism UI, Firebase authentication, background audio, native Android notifications, favorites, and device music scanning.

## Architecture & Key Components
- `lib/core/services/`: Business logic (auth, music, notifications, favorites, Google sign-in)
- `lib/core/widgets/`: Reusable UI (buttons, text fields, mini player, notifications, backgrounds)
- `lib/core/transitions/`: Custom page transitions (see `page_transitions.dart`, `advanced_transitions.dart`)
- `lib/ui/`: Screens (auth, home, favorites, full player, splash)
- `lib/main.dart`: App entry point
- State management: **Provider**
- Audio: **just_audio**
- Animations: **flutter_animate**
- Data persistence: **shared_preferences**

## Developer Workflows
- **Install dependencies:** `flutter pub get`
- **Run app:** `flutter run`
- **Test:** `flutter test` (see `test/widget_test.dart`)
- **Firebase setup:** Place `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) in platform folders
- **Platform notes:**
  - Android: Storage permissions for music access
  - iOS: Background audio, media permissions
  - Desktop: Music directory scanning

## Project-Specific Patterns
- **Transitions:** Use `PageTransitions.*` for navigation (see README for examples)
- **Theme:** Colors and styles in `core/theme/app_theme.dart`
- **Favorites:** Managed via `favorites_service.dart` and persistent storage
- **Mini Player:** Enhanced controls, long-press for settings
- **Notifications:** Android media controls via `notification_service.dart`
- **Permissions:** Use `permission_handler` for adaptive access

## Integration Points
- **Firebase:** Auth, Google sign-in
- **Local music:** Device scanning, multiple formats (MP3, WAV, etc.)
- **AndroidX Media:** Native notification controls

## Conventions & Best Practices
- **Animations:** Target 60fps, use GPU acceleration
- **Typography:** Inter font via `google_fonts`
- **Code standards:** Follow Flutter/Dart style, add tests for new features
- **File organization:** Keep business logic in `core/services`, UI in `core/widgets` and `ui/`

## Examples
- **Transition navigation:**
  ```dart
  Navigator.push(context, PageTransitions.circleMorph(const HomePage()));
  ```
- **Theme customization:**
  ```dart
  // core/theme/app_theme.dart
  static const Color primaryColor = Color(0xFF00C896);
  ```
- **Favorites usage:**
  ```dart
  FavoritesService.addToFavorites(song);
  ```

## References
- See `README.md` for feature details, architecture, and usage examples.
- Key files: `core/services/music_service.dart`, `core/widgets/mini_player.dart`, `core/transitions/page_transitions.dart`, `core/theme/app_theme.dart`, `ui/full_music_player_page.dart`

---
**If any section is unclear or missing, please provide feedback for improvement.**
