# Repository Guidelines

## Project Structure & Module Organization
This is a Flutter-based TV application (`tv_plus`) designed for large-screen experiences. It uses the **Provider** package for state management and follows a modular directory structure:

- **`lib/models/`**: Data structures representing entities like movies.
- **`lib/providers/`**: State management logic using `ChangeNotifier`.
- **`lib/services/`**: API interaction (TMDB, custom services) and business logic.
- **`lib/screens/`**: High-level UI components and navigation targets.
- **`lib/widgets/`**: Reusable UI components.
- **`assets/`**: Static resources like logos and images.

The application is optimized for TV platforms, incorporating `dpad_container` for focus management and custom shortcuts for D-pad navigation.

## Build, Test, and Development Commands
The project uses standard Flutter tooling:

- **Fetch dependencies**: `flutter pub get`
- **Run the app**: `flutter run`
- **Run static analysis**: `flutter analyze`
- **Run all tests**: `flutter test`
- **Run a specific test**: `flutter test test/widget_test.dart`
- **Build Android APK**: `flutter build apk`
- **Build Windows app**: `flutter build windows`

## Coding Style & Naming Conventions
- **Language**: Dart (SDK ^3.10.4).
- **Style Guide**: Follows the official [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines.
- **Linting**: Rules are enforced via `analysis_options.yaml` (includes `package:flutter_lints/flutter.yaml`).
- **UI**: Material 3 enabled. Uses `GoogleFonts.cairo` for typography and a dark-themed color scheme.
- **TV Support**: Always ensure focusability for interactive widgets and support for directional navigation keys (Select/Enter).

## Testing Guidelines
- **Framework**: `flutter_test` (built-in Flutter testing framework).
- **Location**: All tests reside in the `test/` directory.
- **Execution**: Run `flutter test` to verify code correctness.
