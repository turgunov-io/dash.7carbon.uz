import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/widgets/entity_table.dart';
import '../../../core/ui/widgets/formatters.dart';
import '../../../core/ui/widgets/section_container.dart';
import '../../../core/ui/widgets/state_views.dart';
import '../application/admin_entity_state.dart';
import '../application/admin_providers.dart';
import '../domain/admin_entity_definition.dart';
import '../models/admin_entity_item.dart';
import '../../storage/ui/widgets/storage_upload_button.dart';

class AdminEntityPage extends ConsumerStatefulWidget {
  const AdminEntityPage({
    required this.entityKey,
    this.openCreateOnLoad = false,
    super.key,
  });

  final String entityKey;
  final bool openCreateOnLoad;

  @override
  ConsumerState<AdminEntityPage> createState() => _AdminEntityPageState();
}

class _AdminEntityPageState extends ConsumerState<AdminEntityPage> {
  bool _createOpenedOnce = false;
  final _tuningSearchController = TextEditingController();
  final _partnersSearchController = TextEditingController();
  final _bannersSearchController = TextEditingController();
  final _portfolioSearchController = TextEditingController();
  final _workPostSearchController = TextEditingController();
  final _consultationsSearchController = TextEditingController();
  final _serviceOfferingsSearchController = TextEditingController();
  String _tuningSearchQuery = '';
  String _partnersSearchQuery = '';
  String _bannersSearchQuery = '';
  String _portfolioSearchQuery = '';
  String _workPostSearchQuery = '';
  String _consultationsSearchQuery = '';
  String _serviceOfferingsSearchQuery = '';

  @override
  void dispose() {
    _tuningSearchController.dispose();
    _partnersSearchController.dispose();
    _bannersSearchController.dispose();
    _portfolioSearchController.dispose();
    _workPostSearchController.dispose();
    _consultationsSearchController.dispose();
    _serviceOfferingsSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entity = ref.watch(adminEntityByKeyProvider(widget.entityKey));
    final state = ref.watch(adminEntityControllerProvider(widget.entityKey));
    final controller = ref.read(
      adminEntityControllerProvider(widget.entityKey).notifier,
    );
    final singletonItem = _existingSingletonItem(entity, state);

    if (widget.openCreateOnLoad && !_createOpenedOnce) {
      _createOpenedOnce = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (singletonItem != null) {
          _openEditDialog(entity, controller, singletonItem);
        } else {
          _openCreateDialog(entity, controller);
        }
      });
    }

    return SectionContainer(
      title: entity.title,
      subtitle: 'CRUD для ${entity.endpoint}',
      actions: [
        FilledButton.tonalIcon(
          onPressed: state.submitting ? null : controller.load,
          icon: const Icon(Icons.refresh),
          label: const Text('Обновить'),
        ),
      ],
      child: _buildContent(
        entity: entity,
        state: state,
        controller: controller,
      ),
    );
  }

  Widget _buildContent({
    required AdminEntityDefinition entity,
    required AdminEntityState state,
    required AdminEntityController controller,
  }) {
    if (state.status == AdminLoadStatus.loading && state.items.isEmpty) {
      return const LoadingState();
    }

    if (state.status == AdminLoadStatus.failure && state.items.isEmpty) {
      return ErrorState(
        message: state.errorMessage ?? 'Не удалось загрузить данные.',
        onRetry: controller.load,
      );
    }

    if (entity.key == 'about_page') {
      return _buildAboutPageList(
        entity: entity,
        state: state,
        controller: controller,
      );
    }

    if (state.items.isEmpty) {
      return const EmptyState(message: 'Записи отсутствуют');
    }

    if (entity.key == 'banners') {
      return _buildBannersList(
        entity: entity,
        state: state,
        controller: controller,
      );
    }

    if (entity.key == 'partners') {
      return _buildPartnersList(
        entity: entity,
        state: state,
        controller: controller,
      );
    }

    if (entity.key == 'portfolio_items') {
      return _buildPortfolioList(
        entity: entity,
        state: state,
        controller: controller,
      );
    }

    if (entity.key == 'work_post') {
      return _buildPostCardsList(
        entity: entity,
        state: state,
        controller: controller,
        searchController: _workPostSearchController,
        searchQuery: _workPostSearchQuery,
        onQueryChanged: (value) {
          setState(() {
            _workPostSearchQuery = value;
          });
        },
      );
    }

    if (entity.key == 'consultations') {
      return _buildConsultationsList(
        entity: entity,
        state: state,
        controller: controller,
      );
    }

    if (entity.key == 'tuning') {
      return _buildTuningCards(
        entity: entity,
        state: state,
        controller: controller,
      );
    }

    if (entity.key == 'service_offerings') {
      return _buildServiceOfferingsList(
        entity: entity,
        state: state,
        controller: controller,
      );
    }

    return EntityTable<AdminEntityItem>(
      items: state.items,
      searchHint: 'Поиск',
      searchMatcher: (item, query) {
        if (entity.searchFields.isEmpty) {
          return item.values.values.any(
            (value) => _displayValue(value).toLowerCase().contains(query),
          );
        }
        return entity.searchFields.any((field) {
          return _displayValue(
            item.values[field],
          ).toLowerCase().contains(query);
        });
      },
      columns: [
        ...entity.listFields.map((field) {
          return DataColumnDefinition<AdminEntityItem>(
            label: field.label,
            sortValue: (item) => _sortValue(item.values[field.key]),
            cellBuilder: (item) => SizedBox(
              width: field.width,
              child: Text(
                _displayValue(item.values[field.key]),
                maxLines: field.type == AdminFieldType.multiline ? 3 : 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        }),
        DataColumnDefinition<AdminEntityItem>(
          label: 'Действия',
          cellBuilder: (item) => SizedBox(
            width: 156,
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Детали',
                  onPressed: () =>
                      _openDetailsDialog(entity, controller, item.id),
                  icon: const Icon(Icons.visibility_outlined),
                ),
                IconButton(
                  tooltip: 'Редактировать',
                  onPressed: () => _openEditDialog(entity, controller, item),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Удалить',
                  onPressed: () => _confirmDelete(entity, controller, item.id),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ),
        ),
      ],
      toolbarWidgets: [
        if (state.errorMessage != null)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Text(
              state.errorMessage!,
              style: const TextStyle(color: AppColors.errorAccent),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  Widget _buildBannersList({
    required AdminEntityDefinition entity,
    required AdminEntityState state,
    required AdminEntityController controller,
  }) {
    final query = _bannersSearchQuery.trim().toLowerCase();
    final filtered = state.items
        .where((item) {
          if (query.isEmpty) {
            return true;
          }
          final id = item.id.toString().toLowerCase();
          final title = _displayValue(item.values['title']).toLowerCase();
          final imageUrl = _displayValue(
            item.values['image_url'],
          ).toLowerCase();
          return id.contains(query) ||
              title.contains(query) ||
              imageUrl.contains(query);
        })
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 360,
              child: TextField(
                controller: _bannersSearchController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Поиск по заголовку и URL',
                ),
                onChanged: (value) {
                  setState(() {
                    _bannersSearchQuery = value;
                  });
                },
              ),
            ),
            if (state.errorMessage != null)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Text(
                  state.errorMessage!,
                  style: const TextStyle(color: AppColors.errorAccent),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          const Expanded(
            child: EmptyState(message: 'По выбранным фильтрам записей нет'),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final item = filtered[index];
                final title = _displayValue(item.values['title']);
                final imageUrlText = _displayValue(item.values['image_url']);
                final imageUrl = _normalizedUrl(item.values['image_url']);

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 940;

                        final actionButtons = Wrap(
                          spacing: 2,
                          runSpacing: 2,
                          children: [
                            IconButton(
                              tooltip: 'Детали',
                              onPressed: () => _openDetailsDialog(
                                entity,
                                controller,
                                item.id,
                              ),
                              icon: const Icon(Icons.visibility_outlined),
                            ),
                            IconButton(
                              tooltip: 'Редактировать',
                              onPressed: () =>
                                  _openEditDialog(entity, controller, item),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              tooltip: 'Удалить',
                              onPressed: () =>
                                  _confirmDelete(entity, controller, item.id),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        );

                        final infoBlock = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              maxLines: compact ? 2 : 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                Chip(
                                  label: Text('ID: ${item.id}'),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SelectableText(
                              imageUrlText,
                              maxLines: compact ? 3 : 2,
                            ),
                          ],
                        );

                        if (compact) {
                          return InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () =>
                                _openDetailsDialog(entity, controller, item.id),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AspectRatio(
                                  aspectRatio: 16 / 7,
                                  child: _BannerImagePreview(url: imageUrl),
                                ),
                                const SizedBox(height: 10),
                                infoBlock,
                                const SizedBox(height: 6),
                                actionButtons,
                              ],
                            ),
                          );
                        }

                        return InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () =>
                              _openDetailsDialog(entity, controller, item.id),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 280,
                                height: 130,
                                child: _BannerImagePreview(url: imageUrl),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: infoBlock),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 130,
                                child: Align(
                                  alignment: Alignment.topRight,
                                  child: actionButtons,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  AdminEntityItem? _existingSingletonItem(
    AdminEntityDefinition entity,
    AdminEntityState state,
  ) {
    if (entity.key != 'about_page') {
      return null;
    }
    for (final item in state.items) {
      if (item.id != null) {
        return item;
      }
    }
    return null;
  }

  Widget _buildAboutPageList({
    required AdminEntityDefinition entity,
    required AdminEntityState state,
    required AdminEntityController controller,
  }) {
    final singletonItem = _existingSingletonItem(entity, state);
    final aboutId = singletonItem == null
        ? null
        : int.tryParse(singletonItem.id.toString());
    final metricsEntity = ref.watch(adminEntityByKeyProvider('about_metrics'));
    final metricsState = ref.watch(
      adminEntityControllerProvider('about_metrics'),
    );
    final metricsController = ref.read(
      adminEntityControllerProvider('about_metrics').notifier,
    );
    final sectionsEntity = ref.watch(
      adminEntityByKeyProvider('about_sections'),
    );
    final sectionsState = ref.watch(
      adminEntityControllerProvider('about_sections'),
    );
    final sectionsController = ref.read(
      adminEntityControllerProvider('about_sections').notifier,
    );
    final filtered = state.items;

    return ListView(
      children: [
        if (state.errorMessage != null)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Text(
              state.errorMessage!,
              style: const TextStyle(color: AppColors.errorAccent),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        if (state.errorMessage != null) const SizedBox(height: 12),
        if (singletonItem == null) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: state.submitting
                  ? null
                  : () => _openCreateDialog(entity, controller),
              icon: const Icon(Icons.add),
              label: const Text('Создать'),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (filtered.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: Text('Записи не найдены')),
            ),
          )
        else
          ...filtered.map((item) {
            final missionDescription = _displayValue(
              item.values['mission_description'],
            );

            final actionButtons = Wrap(
              spacing: 2,
              runSpacing: 2,
              children: [
                IconButton(
                  tooltip: 'Редактировать',
                  onPressed: () => _openEditDialog(entity, controller, item),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Удалить',
                  onPressed: () => _confirmDelete(entity, controller, item.id),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            );

            final detailsBlock = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAboutTextSection(
                  context,
                  label: 'Миссия',
                  value: missionDescription,
                  maxLines: 12,
                ),
              ],
            );

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _openDetailsDialog(entity, controller, item.id),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      detailsBlock,
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: actionButtons,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        const SizedBox(height: 16),
        _buildAboutSubsectionTable(
          title: 'Метрики',
          entity: metricsEntity,
          state: metricsState,
          controller: metricsController,
          aboutId: aboutId,
          searchHint: 'Поиск по названию и значению',
          searchMatcher: (item, normalizedQuery) {
            return _displayValue(
                  item.values['metric_label'],
                ).toLowerCase().contains(normalizedQuery) ||
                _displayValue(
                  item.values['metric_value'],
                ).toLowerCase().contains(normalizedQuery);
          },
          columns: [
            DataColumnDefinition<AdminEntityItem>(
              label: 'ID',
              sortValue: (item) => _sortValue(item.values['id']),
              cellBuilder: (item) => Text(item.id.toString()),
            ),
            //   label: 'Ключ',
            DataColumnDefinition<AdminEntityItem>(
              label: 'Название',
              sortValue: (item) => _sortValue(item.values['metric_label']),
              cellBuilder: (item) =>
                  Text(_displayValue(item.values['metric_label'])),
            ),
            DataColumnDefinition<AdminEntityItem>(
              label: 'Значение',
              sortValue: (item) => _sortValue(item.values['metric_value']),
              cellBuilder: (item) =>
                  Text(_displayValue(item.values['metric_value'])),
            ),
            DataColumnDefinition<AdminEntityItem>(
              label: 'Позиция',
              sortValue: (item) => _sortValue(item.values['position']),
              cellBuilder: (item) =>
                  Text(_displayValue(item.values['position'])),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildAboutSubsectionTable(
          title: 'Секции',
          entity: sectionsEntity,
          state: sectionsState,
          controller: sectionsController,
          aboutId: aboutId,
          searchHint: 'Поиск по ключу, заголовку и описанию',
          searchMatcher: (item, normalizedQuery) {
            return _displayValue(
                  item.values['section_key'],
                ).toLowerCase().contains(normalizedQuery) ||
                _displayValue(
                  item.values['title'],
                ).toLowerCase().contains(normalizedQuery) ||
                _displayValue(
                  item.values['description'],
                ).toLowerCase().contains(normalizedQuery);
          },
          columns: [
            DataColumnDefinition<AdminEntityItem>(
              label: 'ID',
              sortValue: (item) => _sortValue(item.values['id']),
              cellBuilder: (item) => Text(item.id.toString()),
            ),
            // DataColumnDefinition<AdminEntityItem>(
            //   label: 'Ключ',
            //   sortValue: (item) => _sortValue(item.values['section_key']),
            //   cellBuilder: (item) =>
            //       Text(_displayValue(item.values['section_key'])),
            // ),
            DataColumnDefinition<AdminEntityItem>(
              label: 'Заголовок',
              sortValue: (item) => _sortValue(item.values['title']),
              cellBuilder: (item) => Text(_displayValue(item.values['title'])),
            ),
            DataColumnDefinition<AdminEntityItem>(
              label: 'Описание',
              sortValue: (item) => _sortValue(item.values['description']),
              cellBuilder: (item) => SizedBox(
                width: 320,
                child: Text(
                  _displayValue(item.values['description']),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            DataColumnDefinition<AdminEntityItem>(
              label: 'Позиция',
              sortValue: (item) => _sortValue(item.values['position']),
              cellBuilder: (item) =>
                  Text(_displayValue(item.values['position'])),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAboutTextSection(
    BuildContext context, {
    required String label,
    required String value,
    bool selectable = false,
    int maxLines = 4,
  }) {
    final textStyle = Theme.of(context).textTheme.bodyMedium;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        if (selectable)
          SelectableText(value, maxLines: maxLines, style: textStyle)
        else
          Text(
            value,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: textStyle,
          ),
      ],
    );
  }

  Widget _buildAboutSubsectionTable({
    required String title,
    required AdminEntityDefinition entity,
    required AdminEntityState state,
    required AdminEntityController controller,
    required int? aboutId,
    required String searchHint,
    required SearchMatcher<AdminEntityItem> searchMatcher,
    required List<DataColumnDefinition<AdminEntityItem>> columns,
  }) {
    final toolbar = <Widget>[
      FilledButton.icon(
        onPressed: state.submitting
            ? null
            : () {
                if (aboutId == null) {
                  _showMessage('Сначала создайте запись страницы "О нас"');
                  return;
                }
                _openCreateDialog(
                  entity,
                  controller,
                  extraPayload: {'about_id': aboutId},
                );
              },
        icon: const Icon(Icons.add),
        label: const Text('Добавить'),
      ),
      // FilledButton.tonalIcon(
      //   onPressed: state.submitting ? null : controller.load,
      //   icon: const Icon(Icons.refresh),
      //   label: const Text('Обновить'),
      // ),
    ];

    if (state.errorMessage != null) {
      toolbar.add(
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Text(
            state.errorMessage!,
            style: const TextStyle(color: AppColors.errorAccent),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    if (state.status == AdminLoadStatus.loading && state.items.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      );
    }

    if (state.status == AdminLoadStatus.failure && state.items.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(state.errorMessage ?? 'Не удалось загрузить данные'),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: controller.load,
                icon: const Icon(Icons.refresh),
                label: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        EntityTable<AdminEntityItem>(
          items: state.items,
          columns: [
            ...columns,
            DataColumnDefinition<AdminEntityItem>(
              label: 'Действия',
              cellBuilder: (item) => _buildEntityActions(
                entity: entity,
                controller: controller,
                item: item,
                aboutId: aboutId,
              ),
            ),
          ],
          showSearch: false,
          searchHint: searchHint,
          searchMatcher: searchMatcher,
          toolbarWidgets: toolbar,
        ),
      ],
    );
  }

  Widget _buildEntityActions({
    required AdminEntityDefinition entity,
    required AdminEntityController controller,
    required AdminEntityItem item,
    int? aboutId,
  }) {
    final editPayload = _hiddenEditPayload(
      entity: entity,
      item: item,
      aboutId: aboutId,
    );

    return SizedBox(
      width: 156,
      child: Row(
        children: [
          IconButton(
            tooltip: 'Детали',
            onPressed: () => _openDetailsDialog(entity, controller, item.id),
            icon: const Icon(Icons.visibility_outlined),
          ),
          IconButton(
            tooltip: 'Редактировать',
            onPressed: () => _openEditDialog(
              entity,
              controller,
              item,
              extraPayload: editPayload,
            ),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Удалить',
            onPressed: () => _confirmDelete(entity, controller, item.id),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic>? _hiddenEditPayload({
    required AdminEntityDefinition entity,
    required AdminEntityItem item,
    int? aboutId,
  }) {
    final payload = <String, dynamic>{};
    final rawAboutId = item.values['about_id'];
    final resolvedAboutId =
        aboutId ??
        (rawAboutId == null ? null : int.tryParse(rawAboutId.toString()));

    if (resolvedAboutId != null) {
      payload['about_id'] = resolvedAboutId;
    }

    if (entity.key == 'about_sections') {
      final sectionKey = item.values['section_key']?.toString().trim();
      if (sectionKey != null && sectionKey.isNotEmpty) {
        payload['section_key'] = sectionKey;
      }
    }

    return payload.isEmpty ? null : payload;
  }

  Widget _buildPartnersList({
    required AdminEntityDefinition entity,
    required AdminEntityState state,
    required AdminEntityController controller,
  }) {
    final query = _partnersSearchQuery.trim().toLowerCase();
    final filtered = state.items
        .where((item) {
          if (query.isEmpty) {
            return true;
          }
          final logoUrl = _displayValue(item.values['logo_url']).toLowerCase();
          final id = item.id.toString().toLowerCase();
          return logoUrl.contains(query) || id.contains(query);
        })
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 340,
              child: TextField(
                controller: _partnersSearchController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Поиск по ID или URL логотипа',
                ),
                onChanged: (value) {
                  setState(() {
                    _partnersSearchQuery = value;
                  });
                },
              ),
            ),
            if (state.errorMessage != null)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Text(
                  state.errorMessage!,
                  style: const TextStyle(color: AppColors.errorAccent),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          const Expanded(
            child: EmptyState(message: 'По выбранным фильтрам записей нет'),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final item = filtered[index];
                final logoUrl = _normalizedUrl(item.values['logo_url']);

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 720;

                        final actionButtons = Wrap(
                          spacing: 2,
                          children: [
                            IconButton(
                              tooltip: 'Детали',
                              onPressed: () => _openDetailsDialog(
                                entity,
                                controller,
                                item.id,
                              ),
                              icon: const Icon(Icons.visibility_outlined),
                            ),
                            IconButton(
                              tooltip: 'Редактировать',
                              onPressed: () =>
                                  _openEditDialog(entity, controller, item),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              tooltip: 'Удалить',
                              onPressed: () =>
                                  _confirmDelete(entity, controller, item.id),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        );

                        final infoBlock = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'ID: ${item.id}',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            const SizedBox(height: 6),
                            SelectableText(
                              _displayValue(item.values['logo_url']),
                              maxLines: compact ? 3 : 2,
                            ),
                          ],
                        );

                        if (compact) {
                          return InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () =>
                                _openDetailsDialog(entity, controller, item.id),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  height: 90,
                                  child: _PartnerLogoPreview(url: logoUrl),
                                ),
                                const SizedBox(height: 10),
                                infoBlock,
                                const SizedBox(height: 6),
                                actionButtons,
                              ],
                            ),
                          );
                        }

                        return InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () =>
                              _openDetailsDialog(entity, controller, item.id),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 160,
                                height: 90,
                                child: _PartnerLogoPreview(url: logoUrl),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: infoBlock),
                              const SizedBox(width: 8),
                              actionButtons,
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildPortfolioList({
    required AdminEntityDefinition entity,
    required AdminEntityState state,
    required AdminEntityController controller,
  }) {
    final query = _portfolioSearchQuery.trim().toLowerCase();
    final filtered = state.items
        .where((item) {
          if (query.isEmpty) {
            return true;
          }
          final id = item.id.toString().toLowerCase();
          final brand = _displayValue(item.values['brand']).toLowerCase();
          final title = _displayValue(item.values['title']).toLowerCase();
          final description = _displayValue(
            item.values['description'],
          ).toLowerCase();
          final imageUrl = _displayValue(
            item.values['image_url'],
          ).toLowerCase();
          return id.contains(query) ||
              brand.contains(query) ||
              title.contains(query) ||
              description.contains(query) ||
              imageUrl.contains(query);
        })
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 360,
              child: TextField(
                controller: _portfolioSearchController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Поиск по заголовку, бренду или изображению',
                ),
                onChanged: (value) {
                  setState(() {
                    _portfolioSearchQuery = value;
                  });
                },
              ),
            ),
            if (state.errorMessage != null)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Text(
                  state.errorMessage!,
                  style: const TextStyle(color: AppColors.errorAccent),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          const Expanded(
            child: EmptyState(message: 'По выбранным фильтрам записей нет'),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final item = filtered[index];
                final brand = _displayValue(item.values['brand']);
                final title = _displayValue(item.values['title']);
                final description = _displayValue(item.values['description']);
                final createdAt = _displayValue(item.values['created_at']);
                final imageUrlText = _displayValue(item.values['image_url']);
                final imageUrl = _normalizedUrl(item.values['image_url']);

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 920;

                        final actionButtons = Wrap(
                          spacing: 2,
                          runSpacing: 2,
                          children: [
                            IconButton(
                              tooltip: 'Детали',
                              onPressed: () => _openDetailsDialog(
                                entity,
                                controller,
                                item.id,
                              ),
                              icon: const Icon(Icons.visibility_outlined),
                            ),
                            IconButton(
                              tooltip: 'Редактировать',
                              onPressed: () =>
                                  _openEditDialog(entity, controller, item),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              tooltip: 'Удалить',
                              onPressed: () =>
                                  _confirmDelete(entity, controller, item.id),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        );

                        final chips = <Widget>[
                          Chip(
                            label: Text('ID: ${item.id}'),
                            visualDensity: VisualDensity.compact,
                          ),
                          if (brand != dashValue)
                            Chip(
                              label: Text('Бренд: $brand'),
                              visualDensity: VisualDensity.compact,
                            ),
                          if (createdAt != dashValue)
                            Chip(
                              label: Text('Created: $createdAt'),
                              visualDensity: VisualDensity.compact,
                            ),
                        ];

                        final infoBlock = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              maxLines: compact ? 2 : 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Wrap(spacing: 8, runSpacing: 6, children: chips),
                            const SizedBox(height: 8),
                            Text(
                              description,
                              maxLines: compact ? 4 : 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            SelectableText(
                              imageUrlText,
                              maxLines: compact ? 3 : 2,
                            ),
                          ],
                        );

                        if (compact) {
                          return InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () =>
                                _openDetailsDialog(entity, controller, item.id),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AspectRatio(
                                  aspectRatio: 16 / 9,
                                  child: _BannerImagePreview(url: imageUrl),
                                ),
                                const SizedBox(height: 10),
                                infoBlock,
                                const SizedBox(height: 6),
                                actionButtons,
                              ],
                            ),
                          );
                        }

                        return InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () =>
                              _openDetailsDialog(entity, controller, item.id),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 240,
                                height: 140,
                                child: _BannerImagePreview(url: imageUrl),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: infoBlock),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 130,
                                child: Align(
                                  alignment: Alignment.topRight,
                                  child: actionButtons,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildPostCardsList({
    required AdminEntityDefinition entity,
    required AdminEntityState state,
    required AdminEntityController controller,
    required TextEditingController searchController,
    required String searchQuery,
    required ValueChanged<String> onQueryChanged,
  }) {
    final query = searchQuery.trim().toLowerCase();
    final filtered = state.items
        .where((item) {
          if (query.isEmpty) {
            return true;
          }
          final values = item.values;
          final id = item.id.toString().toLowerCase();
          final title = _displayValue(
            _firstValueByKeys(values, const ['title_model', 'title']),
          ).toLowerCase();
          final description = _displayValue(
            _firstValueByKeys(values, const [
              'card_description',
              'description',
            ]),
          ).toLowerCase();
          final fullDescription = _displayValue(
            _firstValueByKeys(values, const [
              'full_description',
              'fullDescription',
            ]),
          ).toLowerCase();
          final imageUrl = _displayValue(
            _firstValueByKeys(values, const [
              'card_image_url',
              'image_url',
              'imageUrl',
            ]),
          ).toLowerCase();
          final videoUrl = _displayValue(
            _firstValueByKeys(values, const [
              'video_link',
              'video_url',
              'videoUrl',
            ]),
          ).toLowerCase();
          final gallery = _extractUrlListByKeys(values, const [
            'full_image_url',
            'gallery_images',
            'galleryImages',
          ]).join(' ').toLowerCase();
          return id.contains(query) ||
              title.contains(query) ||
              description.contains(query) ||
              fullDescription.contains(query) ||
              imageUrl.contains(query) ||
              videoUrl.contains(query) ||
              gallery.contains(query);
        })
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 360,
              child: TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Поиск по заголовку, описанию, фото или видео URL',
                ),
                onChanged: onQueryChanged,
              ),
            ),
            if (state.errorMessage != null)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Text(
                  state.errorMessage!,
                  style: const TextStyle(color: AppColors.errorAccent),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          const Expanded(
            child: EmptyState(message: 'По выбранным фильтрам записей нет'),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final item = filtered[index];
                final values = item.values;
                final title = _displayValue(
                  _firstValueByKeys(values, const ['title_model', 'title']),
                );
                final description = _displayValue(
                  _firstValueByKeys(values, const [
                    'card_description',
                    'description',
                  ]),
                );
                final fullDescription = _displayValue(
                  _firstValueByKeys(values, const [
                    'full_description',
                    'fullDescription',
                  ]),
                );
                final previewText = description == dashValue
                    ? fullDescription
                    : description;
                final createdAt = _displayValue(values['created_at']);
                final imageValue = _firstValueByKeys(values, const [
                  'card_image_url',
                  'image_url',
                  'imageUrl',
                ]);
                final galleryUrls = _extractUrlListByKeys(values, const [
                  'full_image_url',
                  'gallery_images',
                  'galleryImages',
                ]);
                final imageUrl =
                    _normalizedUrl(imageValue) ??
                    (galleryUrls.isNotEmpty ? galleryUrls.first : null);
                final imageUrlText = _displayValue(
                  imageValue ??
                      (galleryUrls.isNotEmpty ? galleryUrls.first : null),
                );
                final videoUrl = _displayValue(
                  _firstValueByKeys(values, const [
                    'video_link',
                    'video_url',
                    'videoUrl',
                  ]),
                );

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 920;

                        final actionButtons = Wrap(
                          spacing: 2,
                          runSpacing: 2,
                          children: [
                            IconButton(
                              tooltip: 'Детали',
                              onPressed: () => _openDetailsDialog(
                                entity,
                                controller,
                                item.id,
                              ),
                              icon: const Icon(Icons.visibility_outlined),
                            ),
                            IconButton(
                              tooltip: 'Edit',
                              onPressed: () =>
                                  _openEditDialog(entity, controller, item),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              tooltip: 'Удалить',
                              onPressed: () =>
                                  _confirmDelete(entity, controller, item.id),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        );

                        final chips = <Widget>[
                          Chip(
                            label: Text('ID: ${item.id}'),
                            visualDensity: VisualDensity.compact,
                          ),
                          if (createdAt != dashValue)
                            Chip(
                              label: Text('Created: $createdAt'),
                              visualDensity: VisualDensity.compact,
                            ),
                          if (videoUrl != dashValue)
                            const Chip(
                              label: Text('Видео'),
                              visualDensity: VisualDensity.compact,
                            ),
                          if (galleryUrls.isNotEmpty)
                            Chip(
                              label: Text('Фото: ${galleryUrls.length}'),
                              visualDensity: VisualDensity.compact,
                            ),
                        ];

                        final infoBlock = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              maxLines: compact ? 2 : 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Wrap(spacing: 8, runSpacing: 6, children: chips),
                            const SizedBox(height: 8),
                            Text(
                              previewText,
                              maxLines: compact ? 4 : 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            SelectableText(
                              imageUrlText,
                              maxLines: compact ? 3 : 2,
                            ),
                            if (galleryUrls.isNotEmpty)
                              TextButton.icon(
                                onPressed: () => _openImageGalleryDialog(
                                  title: title,
                                  urls: galleryUrls,
                                ),
                                icon: const Icon(Icons.photo_library_outlined),
                                label: Text('Галерея (${galleryUrls.length})'),
                              ),
                          ],
                        );

                        if (compact) {
                          return InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () =>
                                _openDetailsDialog(entity, controller, item.id),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AspectRatio(
                                  aspectRatio: 16 / 9,
                                  child: _BannerImagePreview(url: imageUrl),
                                ),
                                const SizedBox(height: 10),
                                infoBlock,
                                const SizedBox(height: 6),
                                actionButtons,
                              ],
                            ),
                          );
                        }

                        return InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () =>
                              _openDetailsDialog(entity, controller, item.id),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 240,
                                height: 140,
                                child: _BannerImagePreview(url: imageUrl),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: infoBlock),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 130,
                                child: Align(
                                  alignment: Alignment.topRight,
                                  child: actionButtons,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildConsultationsList({
    required AdminEntityDefinition entity,
    required AdminEntityState state,
    required AdminEntityController controller,
  }) {
    final query = _consultationsSearchQuery.trim().toLowerCase();
    final filtered = state.items
        .where((item) {
          if (query.isEmpty) {
            return true;
          }
          final id = item.id.toString().toLowerCase();
          final firstName = _displayValue(
            item.values['first_name'],
          ).toLowerCase();
          final lastName = _displayValue(
            item.values['last_name'],
          ).toLowerCase();
          final phone = _displayValue(item.values['phone']).toLowerCase();
          final serviceType = _displayValue(
            item.values['service_type'],
          ).toLowerCase();
          final status = _displayValue(item.values['status']).toLowerCase();
          final comments = _displayValue(item.values['comments']).toLowerCase();
          return id.contains(query) ||
              firstName.contains(query) ||
              lastName.contains(query) ||
              phone.contains(query) ||
              serviceType.contains(query) ||
              status.contains(query) ||
              comments.contains(query);
        })
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 380,
              child: TextField(
                controller: _consultationsSearchController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Поиск по имени, телефону, услуге или статусу',
                ),
                onChanged: (value) {
                  setState(() {
                    _consultationsSearchQuery = value;
                  });
                },
              ),
            ),
            if (state.errorMessage != null)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Text(
                  state.errorMessage!,
                  style: const TextStyle(color: AppColors.errorAccent),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          const Expanded(
            child: EmptyState(message: 'По выбранным фильтрам записей нет'),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final item = filtered[index];
                final firstName = _displayValue(item.values['first_name']);
                final lastName = _displayValue(item.values['last_name']);
                final phone = _displayValue(item.values['phone']);
                final serviceType = _displayValue(item.values['service_type']);
                final carModel = _displayValue(item.values['car_model']);
                final preferredCallTime = _displayValue(
                  item.values['preferred_call_time'],
                );
                final comments = _displayValue(item.values['comments']);
                final status = _displayValue(item.values['status']);
                final createdAt = _displayValue(item.values['created_at']);
                final fullName = ('$firstName $lastName').trim();

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 920;

                        final actionButtons = Wrap(
                          spacing: 2,
                          runSpacing: 2,
                          children: [
                            IconButton(
                              tooltip: 'Детали',
                              onPressed: () => _openDetailsDialog(
                                entity,
                                controller,
                                item.id,
                              ),
                              icon: const Icon(Icons.visibility_outlined),
                            ),
                            IconButton(
                              tooltip: 'Edit',
                              onPressed: () =>
                                  _openEditDialog(entity, controller, item),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              tooltip: 'Удалить',
                              onPressed: () =>
                                  _confirmDelete(entity, controller, item.id),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        );

                        final infoBlock = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              fullName == dashValue ? 'Консультация' : fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                Chip(
                                  label: Text('ID: ${item.id}'),
                                  visualDensity: VisualDensity.compact,
                                ),
                                Chip(
                                  label: Text('Status: $status'),
                                  visualDensity: VisualDensity.compact,
                                ),
                                if (createdAt != dashValue)
                                  Chip(
                                    label: Text('Created: $createdAt'),
                                    visualDensity: VisualDensity.compact,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Телефон: $phone',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Услуга: $serviceType',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (carModel != dashValue)
                              Text(
                                'Модель авто: $carModel',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            if (preferredCallTime != dashValue)
                              Text(
                                'Удобное время звонка: $preferredCallTime',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            if (comments != dashValue) ...[
                              const SizedBox(height: 6),
                              Text(
                                comments,
                                maxLines: compact ? 4 : 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        );

                        if (compact) {
                          return InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () =>
                                _openDetailsDialog(entity, controller, item.id),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                infoBlock,
                                const SizedBox(height: 6),
                                actionButtons,
                              ],
                            ),
                          );
                        }

                        return InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () =>
                              _openDetailsDialog(entity, controller, item.id),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: infoBlock),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 130,
                                child: Align(
                                  alignment: Alignment.topRight,
                                  child: actionButtons,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildTuningCards({
    required AdminEntityDefinition entity,
    required AdminEntityState state,
    required AdminEntityController controller,
  }) {
    final query = _tuningSearchQuery.trim().toLowerCase();
    final filtered = state.items
        .where((item) {
          if (query.isEmpty) {
            return true;
          }
          final title = _displayValue(item.values['title']).toLowerCase();
          final brand = _displayValue(item.values['brand']).toLowerCase();
          final model = _displayValue(item.values['model']).toLowerCase();
          final price = _displayValue(item.values['price']).toLowerCase();
          final description = _displayValue(
            item.values['description'],
          ).toLowerCase();
          final cardDescription = _displayValue(
            item.values['card_description'],
          ).toLowerCase();
          final fullDescription = _displayValue(
            item.values['full_description'],
          ).toLowerCase();
          final videoLink = _displayValue(
            item.values['video_link'],
          ).toLowerCase();
          return title.contains(query) ||
              brand.contains(query) ||
              model.contains(query) ||
              price.contains(query) ||
              description.contains(query) ||
              cardDescription.contains(query) ||
              fullDescription.contains(query) ||
              videoLink.contains(query);
        })
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 320,
              child: TextField(
                controller: _tuningSearchController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText:
                      'Поиск по бренду, модели, заголовку, описанию, цене',
                ),
                onChanged: (value) {
                  setState(() {
                    _tuningSearchQuery = value;
                  });
                },
              ),
            ),
            if (state.errorMessage != null)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Text(
                  state.errorMessage!,
                  style: const TextStyle(color: AppColors.errorAccent),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          const Expanded(
            child: EmptyState(message: 'По выбранным фильтрам записей нет'),
          )
        else
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 12.0;
                const minTileWidth = 270.0;
                const maxColumns = 4;

                var crossAxisCount =
                    ((constraints.maxWidth + spacing) /
                            (minTileWidth + spacing))
                        .floor();
                if (crossAxisCount < 1) {
                  crossAxisCount = 1;
                }
                if (crossAxisCount > maxColumns) {
                  crossAxisCount = maxColumns;
                }

                final tileWidth =
                    (constraints.maxWidth - (crossAxisCount - 1) * spacing) /
                    crossAxisCount;
                final childAspectRatio = _tuningCardAspectRatio(tileWidth);

                return GridView.builder(
                  itemCount: filtered.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: spacing,
                    crossAxisSpacing: spacing,
                    childAspectRatio: childAspectRatio,
                  ),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final title = _displayValue(
                      _firstValueByKeys(item.values, const [
                        'title',
                        'description',
                        'card_description',
                      ]),
                    );
                    final brand = _displayValue(item.values['brand']);
                    final model = _displayValue(item.values['model']);
                    final price = _displayValue(item.values['price']);
                    final description = _displayValue(
                      item.values['description'],
                    );
                    final cardDescription = _displayValue(
                      item.values['card_description'],
                    );
                    final fullDescription = _displayValue(
                      item.values['full_description'],
                    );
                    final previewText = cardDescription != dashValue
                        ? cardDescription
                        : (description != dashValue
                              ? description
                              : fullDescription);
                    final cardImageUrl = _normalizedUrl(
                      item.values['card_image_url'],
                    );
                    final videoImageUrl = _normalizedUrl(
                      item.values['video_image_url'],
                    );
                    final videoLink = _displayValue(item.values['video_link']);
                    final galleryUrls = _extractUrlList(
                      item.values['full_image_url'],
                    );
                    final createdAt = _displayValue(item.values['created_at']);
                    final updatedAt = _displayValue(item.values['updated_at']);
                    final metaParts = <String>[
                      if (galleryUrls.isNotEmpty) 'Фото: ${galleryUrls.length}',
                      if (videoLink != dashValue || videoImageUrl != null)
                        'Видео',
                      if (createdAt != dashValue) 'Создано: $createdAt',
                      if (updatedAt != dashValue) 'Обновлено: $updatedAt',
                    ];
                    final metaLine = metaParts.join(' • ');

                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () =>
                          _openDetailsDialog(entity, controller, item.id),
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AspectRatio(
                              aspectRatio: 21 / 9,
                              child: _TuningCardImage(url: cardImageUrl),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$brand / $model',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Цена: $price',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (metaLine.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        metaLine,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ],
                                    if (previewText != dashValue)
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            top: 6,
                                          ),
                                          child: Text(
                                            previewText,
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                          ),
                                        ),
                                      )
                                    else
                                      const Spacer(),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        IconButton(
                                          tooltip: 'Редактировать',
                                          onPressed: () => _openEditDialog(
                                            entity,
                                            controller,
                                            item,
                                          ),
                                          visualDensity: VisualDensity.compact,
                                          constraints: const BoxConstraints(
                                            minWidth: 36,
                                            minHeight: 36,
                                          ),
                                          padding: EdgeInsets.zero,
                                          iconSize: 20,
                                          icon: const Icon(Icons.edit_outlined),
                                        ),
                                        IconButton(
                                          tooltip: 'Удалить',
                                          onPressed: () => _confirmDelete(
                                            entity,
                                            controller,
                                            item.id,
                                          ),
                                          visualDensity: VisualDensity.compact,
                                          constraints: const BoxConstraints(
                                            minWidth: 36,
                                            minHeight: 36,
                                          ),
                                          padding: EdgeInsets.zero,
                                          iconSize: 20,
                                          icon: const Icon(
                                            Icons.delete_outline,
                                          ),
                                        ),
                                        const Spacer(),
                                        TextButton(
                                          onPressed: () => _openDetailsDialog(
                                            entity,
                                            controller,
                                            item.id,
                                          ),
                                          style: TextButton.styleFrom(
                                            minimumSize: const Size(0, 34),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                            ),
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                          ),
                                          child: const Text('Подробнее'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  double _tuningCardAspectRatio(double tileWidth) {
    if (tileWidth < 300) {
      return 0.78;
    }
    if (tileWidth < 360) {
      return 0.86;
    }
    return 0.92;
  }

  Widget _buildServiceOfferingsList({
    required AdminEntityDefinition entity,
    required AdminEntityState state,
    required AdminEntityController controller,
  }) {
    final query = _serviceOfferingsSearchQuery.trim().toLowerCase();
    final filtered = state.items
        .where((item) {
          if (query.isEmpty) {
            return true;
          }
          final id = item.id.toString().toLowerCase();
          final serviceType = _displayValue(
            item.values['service_type'],
          ).toLowerCase();
          final title = _displayValue(item.values['title']).toLowerCase();
          final description = _displayValue(
            item.values['detailed_description'],
          ).toLowerCase();
          final priceText = _displayValue(
            item.values['price_text'],
          ).toLowerCase();
          final gallery = _extractUrlList(
            item.values['gallery_images'],
          ).join(' ').toLowerCase();
          return id.contains(query) ||
              serviceType.contains(query) ||
              title.contains(query) ||
              description.contains(query) ||
              priceText.contains(query) ||
              gallery.contains(query);
        })
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 420,
              child: TextField(
                controller: _serviceOfferingsSearchController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Поиск по услуге, заголовку, описанию или фото',
                ),
                onChanged: (value) {
                  setState(() {
                    _serviceOfferingsSearchQuery = value;
                  });
                },
              ),
            ),
            if (state.errorMessage != null)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Text(
                  state.errorMessage!,
                  style: const TextStyle(color: AppColors.errorAccent),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          const Expanded(
            child: EmptyState(message: 'По выбранным фильтрам записей нет'),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final item = filtered[index];
                final title = _displayValue(item.values['title']);
                final serviceType = _displayValue(item.values['service_type']);
                final description = _displayValue(
                  item.values['detailed_description'],
                );
                final priceText = _displayValue(item.values['price_text']);
                final position = _displayValue(item.values['position']);
                final createdAt = _displayValue(item.values['created_at']);
                final galleryUrls = _extractUrlList(
                  item.values['gallery_images'],
                );
                final previewUrl = galleryUrls.isEmpty
                    ? null
                    : galleryUrls.first;

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 960;
                        final actionButtons = Wrap(
                          spacing: 2,
                          runSpacing: 2,
                          children: [
                            IconButton(
                              tooltip: 'Детали',
                              onPressed: () => _openDetailsDialog(
                                entity,
                                controller,
                                item.id,
                              ),
                              icon: const Icon(Icons.visibility_outlined),
                            ),
                            IconButton(
                              tooltip: 'Edit',
                              onPressed: () =>
                                  _openEditDialog(entity, controller, item),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              tooltip: 'Удалить',
                              onPressed: () =>
                                  _confirmDelete(entity, controller, item.id),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        );

                        final chips = <Widget>[
                          Chip(
                            label: Text('ID: ${item.id}'),
                            visualDensity: VisualDensity.compact,
                          ),
                          if (serviceType != dashValue)
                            Chip(
                              label: Text(serviceType),
                              visualDensity: VisualDensity.compact,
                            ),
                          if (priceText != dashValue)
                            Chip(
                              label: Text('Цена: $priceText'),
                              visualDensity: VisualDensity.compact,
                            ),
                          if (position != dashValue)
                            Chip(
                              label: Text('Позиция: $position'),
                              visualDensity: VisualDensity.compact,
                            ),
                          if (createdAt != dashValue)
                            Chip(
                              label: Text('Created: $createdAt'),
                              visualDensity: VisualDensity.compact,
                            ),
                          Chip(
                            label: Text('Фото: ${galleryUrls.length}'),
                            visualDensity: VisualDensity.compact,
                          ),
                        ];

                        final infoBlock = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              maxLines: compact ? 2 : 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Wrap(spacing: 8, runSpacing: 6, children: chips),
                            const SizedBox(height: 8),
                            Text(
                              description,
                              maxLines: compact ? 5 : 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            if (galleryUrls.isEmpty)
                              const Text('Gallery: —')
                            else
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  ...galleryUrls
                                      .take(compact ? 4 : 6)
                                      .map(
                                        (url) => SizedBox(
                                          width: 56,
                                          height: 56,
                                          child: _BannerImagePreview(url: url),
                                        ),
                                      ),
                                  if (galleryUrls.length > (compact ? 4 : 6))
                                    Chip(
                                      label: Text(
                                        '+${galleryUrls.length - (compact ? 4 : 6)}',
                                      ),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                ],
                              ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: galleryUrls.isEmpty
                                    ? null
                                    : () => _openImageGalleryDialog(
                                        title: title,
                                        urls: galleryUrls,
                                      ),
                                icon: const Icon(Icons.photo_library_outlined),
                                label: const Text('Открыть галерею'),
                              ),
                            ),
                          ],
                        );

                        final preview = AspectRatio(
                          aspectRatio: 16 / 9,
                          child: _BannerImagePreview(url: previewUrl),
                        );

                        if (compact) {
                          return InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () =>
                                _openDetailsDialog(entity, controller, item.id),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                preview,
                                const SizedBox(height: 10),
                                infoBlock,
                                const SizedBox(height: 6),
                                actionButtons,
                              ],
                            ),
                          );
                        }

                        return InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () =>
                              _openDetailsDialog(entity, controller, item.id),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 250,
                                height: 142,
                                child: _BannerImagePreview(url: previewUrl),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: infoBlock),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 130,
                                child: Align(
                                  alignment: Alignment.topRight,
                                  child: actionButtons,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Future<void> _openCreateDialog(
    AdminEntityDefinition entity,
    AdminEntityController controller, {
    Map<String, dynamic>? extraPayload,
  }) async {
    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) =>
          _EntityFormDialog(title: 'Создать запись', entity: entity),
    );
    if (payload == null) {
      return;
    }

    final Map<String, dynamic> nextPayload;
    if (extraPayload == null) {
      nextPayload = payload;
    } else {
      nextPayload = Map<String, dynamic>.from(payload)..addAll(extraPayload);
    }

    try {
      await controller.create(nextPayload);
      _showMessage('Запись создана');
    } on ApiError catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage('Не удалось создать запись. Проверьте заполнение полей.');
    }
  }

  Future<void> _openEditDialog(
    AdminEntityDefinition entity,
    AdminEntityController controller,
    AdminEntityItem item, {
    Map<String, dynamic>? extraPayload,
  }) async {
    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _EntityFormDialog(
        title: 'Редактировать запись',
        entity: entity,
        initialValues: _normalizedFormValues(entity, item.values),
      ),
    );
    if (payload == null) {
      return;
    }

    final Map<String, dynamic> nextPayload;
    if (extraPayload == null) {
      nextPayload = payload;
    } else {
      nextPayload = Map<String, dynamic>.from(payload)..addAll(extraPayload);
    }

    try {
      await controller.update(item.id, nextPayload);
      _showMessage('Запись обновлена');
    } on ApiError catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage('Не удалось обновить запись. Проверьте заполнение полей.');
    }
  }

  Map<String, dynamic> _normalizedFormValues(
    AdminEntityDefinition entity,
    Map<String, dynamic> values,
  ) {
    final normalized = Map<String, dynamic>.from(values);

    dynamic pick(List<String> keys) {
      for (final key in keys) {
        if (!normalized.containsKey(key)) {
          continue;
        }
        final value = normalized[key];
        if (value == null) {
          continue;
        }
        if (value is String && value.trim().isEmpty) {
          continue;
        }
        return value;
      }
      return null;
    }

    if (entity.key == 'tuning') {
      normalized['description'] ??= pick(const ['title', 'card_description']);
      return normalized;
    }

    if (entity.key != 'work_post') {
      return normalized;
    }

    normalized['title_model'] ??= pick(const ['title']);
    normalized['card_description'] ??= pick(const ['description']);
    normalized['full_description'] ??= pick(const ['fullDescription']);
    normalized['card_image_url'] ??= pick(const ['image_url', 'imageUrl']);
    normalized['video_link'] ??= pick(const ['video_url', 'videoUrl']);
    normalized['work_list'] ??= pick(const ['performedWorks']);
    normalized['full_image_url'] ??= pick(const [
      'gallery_images',
      'galleryImages',
    ]);
    return normalized;
  }

  Future<void> _confirmDelete(
    AdminEntityDefinition entity,
    AdminEntityController controller,
    dynamic id,
  ) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Удаление записи'),
          content: Text('Удалить запись с ID: $id?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Удалить'),
            ),
          ],
        );
      },
    );

    if (approved != true) {
      return;
    }

    try {
      await controller.remove(id);
      _showMessage('Запись удалена');
    } catch (_) {
      _showMessage('Не удалось удалить запись');
    }
  }

  Future<void> _openDetailsDialog(
    AdminEntityDefinition entity,
    AdminEntityController controller,
    dynamic id,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Детали записи #$id'),
          content: SizedBox(
            width: MediaQuery.sizeOf(context).width < 820
                ? MediaQuery.sizeOf(context).width * 0.9
                : 720,
            child: FutureBuilder<AdminEntityItem>(
              future: controller.fetchDetails(id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text('Ошибка загрузки: ${snapshot.error}');
                }
                final item = snapshot.data;
                if (item == null) {
                  return const Text('Запись не найдена');
                }

                if (entity.key == 'about_page') {
                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'mission_description',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          _displayValue(item.values['mission_description']),
                        ),
                      ],
                    ),
                  );
                }

                final sortedEntries = item.values.entries.toList()
                  ..sort((a, b) => a.key.compareTo(b.key));
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: sortedEntries
                        .map(
                          (entry) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.key,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.labelMedium,
                                ),
                                const SizedBox(height: 4),
                                SelectableText(_displayValue(entry.value)),
                              ],
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () async {
                try {
                  final item = await controller.fetchDetails(id);
                  if (!context.mounted) {
                    return;
                  }
                  Navigator.of(context).pop();
                  await _openEditDialog(
                    entity,
                    controller,
                    item,
                    extraPayload: _hiddenEditPayload(
                      entity: entity,
                      item: item,
                    ),
                  );
                } catch (_) {
                  if (!mounted) {
                    return;
                  }
                  _showMessage(
                    'Не удалось загрузить запись для редактирования',
                  );
                }
              },
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Редактировать'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Закрыть'),
            ),
          ],
        );
      },
    );
  }

  String _displayValue(dynamic value) {
    if (value == null) {
      return dashValue;
    }

    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        return dashValue;
      }
      final formattedDate = _tryFormatDateTimeString(trimmed);
      return formattedDate ?? trimmed;
    }

    if (value is List) {
      if (value.isEmpty) {
        return dashValue;
      }
      return value.map((item) => item.toString()).join(', ');
    }

    if (value is Map) {
      if (value.isEmpty) {
        return dashValue;
      }
      return const JsonEncoder.withIndent('  ').convert(value);
    }

    return value.toString();
  }

  String? _tryFormatDateTimeString(String value) {
    final looksLikeDateTime = RegExp(
      r'^\d{4}-\d{2}-\d{2}(?:[T ][^ ]+)?(?:Z|[+-]\d{2}:\d{2})?$',
    ).hasMatch(value);
    if (!looksLikeDateTime) {
      return null;
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return null;
    }
    return formatDateTimeOrDash(parsed);
  }

  Object? _sortValue(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num || value is DateTime) {
      return value;
    }
    return _displayValue(value);
  }

  dynamic _firstValueByKeys(Map<String, dynamic> values, List<String> keys) {
    for (final key in keys) {
      if (!values.containsKey(key)) {
        continue;
      }
      final value = values[key];
      if (value == null) {
        continue;
      }
      if (value is String && value.trim().isEmpty) {
        continue;
      }
      return value;
    }
    return null;
  }

  List<String> _extractUrlListByKeys(
    Map<String, dynamic> values,
    List<String> keys,
  ) {
    final urls = <String>{};
    for (final key in keys) {
      for (final url in _extractUrlList(values[key])) {
        urls.add(url);
      }
    }
    return urls.toList(growable: false);
  }

  String? _normalizedUrl(dynamic value) {
    return _resolveImageUrl(value);
  }

  List<String> _extractUrlList(dynamic value) {
    final urls = <String>{};

    void addUrl(dynamic raw) {
      final normalized = _resolveImageUrl(raw);
      if (normalized != null) {
        urls.add(normalized);
      }
    }

    void collect(dynamic source) {
      if (source == null) {
        return;
      }

      if (source is List) {
        for (final item in source) {
          collect(item);
        }
        return;
      }

      if (source is Map) {
        const candidateKeys = <String>[
          'public_url',
          'url',
          'image_url',
          'src',
          'storage_url',
          'path',
        ];
        var hasKnownKey = false;
        for (final key in candidateKeys) {
          if (source.containsKey(key)) {
            hasKnownKey = true;
            collect(source[key]);
          }
        }
        if (!hasKnownKey) {
          for (final entry in source.entries) {
            final key = entry.key.toString().toLowerCase();
            if (key.contains('url') ||
                key.contains('image') ||
                key.contains('path')) {
              collect(entry.value);
            }
          }
        }
        return;
      }

      if (source is String) {
        final normalized = source.trim();
        if (normalized.isEmpty ||
            normalized == dashValue ||
            normalized.toLowerCase() == 'null') {
          return;
        }

        final decoded = _tryJsonDecode(normalized);
        if (decoded is List || decoded is Map) {
          collect(decoded);
          return;
        }

        if (normalized.contains('\n') || normalized.contains(',')) {
          for (final token in normalized.split(RegExp(r'[\n,]'))) {
            collect(token);
          }
          return;
        }

        addUrl(normalized);
        return;
      }

      addUrl(source);
    }

    collect(value);
    return urls.toList(growable: false);
  }

  String? _resolveImageUrl(dynamic value) {
    if (value == null) {
      return null;
    }

    var raw = value.toString().trim();
    if (raw.isEmpty || raw == dashValue || raw.toLowerCase() == 'null') {
      return null;
    }

    if ((raw.startsWith('"') && raw.endsWith('"')) ||
        (raw.startsWith("'") && raw.endsWith("'"))) {
      raw = raw.substring(1, raw.length - 1).trim();
    }

    raw = raw.replaceAll(r'\/', '/').replaceAll(r'\u0026', '&');
    if (raw.isEmpty || raw == dashValue || raw.toLowerCase() == 'null') {
      return null;
    }

    final parsed = Uri.tryParse(raw);
    if (parsed != null && parsed.hasScheme) {
      return raw;
    }

    final base = Uri.tryParse(AppConfig.apiBaseUrl);
    if (base == null) {
      return raw;
    }

    if (raw.startsWith('//')) {
      return '${base.scheme}:$raw';
    }

    if (raw.startsWith('/')) {
      return base.resolve(raw).toString();
    }

    if (raw.contains('/')) {
      return base.resolve('/$raw').toString();
    }

    return null;
  }

  dynamic _tryJsonDecode(String text) {
    try {
      return jsonDecode(text);
    } catch (_) {
      return null;
    }
  }

  Future<void> _openImageGalleryDialog({
    required String title,
    required List<String> urls,
  }) async {
    if (urls.isEmpty) {
      _showMessage('В галерее нет изображений');
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        final width = MediaQuery.sizeOf(context).width;
        final maxWidth = width < 1000 ? width * 0.92 : 980.0;
        return Dialog(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: 760),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Галерея: $title',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: GridView.builder(
                      itemCount: urls.length,
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 250,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.95,
                          ),
                      itemBuilder: (context, index) {
                        final imageUrl = urls[index];
                        return Card(
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => _openSingleImageDialog(imageUrl),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: _BannerImagePreview(url: imageUrl),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    8,
                                    8,
                                    8,
                                    10,
                                  ),
                                  child: Text(
                                    imageUrl,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Закрыть'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openSingleImageDialog(String imageUrl) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 760),
            child: InteractiveViewer(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Не удалось загрузить изображение'),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _TuningCardImage extends StatelessWidget {
  const _TuningCardImage({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null) {
      return _buildFallback(context);
    }

    return Image.network(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return _buildFallback(context);
      },
      loadingBuilder: (context, child, progress) {
        if (progress == null) {
          return child;
        }
        return _buildFallback(context, loading: true);
      },
    );
  }

  Widget _buildFallback(BuildContext context, {bool loading = false}) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: loading
            ? const CircularProgressIndicator(strokeWidth: 2)
            : const Icon(Icons.image_outlined, size: 40),
      ),
    );
  }
}

class _BannerImagePreview extends StatelessWidget {
  const _BannerImagePreview({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null) {
      return _fallback(context);
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        url!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallback(context),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          return _fallback(context, loading: true);
        },
      ),
    );
  }

  Widget _fallback(BuildContext context, {bool loading = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: loading
            ? const CircularProgressIndicator(strokeWidth: 2)
            : const Icon(Icons.image_not_supported_outlined, size: 28),
      ),
    );
  }
}

class _PartnerLogoPreview extends StatelessWidget {
  const _PartnerLogoPreview({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null) {
      return _fallback(context);
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        url!,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _fallback(context),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          return _fallback(context, loading: true);
        },
      ),
    );
  }

  Widget _fallback(BuildContext context, {bool loading = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: loading
            ? const CircularProgressIndicator(strokeWidth: 2)
            : const Icon(Icons.image_not_supported_outlined, size: 28),
      ),
    );
  }
}

class _EntityFormDialog extends ConsumerStatefulWidget {
  const _EntityFormDialog({
    required this.title,
    required this.entity,
    this.initialValues,
  });

  final String title;
  final AdminEntityDefinition entity;
  final Map<String, dynamic>? initialValues;

  @override
  ConsumerState<_EntityFormDialog> createState() => _EntityFormDialogState();
}

class _EntityFormDialogState extends ConsumerState<_EntityFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _controllers;
  late final Map<String, List<TextEditingController>> _arrayControllers;
  final _arrayErrors = <String, String>{};

  List<AdminFieldDefinition> get _formFields {
    return widget.entity.formFields;
  }

  @override
  void initState() {
    super.initState();
    _arrayControllers = {};
    _controllers = {
      for (final field in _formFields)
        if (field.type != AdminFieldType.array)
          field.key: TextEditingController(
            text: _initialText(widget.initialValues?[field.key], field.type),
          ),
    };

    for (final field in _formFields) {
      if (field.type == AdminFieldType.array) {
        final values = _initialArrayValues(
          field,
          widget.initialValues?[field.key],
        );
        final items = values
            .map((value) => TextEditingController(text: value))
            .toList(growable: true);
        if (_isJsonArrayField(field) && items.isEmpty) {
          items.add(TextEditingController());
        }
        _arrayControllers[field.key] = items;
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final list in _arrayControllers.values) {
      for (final controller in list) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: MediaQuery.sizeOf(context).width < 820
            ? MediaQuery.sizeOf(context).width * 0.9
            : 680,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _formFields
                  .map((field) {
                    if (field.type == AdminFieldType.array) {
                      return _buildArrayManager(field);
                    }
                    return _buildTextField(field);
                  })
                  .toList(growable: false),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Сохранить')),
      ],
    );
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _arrayErrors.clear();
    });

    var hasArrayError = false;
    for (final field in _formFields) {
      if (field.type != AdminFieldType.array) {
        continue;
      }
      final values = _collectArrayValues(field);
      if (field.required && values.isEmpty) {
        _arrayErrors[field.key] = _isJsonArrayField(field)
            ? 'Добавьте минимум один пункт'
            : 'Добавьте минимум одно значение';
        hasArrayError = true;
      }
    }

    if (hasArrayError) {
      setState(() {});
      return;
    }

    final result = <String, dynamic>{};
    for (final field in _formFields) {
      if (field.type == AdminFieldType.array) {
        result[field.key] = _collectArrayValues(field);
      } else {
        final raw = _controllers[field.key]!.text.trim();
        if (raw.isEmpty) {
          if (!field.nullable) {
            result[field.key] = '';
          } else {
            result[field.key] = null;
          }
          continue;
        }
        result[field.key] = _parseValue(field, raw);
      }
    }

    Navigator.of(context).pop(result);
  }

  String? _validateField(AdminFieldDefinition field, String? value) {
    final normalized = (value ?? '').trim();
    if (field.required && normalized.isEmpty) {
      return 'Обязательное поле';
    }

    if (normalized.isNotEmpty && field.type == AdminFieldType.number) {
      if (num.tryParse(normalized) == null) {
        return 'Введите число';
      }
    }

    if (normalized.isNotEmpty &&
        (field.type == AdminFieldType.array ||
            field.type == AdminFieldType.json)) {
      try {
        _parseValue(field, normalized);
      } catch (_) {
        return field.type == AdminFieldType.array
            ? 'Некорректный формат массива'
            : 'Некорректный формат данных';
      }
    }

    return null;
  }

  Widget _buildTextField(AdminFieldDefinition field) {
    final controller = _controllers[field.key]!;
    final isLongText =
        field.type == AdminFieldType.multiline ||
        field.type == AdminFieldType.json;
    final uploadable = _isSingleUploadTarget(field);
    final mediaPreview = uploadable
        ? _buildSingleUploadPreview(field, controller.text)
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: controller,
            minLines: isLongText ? 2 : 1,
            maxLines: isLongText ? 6 : 1,
            decoration: InputDecoration(
              labelText: field.required ? '${field.label} *' : field.label,
              helperText: _fieldHelperText(field),
            ),
            validator: (value) => _validateField(field, value),
          ),
          if (uploadable) ...[
            const SizedBox(height: 8),
            StorageUploadButton(
              label: 'Загрузить изображение',
              folder: _suggestedFolder(field),
              onUploaded: (result) {
                controller.text = result.publicUrl;
                setState(() {});
              },
            ),
          ],
          if (mediaPreview != null) ...[
            const SizedBox(height: 10),
            mediaPreview,
          ],
        ],
      ),
    );
  }

  String? _fieldHelperText(AdminFieldDefinition field) {
    if (field.type == AdminFieldType.json) {
      return 'Введите данные';
    }

    if (widget.entity.key == 'tuning') {
      switch (field.key) {
        case 'title':
          return 'Название проекта';
        case 'card_description':
          return 'Текст для карточки в списке';
        case 'full_description':
          return 'Полное описание для детальной страницы';
        default:
          break;
      }
    }

    return null;
  }

  Widget? _buildSingleUploadPreview(AdminFieldDefinition field, String raw) {
    if (!_isPreviewableImageField(field)) {
      return null;
    }

    final previewUrl = _resolvePreviewUrl(raw);
    if (previewUrl == null) {
      return null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Preview', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 6),
        SizedBox(
          height: 160,
          width: double.infinity,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _openImagePreview(previewUrl),
            child: _BannerImagePreview(url: previewUrl),
          ),
        ),
        const SizedBox(height: 6),
        SelectableText(
          previewUrl,
          maxLines: 2,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  bool _isPreviewableImageField(AdminFieldDefinition field) {
    final key = '${widget.entity.key}.${field.key}';
    return _singleImagePreviewTargets.contains(key);
  }

  String? _resolvePreviewUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed == dashValue) {
      return null;
    }

    final parsed = Uri.tryParse(trimmed);
    if (parsed != null && parsed.hasScheme) {
      return trimmed;
    }

    final base = Uri.tryParse(AppConfig.apiBaseUrl);
    if (base == null) {
      return trimmed;
    }

    if (trimmed.startsWith('//')) {
      return '${base.scheme}:$trimmed';
    }
    if (trimmed.startsWith('/')) {
      return base.resolve(trimmed).toString();
    }
    if (trimmed.contains('/')) {
      return base.resolve('/$trimmed').toString();
    }

    return null;
  }

  Future<void> _openImagePreview(String imageUrl) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 760),
            child: InteractiveViewer(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Не удалось загрузить изображение'),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildArrayManager(AdminFieldDefinition field) {
    final items = _arrayControllers[field.key]!;
    final uploadable = _isArrayUploadTarget(field);
    final jsonArrayField = _isJsonArrayField(field);
    final hideManualAddButton = uploadable && !jsonArrayField;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  field.required ? '${field.label} *' : field.label,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (!hideManualAddButton)
                  OutlinedButton.icon(
                    onPressed: () => _addArrayItem(field.key),
                    icon: const Icon(Icons.add),
                    label: Text(
                      jsonArrayField ? 'Добавить пункт' : 'Добавить значение',
                    ),
                  ),
                if (uploadable)
                  StorageUploadButton(
                    label: 'Загрузить и добавить',
                    folder: _suggestedFolder(field),
                    onUploaded: (result) {
                      _addArrayItem(field.key, initialValue: result.publicUrl);
                    },
                  ),
              ],
            ),
            if (_arrayErrors[field.key] != null) ...[
              const SizedBox(height: 6),
              Text(
                _arrayErrors[field.key]!,
                style: const TextStyle(color: AppColors.errorAccent),
              ),
            ],
            if (jsonArrayField)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text('Добавляйте пункты работ по одному.'),
              ),
            const SizedBox(height: 8),
            if (items.isEmpty)
              const Text('Список пуст')
            else
              Column(
                children: List.generate(items.length, (index) {
                  final controller = items[index];
                  return Padding(
                    key: ValueKey('${field.key}-$index'),
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller,
                            minLines: jsonArrayField ? 2 : 1,
                            maxLines: jsonArrayField ? 6 : 1,
                            decoration: InputDecoration(
                              labelText: _arrayItemLabel(field, index),
                              hintText: _arrayHintText(field),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Вверх',
                          onPressed: index == 0
                              ? null
                              : () =>
                                    _moveArrayItem(field.key, index, index - 1),
                          icon: const Icon(Icons.arrow_upward_outlined),
                        ),
                        IconButton(
                          tooltip: 'Вниз',
                          onPressed: index == items.length - 1
                              ? null
                              : () =>
                                    _moveArrayItem(field.key, index, index + 1),
                          icon: const Icon(Icons.arrow_downward_outlined),
                        ),
                        IconButton(
                          tooltip: 'Удалить',
                          onPressed: () => _removeArrayItem(field.key, index),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  );
                }),
              ),
          ],
        ),
      ),
    );
  }

  List<dynamic> _collectArrayValues(AdminFieldDefinition field) {
    final values = _arrayControllers[field.key]!
        .map((controller) => controller.text.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);

    if (!_isJsonArrayField(field)) {
      return values;
    }

    return values
        .map((value) => _parseArrayItemValue(field, value))
        .toList(growable: false);
  }

  dynamic _parseArrayItemValue(AdminFieldDefinition field, String raw) {
    if (!_isJsonArrayField(field)) {
      return raw;
    }
    final parsed = _tryJsonDecode(raw);
    return parsed ?? raw;
  }

  bool _isJsonArrayField(AdminFieldDefinition field) {
    return widget.entity.key == 'work_post' && field.key == 'work_list';
  }

  String _arrayItemLabel(AdminFieldDefinition field, int index) {
    if (_isJsonArrayField(field)) {
      return 'Пункт ${index + 1}';
    }
    if (_isArrayUploadTarget(field)) {
      return 'Изображение ${index + 1}';
    }
    return 'Значение ${index + 1}';
  }

  String? _arrayHintText(AdminFieldDefinition field) {
    if (_isJsonArrayField(field)) {
      return 'Например: Полировка кузова';
    }
    if (_isArrayUploadTarget(field)) {
      return 'При необходимости можно вставить ссылку на изображение';
    }
    return null;
  }

  void _addArrayItem(String fieldKey, {String initialValue = ''}) {
    setState(() {
      _arrayControllers[fieldKey]!.add(
        TextEditingController(text: initialValue),
      );
      _arrayErrors.remove(fieldKey);
    });
  }

  void _removeArrayItem(String fieldKey, int index) {
    setState(() {
      final controller = _arrayControllers[fieldKey]!.removeAt(index);
      controller.dispose();
    });
  }

  void _moveArrayItem(String fieldKey, int from, int to) {
    setState(() {
      final items = _arrayControllers[fieldKey]!;
      final value = items.removeAt(from);
      items.insert(to, value);
    });
  }

  bool _isSingleUploadTarget(AdminFieldDefinition field) {
    final key = '${widget.entity.key}.${field.key}';
    return _singleUploadTargets.contains(key);
  }

  bool _isArrayUploadTarget(AdminFieldDefinition field) {
    final key = '${widget.entity.key}.${field.key}';
    return _arrayUploadTargets.contains(key);
  }

  String? _suggestedFolder(AdminFieldDefinition field) {
    final entityKey = widget.entity.key;
    final fieldKey = field.key;
    if (entityKey == 'banners') {
      return 'banners/home';
    }
    if (entityKey == 'partners') {
      return 'partners';
    }
    if (entityKey == 'portfolio_items') {
      return 'portfolio/items';
    }
    if (entityKey == 'about_page' && fieldKey == 'banner_image_url') {
      return 'about/banner';
    }
    if (entityKey == 'about_page' && fieldKey == 'mission_image_url') {
      return 'about/mission';
    }
    if (entityKey == 'tuning' && fieldKey == 'card_image_url') {
      return 'tuning/card';
    }
    if (entityKey == 'tuning' && fieldKey == 'video_image_url') {
      return 'tuning/video';
    }
    if (entityKey == 'tuning' && fieldKey == 'full_image_url') {
      return 'tuning/full';
    }
    if (entityKey == 'service_offerings' && fieldKey == 'gallery_images') {
      return 'service_offerings/gallery';
    }
    if (entityKey == 'work_post' && fieldKey == 'card_image_url') {
      return 'work_post/card';
    }
    if (entityKey == 'work_post' && fieldKey == 'video_image_url') {
      return 'work_post/video';
    }
    if (entityKey == 'work_post' && fieldKey == 'full_image_url') {
      return 'work_post/gallery';
    }
    return entityKey;
  }

  dynamic _parseValue(AdminFieldDefinition field, String raw) {
    switch (field.type) {
      case AdminFieldType.number:
        final parsed = num.tryParse(raw);
        if (parsed == null) {
          return raw;
        }
        return parsed;
      case AdminFieldType.boolean:
        final normalized = raw.toLowerCase();
        if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
          return true;
        }
        if (normalized == 'false' || normalized == '0' || normalized == 'no') {
          return false;
        }
        return raw;
      case AdminFieldType.array:
        final parsedJson = _tryJsonDecode(raw);
        if (parsedJson is List) {
          return parsedJson;
        }
        return raw
            .split(RegExp(r'[\n,]'))
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList(growable: false);
      case AdminFieldType.json:
        final parsed = _tryJsonDecode(raw);
        return parsed ?? raw;
      case AdminFieldType.text:
      case AdminFieldType.multiline:
      case AdminFieldType.dateTime:
        return raw;
    }
  }

  dynamic _tryJsonDecode(String text) {
    try {
      return jsonDecode(text);
    } catch (_) {
      return null;
    }
  }

  String _initialText(dynamic value, AdminFieldType type) {
    if (value == null) {
      return '';
    }
    if (value is String) {
      return value;
    }
    if (value is List || value is Map) {
      if (type == AdminFieldType.array || type == AdminFieldType.json) {
        return const JsonEncoder.withIndent('  ').convert(value);
      }
      return value.toString();
    }
    return value.toString();
  }

  List<String> _initialArrayValues(AdminFieldDefinition field, dynamic value) {
    if (value is List) {
      return value
          .map((item) => _stringifyArrayItem(field, item))
          .toList(growable: false);
    }
    if (value is String) {
      final parsed = _tryJsonDecode(value);
      if (parsed is List) {
        return parsed
            .map((item) => _stringifyArrayItem(field, item))
            .toList(growable: false);
      }
      return value
          .split(RegExp(r'[\n,]'))
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    return const <String>[];
  }

  String _stringifyArrayItem(AdminFieldDefinition field, dynamic item) {
    if (_isJsonArrayField(field) && (item is Map || item is List)) {
      return const JsonEncoder.withIndent('  ').convert(item);
    }
    return item.toString();
  }
}

const _singleUploadTargets = <String>{
  'banners.image_url',
  'about_page.banner_image_url',
  'about_page.mission_image_url',
  'partners.logo_url',
  'portfolio_items.image_url',
  'tuning.card_image_url',
  'tuning.video_image_url',
  'work_post.card_image_url',
  'work_post.video_image_url',
};

const _singleImagePreviewTargets = <String>{
  'banners.image_url',
  'about_page.banner_image_url',
  'about_page.mission_image_url',
  'partners.logo_url',
  'portfolio_items.image_url',
  'tuning.card_image_url',
  'tuning.video_image_url',
  'work_post.card_image_url',
  'work_post.video_image_url',
};

const _arrayUploadTargets = <String>{
  'tuning.full_image_url',
  'service_offerings.gallery_images',
  'work_post.full_image_url',
};
