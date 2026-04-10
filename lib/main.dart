import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/theme/theme_mode_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const themeModeStorage = ThemeModeStorage();
  final initialThemeMode =
      await themeModeStorage.readThemeMode() ?? ThemeMode.light;

  runApp(
    ProviderScope(
      overrides: [
        themeModeStorageProvider.overrideWith((ref) => themeModeStorage),
        initialThemeModeProvider.overrideWith((ref) => initialThemeMode),
      ],
      child: const CarbonAdminApp(),
    ),
  );
}
