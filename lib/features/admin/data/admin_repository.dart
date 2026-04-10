import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../domain/admin_entity_definition.dart';
import '../models/admin_entity_item.dart';

class AdminRepository {
  const AdminRepository(this._client);

  final ApiClient _client;

  Future<List<AdminEntityItem>> fetchList(AdminEntityDefinition entity) async {
    final payload = await _client.get(entity.endpoint);
    final rows = _extractRows(entity, payload);
    return rows
        .map((row) => AdminEntityItem.fromBackend(row))
        .toList(growable: false);
  }

  Future<AdminEntityItem> fetchDetails(
    AdminEntityDefinition entity,
    dynamic id,
  ) async {
    final payload = await _client.get('${entity.endpoint}/$id');
    final row = _extractDetailRow(entity, payload);
    return AdminEntityItem.fromBackend(row);
  }

  Future<void> create(
    AdminEntityDefinition entity,
    Map<String, dynamic> payload,
  ) async {
    await _client.post(entity.endpoint, data: payload);
  }

  Future<void> update(
    AdminEntityDefinition entity,
    dynamic id,
    Map<String, dynamic> payload,
  ) async {
    if (entity.key == 'about_page') {
      try {
        await _client.patch('${entity.endpoint}/$id', data: payload);
        return;
      } on ApiError catch (error) {
        if (error.statusCode == 404 || error.statusCode == 405) {
          await _client.put('${entity.endpoint}/$id', data: payload);
          return;
        }
        rethrow;
      }
    }

    try {
      await _client.put('${entity.endpoint}/$id', data: payload);
    } on ApiError catch (error) {
      if (error.statusCode == 404 || error.statusCode == 405) {
        await _client.patch('${entity.endpoint}/$id', data: payload);
        return;
      }
      rethrow;
    }
  }

  Future<void> delete(AdminEntityDefinition entity, dynamic id) async {
    if (entity.key == 'about_metrics' || entity.key == 'about_sections') {
      try {
        await _client.delete('${entity.endpoint}/$id');
        return;
      } on ApiError catch (error) {
        if (error.statusCode == 404 ||
            error.statusCode == 405 ||
            error.statusCode == 422) {
          await _client.delete(entity.endpoint, queryParameters: {'id': id});
          return;
        }
        rethrow;
      }
    }

    await _client.delete('${entity.endpoint}/$id');
  }

  Future<int> fetchCount(AdminEntityDefinition entity) async {
    final rows = await fetchList(entity);
    return rows.length;
  }

  List<Map<String, dynamic>> _extractRows(
    AdminEntityDefinition entity,
    dynamic payload,
  ) {
    if (payload is List) {
      return payload.whereType<Map>().map(_asMap).toList(growable: false);
    }

    if (payload is Map<String, dynamic>) {
      if (entity.key == 'about_page') {
        final pageRows = _extractAboutPageRows(payload);
        if (pageRows.isNotEmpty) {
          return pageRows;
        }
      }

      final directList = payload['items'] ?? payload['rows'] ?? payload['data'];
      if (directList is List) {
        return directList
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList(growable: false);
      }
      if (directList is Map) {
        return [Map<String, dynamic>.from(directList)];
      }

      return [Map<String, dynamic>.from(payload)];
    }

    return const <Map<String, dynamic>>[];
  }

  Map<String, dynamic> _extractDetailRow(
    AdminEntityDefinition entity,
    dynamic payload,
  ) {
    if (entity.key == 'about_page' && payload is Map<String, dynamic>) {
      final rows = _extractAboutPageRows(payload);
      if (rows.isNotEmpty) {
        return rows.first;
      }
    }
    return _asMap(payload);
  }

  List<Map<String, dynamic>> _extractAboutPageRows(
    Map<String, dynamic> payload,
  ) {
    for (final key in const ['page', 'about_page', 'aboutPage']) {
      if (!payload.containsKey(key)) {
        continue;
      }
      final rows = _extractRowCandidates(payload[key]);
      if (rows.isNotEmpty) {
        return rows;
      }
    }
    return const <Map<String, dynamic>>[];
  }

  List<Map<String, dynamic>> _extractRowCandidates(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);
    }

    if (value is Map<String, dynamic>) {
      final nested = value['items'] ?? value['rows'] ?? value['data'];
      if (nested != null) {
        final rows = _extractRowCandidates(nested);
        if (rows.isNotEmpty) {
          return rows;
        }
      }
      return [Map<String, dynamic>.from(value)];
    }

    if (value is Map) {
      return [Map<String, dynamic>.from(value)];
    }

    return const <Map<String, dynamic>>[];
  }

  Map<String, dynamic> _asMap(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    if (payload is Map) {
      return Map<String, dynamic>.from(payload);
    }
    return <String, dynamic>{};
  }
}
