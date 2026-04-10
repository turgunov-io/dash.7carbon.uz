import 'package:flutter/material.dart';

typedef SearchMatcher<T> = bool Function(T item, String query);

class DataColumnDefinition<T> {
  const DataColumnDefinition({
    required this.label,
    required this.cellBuilder,
    this.sortValue,
    this.numeric = false,
  });

  final String label;
  final Widget Function(T item) cellBuilder;
  final Object? Function(T item)? sortValue;
  final bool numeric;
}

class EntityTable<T> extends StatefulWidget {
  const EntityTable({
    required this.items,
    required this.columns,
    this.searchHint = 'Поиск',
    this.searchMatcher,
    this.showSearch = true,
    this.toolbarWidgets = const <Widget>[],
    super.key,
  });

  final List<T> items;
  final List<DataColumnDefinition<T>> columns;
  final String searchHint;
  final SearchMatcher<T>? searchMatcher;
  final bool showSearch;
  final List<Widget> toolbarWidgets;

  @override
  State<EntityTable<T>> createState() => _EntityTableState<T>();
}

class _EntityTableState<T> extends State<EntityTable<T>> {
  String _query = '';
  int? _sortColumnIndex;
  bool _sortAscending = true;
  final int _rowsPerPage = 10;

  @override
  Widget build(BuildContext context) {
    final filtered = widget.items.where((item) {
      final query = _query.trim().toLowerCase();
      if (query.isEmpty) {
        return true;
      }
      if (widget.searchMatcher != null) {
        return widget.searchMatcher!(item, query);
      }
      return item.toString().toLowerCase().contains(query);
    }).toList();

    if (_sortColumnIndex != null) {
      final column = widget.columns[_sortColumnIndex!];
      if (column.sortValue != null) {
        filtered.sort((a, b) {
          final left = column.sortValue!(a);
          final right = column.sortValue!(b);
          final result = _compare(left, right);
          return _sortAscending ? result : -result;
        });
      }
    }

    final dataSource = _EntityTableSource<T>(
      items: filtered,
      columns: widget.columns,
    );
    final availableRowsPerPage = _buildRowsPerPageOptions(filtered.length);
    final rowsPerPage = _normalizedRowsPerPage(
      current: _rowsPerPage,
      options: availableRowsPerPage,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : MediaQuery.sizeOf(context).width;
            final compact = maxWidth < 760;
            final searchWidth = compact
                ? (maxWidth - 24).clamp(220.0, 420.0).toDouble()
                : 320.0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.showSearch || widget.toolbarWidgets.isNotEmpty)
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (widget.showSearch)
                        SizedBox(
                          width: searchWidth,
                          child: TextField(
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.search),
                              hintText: widget.searchHint,
                            ),
                            onChanged: (value) {
                              setState(() {
                                _query = value;
                              });
                            },
                          ),
                        ),
                      ...widget.toolbarWidgets,
                    ],
                  ),
                if (widget.showSearch || widget.toolbarWidgets.isNotEmpty)
                  const SizedBox(height: 10),
                if (filtered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('Записи не найдены')),
                  )
                else
                  _buildDataTable(
                    context: context,
                    maxWidth: maxWidth,
                    filteredCount: filtered.length,
                    rowsPerPage: rowsPerPage,
                    availableRowsPerPage: availableRowsPerPage,
                    dataSource: dataSource,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDataTable({
    required BuildContext context,
    required double maxWidth,
    required int filteredCount,
    required int rowsPerPage,
    required List<int> availableRowsPerPage,
    required DataTableSource dataSource,
  }) {
    final estimatedTableWidth = widget.columns.length * 180.0;
    final tableWidth = estimatedTableWidth > maxWidth
        ? estimatedTableWidth
        : maxWidth;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: tableWidth, maxWidth: tableWidth),
        child: PaginatedDataTable(
          header: Text('Всего: $filteredCount'),
          columns: List.generate(widget.columns.length, (index) {
            final column = widget.columns[index];
            return DataColumn(
              label: Text(column.label),
              numeric: column.numeric,
              onSort: column.sortValue == null
                  ? null
                  : (columnIndex, ascending) {
                      setState(() {
                        _sortColumnIndex = columnIndex;
                        _sortAscending = ascending;
                      });
                    },
            );
          }),
          source: dataSource,
          rowsPerPage: rowsPerPage,
          availableRowsPerPage: availableRowsPerPage,
          onRowsPerPageChanged: null,
          showFirstLastButtons: true,
          sortColumnIndex: _sortColumnIndex,
          sortAscending: _sortAscending,
          headingRowHeight: 48,
          dataRowMinHeight: 52,
          dataRowMaxHeight: 92,
        ),
      ),
    );
  }

  int _compare(Object? left, Object? right) {
    if (left == null && right == null) {
      return 0;
    }
    if (left == null) {
      return 1;
    }
    if (right == null) {
      return -1;
    }

    if (left is num && right is num) {
      return left.compareTo(right);
    }

    if (left is DateTime && right is DateTime) {
      return left.compareTo(right);
    }

    return left.toString().compareTo(right.toString());
  }

  List<int> _buildRowsPerPageOptions(int total) {
    if (total <= 0) {
      return const [1];
    }

    final defaults = <int>[5, 10, 20, 50];
    final options = defaults.where((value) => value < total).toList()
      ..add(total);
    return options.toSet().toList()..sort();
  }

  int _normalizedRowsPerPage({
    required int current,
    required List<int> options,
  }) {
    if (options.contains(current)) {
      return current;
    }

    final candidates = options.where((value) => value <= current).toList();
    if (candidates.isNotEmpty) {
      return candidates.last;
    }
    return options.first;
  }
}

class _EntityTableSource<T> extends DataTableSource {
  _EntityTableSource({required this.items, required this.columns});

  final List<T> items;
  final List<DataColumnDefinition<T>> columns;

  @override
  DataRow? getRow(int index) {
    if (index >= items.length) {
      return null;
    }

    final item = items[index];
    return DataRow.byIndex(
      index: index,
      cells: columns
          .map((column) => DataCell(column.cellBuilder(item)))
          .toList(growable: false),
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => items.length;

  @override
  int get selectedRowCount => 0;
}
