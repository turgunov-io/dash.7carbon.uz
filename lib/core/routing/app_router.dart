import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/ui/login_page.dart';
import '../../features/admin/domain/admin_entity_registry.dart';
import '../../features/admin/ui/admin_entity_page.dart';
import '../../features/dashboard/ui/consultations_trend_page.dart';
import '../../features/dashboard/ui/dashboard_page.dart';
import '../ui/app_shell.dart';
import 'app_route.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: AppRoutes.dashboard,
    redirect: (context, state) {
      final isLoginRoute = state.uri.path == AppRoutes.login;
      final isAuthenticated = authState.isAuthenticated;

      if (!isAuthenticated && !isLoginRoute) {
        final from = Uri.encodeComponent(state.uri.toString());
        return '${AppRoutes.login}?from=$from';
      }

      if (isAuthenticated && isLoginRoute) {
        final redirectTo = _decodeRedirect(state.uri.queryParameters['from']);
        if (redirectTo != null) {
          return redirectTo;
        }
        return AppRoutes.dashboard;
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (context, state) => AppRoutes.dashboard),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => LoginPage(
          redirectTo: _decodeRedirect(state.uri.queryParameters['from']),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return AppShell(location: state.uri.path, child: child);
        },
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: AppRoutes.dashboardConsultationsTrend,
            builder: (context, state) => const ConsultationsTrendPage(),
          ),
          GoRoute(
            path: '${AppRoutes.entitiesPrefix}/:entityKey',
            redirect: (context, state) {
              final entityKey = state.pathParameters['entityKey'] ?? '';
              if (embeddedAdminEntityKeys.contains(entityKey)) {
                return AppRoutes.entity('about_page');
              }
              return null;
            },
            builder: (context, state) {
              final entityKey = state.pathParameters['entityKey'] ?? '';
              if (!adminEntityMap.containsKey(entityKey)) {
                return const _NotFoundPage();
              }

              return AdminEntityPage(
                entityKey: entityKey,
                openCreateOnLoad: state.uri.queryParameters['create'] == '1',
              );
            },
          ),
        ],
      ),
    ],
  );
});

class _NotFoundPage extends StatelessWidget {
  const _NotFoundPage();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Раздел не найден'));
  }
}

String? _decodeRedirect(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }

  var decoded = value.trim();
  try {
    decoded = Uri.decodeComponent(decoded).trim();
  } catch (_) {
    // Keep original value if it is already decoded or malformed.
  }
  if (!decoded.startsWith('/')) {
    return null;
  }
  if (decoded == AppRoutes.login) {
    return null;
  }
  return decoded;
}
