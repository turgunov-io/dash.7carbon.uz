import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final initialThemeModeProvider = Provider<ThemeMode>((_) => ThemeMode.light);

final themeModeStorageProvider = Provider<ThemeModeStorage>(
  (_) => const ThemeModeStorage(),
);

final themeModeProvider = StateNotifierProvider<ThemeModeController, ThemeMode>(
  (ref) {
    return ThemeModeController(
      storage: ref.watch(themeModeStorageProvider),
      initialState: ref.watch(initialThemeModeProvider),
    );
  },
);

class ThemeModeController extends StateNotifier<ThemeMode> {
  ThemeModeController({
    required ThemeModeStorage storage,
    required ThemeMode initialState,
  }) : _storage = storage,
       super(initialState);

  final ThemeModeStorage _storage;

  Future<void> setThemeMode(ThemeMode nextMode) async {
    if (state == nextMode) {
      return;
    }

    state = nextMode;
    await _storage.saveThemeMode(nextMode);
  }

  Future<void> toggleTheme() async {
    await setThemeMode(
      state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
    );
  }
}

class ThemeModeStorage {
  const ThemeModeStorage();

  static const _themeModeKey = 'theme_mode';

  static final Future<SharedPreferences> _prefs =
      SharedPreferences.getInstance();

  Future<ThemeMode?> readThemeMode() async {
    final prefs = await _prefs;
    final rawValue = prefs.getString(_themeModeKey)?.trim();

    switch (rawValue) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      default:
        return null;
    }
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await _prefs;
    await prefs.setString(_themeModeKey, _serialize(mode));
  }

  String _serialize(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.light:
        return 'light';
      case ThemeMode.system:
        return 'system';
    }
  }
}
