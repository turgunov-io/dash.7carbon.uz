import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../routing/app_route.dart';
import '../theme/app_colors.dart';
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

    if (width < 960) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          titleSpacing: 12,
          title: Row(
            children: [
              _ThemeToggleButton(
                isDark: isDark,
                onTap: () => _toggleTheme(ref),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Carbon Admin',
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      AppRoutes.titleByLocation(location),
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            Builder(
              builder: (context) => IconButton(
                tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
                onPressed: Scaffold.of(context).openDrawer,
                icon: const Icon(Icons.menu_rounded),
              ),
            ),
            IconButton(
              tooltip: 'Выйти',
              onPressed: () => _logout(context, ref),
              icon: const Icon(Icons.logout_outlined),
            ),
            const SizedBox(width: 4),
          ],
        ),
        drawer: Drawer(
          child: _Sidebar(
            selectedIndex: selectedIndex,
            isDark: isDark,
            onNavTap: (item) {
              Navigator.of(context).pop();
              _onNavTap(context, item);
            },
            onLogout: () => _logout(context, ref),
            onToggleTheme: () => _toggleTheme(ref),
          ),
        ),
        body: child,
      );
    }

    final sidebarWidth = width >= 1440 ? 288.0 : 264.0;

    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: sidebarWidth,
            child: _Sidebar(
              selectedIndex: selectedIndex,
              isDark: isDark,
              onNavTap: (item) => _onNavTap(context, item),
              onLogout: () => _logout(context, ref),
              onToggleTheme: () => _toggleTheme(ref),
            ),
          ),
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
    return null;
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

  void _toggleTheme(WidgetRef ref) {
    ref.read(themeModeProvider.notifier).toggleTheme();
  }

  void _logout(BuildContext context, WidgetRef ref) {
    ref.read(authControllerProvider.notifier).logout();
    context.go(AppRoutes.login);
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.selectedIndex,
    required this.isDark,
    required this.onNavTap,
    required this.onLogout,
    required this.onToggleTheme,
  });

  final int? selectedIndex;
  final bool isDark;
  final ValueChanged<AppNavItem> onNavTap;
  final VoidCallback onLogout;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = isDark ? AppColors.surfaceDarker : AppColors.white;
    final borderColor = isDark ? AppColors.borderLight : AppColors.black12;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(right: BorderSide(color: borderColor)),
        boxShadow: isDark
            ? null
            : const [
                BoxShadow(
                  color: AppColors.blackOverlayLight,
                  blurRadius: 18,
                  offset: Offset(2, 0),
                ),
              ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Carbon Admin',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Панель управления',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _ThemeToggleButton(isDark: isDark, onTap: onToggleTheme),
                ],
              ),
              const SizedBox(height: 18),
              // Container(
              //   padding: const EdgeInsets.symmetric(
              //     horizontal: 12,
              //     vertical: 10,
              //   ),
              //   decoration: BoxDecoration(
              //     color: colorScheme.surfaceContainerHighest.withValues(
              //       alpha: isDark ? 0.26 : 0.45,
              //     ),
              //     borderRadius: BorderRadius.circular(14),
              //   ),
              //   child: Row(
              //     children: [
              //       Icon(
              //         Icons.space_dashboard_outlined,
              //         size: 18,
              //         color: colorScheme.primary,
              //       ),

              //     ],
              //   ),
              // ),
              // const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: AppRoutes.navItems.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final item = AppRoutes.navItems[index];
                    return _SidebarNavButton(
                      item: item,
                      selected: selectedIndex == index,
                      onTap: () => onNavTap(item),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Divider(color: borderColor, height: 1),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: onLogout,
                style: FilledButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.logout_outlined),
                label: const Text('Выйти'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarNavButton extends StatelessWidget {
  const _SidebarNavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final AppNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEnabled = item.enabled;
    final foregroundColor = !isEnabled
        ? colorScheme.onSurface.withValues(alpha: 0.45)
        : selected
        ? colorScheme.primary
        : colorScheme.onSurface;
    final subtitleColor = !isEnabled
        ? colorScheme.onSurface.withValues(alpha: 0.38)
        : colorScheme.onSurfaceVariant;

    return Material(
      color: selected
          ? colorScheme.primaryContainer.withValues(alpha: 0.52)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? colorScheme.primary.withValues(alpha: 0.18)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: selected
                      ? colorScheme.primary.withValues(alpha: 0.12)
                      : colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.32,
                        ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, size: 20, color: foregroundColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: foregroundColor,
                      ),
                    ),
                    if (!isEnabled && item.disabledHint != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.disabledHint!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: subtitleColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: selected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
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
