import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The app language shown in settings. English is offered as a future option;
/// only Indonesian is actually applied for now since all copy is in Bahasa
/// Indonesia.
enum AppLanguage { indonesia, english }

/// Holds the user's preferred theme mode as reactive state.
///
/// State is "isDark": dark is the default (BOB is teal-first). [BobApp] watches
/// this to pick between [AppTheme.dark] and [AppTheme.light] via `themeMode`,
/// so flipping the switch in settings re-themes the whole app instantly.
class ThemeModeController extends Notifier<bool> {
  /// State is "isDark". Starts dark, matching the teal-first design.
  @override
  bool build() => true;

  void setDark(bool value) => state = value;

  void toggle() => state = !state;
}

/// True when dark mode is selected. Dark is the default.
final NotifierProvider<ThemeModeController, bool> isDarkModeProvider =
    NotifierProvider<ThemeModeController, bool>(ThemeModeController.new);

/// Holds the selected language. Indonesian is the default and the only one
/// currently applied.
class LanguageController extends Notifier<AppLanguage> {
  @override
  AppLanguage build() => AppLanguage.indonesia;

  void set(AppLanguage language) => state = language;
}

/// The selected app language.
final NotifierProvider<LanguageController, AppLanguage> languageProvider =
    NotifierProvider<LanguageController, AppLanguage>(LanguageController.new);
