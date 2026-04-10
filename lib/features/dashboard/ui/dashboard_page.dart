import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_route.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/widgets/state_views.dart';
import '../../admin/domain/admin_entity_registry.dart';
import '../application/dashboard_provider.dart';
import '../domain/consultation_trend.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countsAsync = ref.watch(dashboardCountsProvider);
    final trendAsync = ref.watch(dashboardConsultationTrendProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final horizontal = width < 760 ? 12.0 : 20.0;

        return Padding(
          padding: EdgeInsets.fromLTRB(horizontal, 20, horizontal, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Дашборд', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'Сводка по количеству записей и быстрые действия',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.black54),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    onPressed: () =>
                        context.go(AppRoutes.createEntity('banners')),
                    icon: const Icon(Icons.add),
                    label: const Text('Создать баннер'),
                  ),
                  FilledButton.icon(
                    onPressed: () =>
                        context.go(AppRoutes.createEntity('partners')),
                    icon: const Icon(Icons.add),
                    label: const Text('Создать партнера'),
                  ),
                  FilledButton.icon(
                    onPressed: () =>
                        context.go(AppRoutes.createEntity('service_offerings')),
                    icon: const Icon(Icons.add),
                    label: const Text('Создать услугу'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              trendAsync.when(
                data: (trend) => _ConsultationTrendCard(
                  trend: trend,
                  onOpenDetails: () =>
                      context.go(AppRoutes.dashboardConsultationsTrend),
                ),
                loading: () => const SizedBox(
                  height: 280,
                  child: Card(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (error, _) => SizedBox(
                  height: 280,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Записи на консультацию по месяцам',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Не удалось загрузить статистику: $error',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const Spacer(),
                          FilledButton(
                            onPressed: () => ref.invalidate(
                              dashboardConsultationTrendProvider,
                            ),
                            child: const Text('Повторить'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: countsAsync.when(
                  data: (counts) {
                    if (counts.counts.isEmpty) {
                      return const EmptyState(message: 'Нет данных');
                    }

                    final crossAxisCount = width >= 1520
                        ? 5
                        : width >= 1160
                        ? 4
                        : width >= 820
                        ? 3
                        : width >= 560
                        ? 2
                        : 1;

                    final childAspectRatio = width < 560 ? 2.3 : 1.9;

                    return GridView.builder(
                      itemCount: visibleAdminEntities.length + 1,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: childAspectRatio,
                      ),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _CountCard(
                            title: 'Всего записей',
                            value: counts.total,
                            icon: Icons.summarize_outlined,
                            onTap: null,
                          );
                        }

                        final entity = visibleAdminEntities[index - 1];
                        return _CountCard(
                          title: entity.title,
                          value: counts.countFor(entity.key),
                          icon: entity.icon,
                          onTap: () => context.go(AppRoutes.entity(entity.key)),
                        );
                      },
                    );
                  },
                  loading: () => const LoadingState(),
                  error: (error, _) => ErrorState(
                    message: error.toString(),
                    onRetry: () => ref.invalidate(dashboardCountsProvider),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CountCard extends StatelessWidget {
  const _CountCard({
    required this.title,
    required this.value,
    required this.icon,
    this.onTap,
  });

  final String title;
  final int value;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 22),
            const Spacer(),
            Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(
              value.toString(),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      ),
    );

    if (onTap == null) {
      return content;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: content,
    );
  }
}

class _ConsultationTrendCard extends StatelessWidget {
  const _ConsultationTrendCard({
    required this.trend,
    required this.onOpenDetails,
  });

  final DashboardConsultationTrend trend;
  final VoidCallback onOpenDetails;

  static const _months = <String>[
    'янв',
    'фев',
    'мар',
    'апр',
    'май',
    'июн',
    'июл',
    'авг',
    'сен',
    'окт',
    'ноя',
    'дек',
  ];

  @override
  Widget build(BuildContext context) {
    final points = trend.monthlyPoints;
    final maxCount = points.isEmpty
        ? 1
        : points.fold<int>(1, (max, point) {
            return point.count > max ? point.count : max;
          });

    final isGrowth = trend.delta >= 0;
    final deltaPrefix = isGrowth ? '+' : '';
    final deltaColor = isGrowth ? AppColors.success700 : AppColors.error700;

    return SizedBox(
      height: 280,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onOpenDetails,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Записи на консультацию по месяцам',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Открыть подробно',
                      onPressed: onOpenDetails,
                      icon: const Icon(Icons.open_in_new),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Текущий месяц: ${trend.currentMonthCount}. Прошлый месяц: ${trend.previousMonthCount}.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Изменение: $deltaPrefix${trend.delta}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: deltaColor),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var index = 0; index < points.length; index++)
                        Expanded(
                          child: _MonthBar(
                            label: _formatMonth(points[index].monthStartUtc),
                            value: points[index].count,
                            max: maxCount,
                            isCurrent: index == points.length - 1,
                            isPrevious: index == points.length - 2,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Нажмите на график для подробного отчета',
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: AppColors.black54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatMonth(DateTime monthStartUtc) {
    final monthIndex = monthStartUtc.month - 1;
    final month = _months[monthIndex];
    final year = monthStartUtc.year % 100;
    return '$month ${year.toString().padLeft(2, '0')}';
  }
}

class _MonthBar extends StatelessWidget {
  const _MonthBar({
    required this.label,
    required this.value,
    required this.max,
    required this.isCurrent,
    required this.isPrevious,
  });

  final String label;
  final int value;
  final int max;
  final bool isCurrent;
  final bool isPrevious;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = max == 0 ? 0.0 : value / max;
    final barHeight = value == 0 ? 10.0 : 10 + (88 * ratio.clamp(0.0, 1.0));
    final barColor = isCurrent
        ? theme.colorScheme.primary
        : isPrevious
        ? theme.colorScheme.tertiary
        : theme.colorScheme.primary.withValues(alpha: 0.35);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            value.toString(),
            style: theme.textTheme.labelSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 24,
                height: barHeight,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.labelSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
