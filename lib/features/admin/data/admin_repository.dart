import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../domain/admin_entity_definition.dart';
import '../models/admin_entity_item.dart';

class AdminRepository {
  const AdminRepository(this._client);

  final ApiClient _client;

  Future<List<AdminEntityItem>> fetchList(AdminEntityDefinition entity) async {
    final payload = await _client.get(entity.endpoint);
    final rows = _extractRows(payload);
    return rows
        .map((row) => AdminEntityItem.fromBackend(row))
        .toList(growable: false);
  }

  Future<AdminEntityItem> fetchDetails(
    AdminEntityDefinition entity,
    dynamic id,
  ) async {
    final payload = await _client.get('${entity.endpoint}/$id');
    final row = _asMap(payload);
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
    await _client.delete('${entity.endpoint}/$id');
  }

  Future<int> fetchCount(AdminEntityDefinition entity) async {
    final rows = await fetchList(entity);
    return rows.length;
  }

  List<Map<String, dynamic>> _extractRows(dynamic payload) {
    if (payload is List) {
      return payload.whereType<Map>().map(_asMap).toList(growable: false);
    }

    if (payload is Map<String, dynamic>) {
      final directList = payload['items'] ?? payload['rows'] ?? payload['data'];
      if (directList is List) {
        return directList
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList(growable: false);
      }

      return [Map<String, dynamic>.from(payload)];
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
