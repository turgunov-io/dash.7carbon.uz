import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../routing/app_route.dart';
import '../theme/theme_mode_provider.dart';

class AppShell extends ConsumerWidget {
  const AppShell({required this.location, required this.child, super.key});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final selectedIndex = _selectedIndex(location);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    // Mobile/Tablet Layout (< 960px)
    if (width < 960) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leadingWidth: 200,
          leading: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Row(
              children: [
                _ThemeToggleButton(
                  isDark: isDark,
                  onTap: () => _toggleTheme(ref, isDark),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    'Carbon Admin',
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          title: Text(AppRoutes.titleByLocation(location)),
          actions: [
            Builder(
              builder: (context) => IconButton(
                tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
                onPressed: Scaffold.of(context).openDrawer,
                icon: const Icon(Icons.menu),
              ),
            ),
            IconButton(
              tooltip: 'Выйти',
              onPressed: () => _logout(context, ref),
              icon: const Icon(Icons.logout_outlined),
            ),
            const SizedBox(width: 8),
          ],
        ),
        drawer: Drawer(
          child: SafeArea(
            child: Column(
              children: [
                const ListTile(
                  title: Text(
                    'Carbon Admin',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    itemCount: AppRoutes.navItems.length,
                    itemBuilder: (context, index) {
                      final item = AppRoutes.navItems[index];
                      final itemEnabled = item.enabled;
                      return ListTile(
                        selected: selectedIndex == index,
                        enabled: itemEnabled,
                        leading: Icon(item.icon),
                        title: Text(item.title),
                        subtitle: itemEnabled || item.disabledHint == null
                            ? null
                            : Text(item.disabledHint!),
                        onTap: () {
                          Navigator.of(context).pop();
                          _onNavTap(context, item);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        body: child,
      );
    }

    // Desktop Layout (>= 960px)
    final railExtended = width >= 1360;
    return Scaffold(
      body: Row(
        children: [
          SafeArea(
            child: NavigationRail(
              selectedIndex: selectedIndex,
              extended: railExtended,
              // Group alignment pulls destinations to the top
              groupAlignment: -1.0,
              onDestinationSelected: (index) {
                _onNavTap(context, AppRoutes.navItems[index]);
              },
              leading: SizedBox(
                width: railExtended ? 200 : 72,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: railExtended
                        ? MainAxisAlignment.start
                        : MainAxisAlignment.center,
                    children: [
                      _ThemeToggleButton(
                        isDark: isDark,
                        onTap: () => _toggleTheme(ref, isDark),
                      ),
                      if (railExtended) ...[
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            'Carbon Admin',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: railExtended
                        ? SizedBox(
                            width: 160,
                            child: TextButton.icon(
                              onPressed: () => _logout(context, ref),
                              icon: const Icon(Icons.logout_outlined),
                              label: const Text('Выйти'),
                              style: TextButton.styleFrom(
                                alignment: Alignment.centerLeft,
                              ),
                            ),
                          )
                        : IconButton(
                            tooltip: 'Выйти',
                            onPressed: () => _logout(context, ref),
                            icon: const Icon(Icons.logout_outlined),
                          ),
                  ),
                ),
              ),
              destinations: AppRoutes.navItems
                  .map(
                    (item) => NavigationRailDestination(
                      icon: Icon(
                        item.icon,
                        color: item.enabled
                            ? null
                            : Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.38),
                      ),
                      label: Text(item.title),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }

  int? _selectedIndex(String currentLocation) {
    for (var i = 0; i < AppRoutes.navItems.length; i++) {
      if (currentLocation.startsWith(AppRoutes.navItems[i].path)) {
        return i;
      }
    }
    return null; // Return null if no route matches to avoid false highlighting
  }

  void _onNavTap(BuildContext context, AppNavItem item) {
    if (!item.enabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(item.disabledHint ?? 'Раздел временно недоступен'),
        ),
      );
      return;
    }
    context.go(item.path);
  }

  void _toggleTheme(WidgetRef ref, bool isDark) {
    ref.read(themeModeProvider.notifier).state = isDark
        ? ThemeMode.light
        : ThemeMode.dark;
  }

  void _logout(BuildContext context, WidgetRef ref) {
    ref.read(authControllerProvider.notifier).logout();
    context.go(AppRoutes.login);
  }
}

class _ThemeToggleButton extends StatelessWidget {
  const _ThemeToggleButton({required this.isDark, required this.onTap});

  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      tooltip: isDark ? 'Светлая тема' : 'Темная тема',
      onPressed: onTap,
      icon: Icon(
        isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
        size: 20,
      ),
    );
  }
}
