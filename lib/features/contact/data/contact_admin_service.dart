import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../auth/data/auth_token_storage.dart';
import '../models/contact_model.dart';

class ContactAdminServiceException implements Exception {
  const ContactAdminServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ContactAdminService {
  ContactAdminService({
    http.Client? client,
    AuthTokenStorage? tokenStorage,
    String? baseUrl,
    String? fallbackToken,
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null,
       _tokenStorage = tokenStorage ?? const AuthTokenStorage(),
       _baseUrl = baseUrl ?? AppConfig.apiBaseUrl,
       _fallbackToken = fallbackToken ?? AppConfig.adminToken;

  static const String _endpoint = '/admin/contact';

  final http.Client _client;
  final bool _ownsClient;
  final AuthTokenStorage _tokenStorage;
  final String _baseUrl;
  final String _fallbackToken;

  Future<List<ContactModel>> fetchContacts() async {
    final payload = await _request(method: 'GET', path: _endpoint);
    return _extractList(
      payload,
    ).map(ContactModel.fromJson).toList(growable: false);
  }

  Future<ContactModel> fetchContact(int id) async {
    final payload = await _request(method: 'GET', path: '$_endpoint/$id');
    return ContactModel.fromJson(_extractMap(payload));
  }

  Future<void> createContact(ContactModel contact) async {
    await _request(
      method: 'POST',
      path: _endpoint,
      body: contact.toRequestBody(),
    );
  }

  Future<void> updateContact(int id, ContactModel contact) async {
    await _request(
      method: 'PATCH',
      path: '$_endpoint/$id',
      body: contact.toRequestBody(),
    );
  }

  Future<void> deleteContact(int id) async {
    await _request(method: 'DELETE', path: '$_endpoint/$id');
  }

  void close() {
    if (_ownsClient) {
      _client.close();
    }
  }

  Future<dynamic> _request({
    required String method,
    required String path,
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse(_baseUrl).resolve(path);
    final headers = await _headers();

    try {
      late final http.Response response;
      switch (method) {
        case 'GET':
          response = await _client.get(uri, headers: headers);
          break;
        case 'POST':
          response = await _client.post(
            uri,
            headers: headers,
            body: jsonEncode(body ?? const <String, dynamic>{}),
          );
          break;
        case 'PATCH':
          response = await _client.patch(
            uri,
            headers: headers,
            body: jsonEncode(body ?? const <String, dynamic>{}),
          );
          break;
        case 'DELETE':
          response = await _client.delete(uri, headers: headers);
          break;
        default:
          throw ContactAdminServiceException(
            'Unsupported HTTP method: $method',
          );
      }

      return _unwrapResponse(response);
    } on ContactAdminServiceException {
      rethrow;
    } catch (error) {
      throw ContactAdminServiceException('Request failed: $error');
    }
  }

  Future<Map<String, String>> _headers() async {
    final storedToken = (await _tokenStorage.readToken())?.trim() ?? '';
    final fallbackToken = _fallbackToken.trim();
    final token = storedToken.isNotEmpty ? storedToken : fallbackToken;

    if (token.isEmpty) {
      throw const ContactAdminServiceException(
        'Admin token is missing. Log in again or provide ADMIN_TOKEN.',
      );
    }

    return <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  dynamic _unwrapResponse(http.Response response) {
    final payload = _decodeBody(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (payload is Map<String, dynamic>) {
        final status = payload['status']?.toString().trim().toLowerCase();
        if (status == 'success') {
          return payload['data'];
        }
        if (payload.containsKey('data') && status == null) {
          return payload['data'];
        }
      }
      return payload;
    }

    throw ContactAdminServiceException(
      _extractErrorMessage(statusCode: response.statusCode, payload: payload),
    );
  }

  dynamic _decodeBody(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    try {
      return jsonDecode(trimmed);
    } catch (_) {
      return trimmed;
    }
  }

  String _extractErrorMessage({
    required int statusCode,
    required dynamic payload,
  }) {
    if (payload is Map<String, dynamic>) {
      final message = payload['message']?.toString().trim();
      final error = payload['error']?.toString().trim();
      final errors = payload['errors'];
      final details = <String>[];

      if (message != null && message.isNotEmpty) {
        details.add(message);
      }
      if (error != null && error.isNotEmpty && error != message) {
        details.add(error);
      }
      if (errors is Map) {
        for (final entry in errors.entries) {
          final value = entry.value;
          if (value is List) {
            final joined = value
                .map((item) => item.toString().trim())
                .where((item) => item.isNotEmpty)
                .join(', ');
            if (joined.isNotEmpty) {
              details.add('${entry.key}: $joined');
            }
          } else {
            final text = value?.toString().trim() ?? '';
            if (text.isNotEmpty) {
              details.add('${entry.key}: $text');
            }
          }
        }
      }

      if (details.isNotEmpty) {
        return details.join(' | ');
      }
    }

    if (payload is String && payload.isNotEmpty) {
      return payload;
    }

    return 'Request failed with status code $statusCode.';
  }

  List<Map<String, dynamic>> _extractList(dynamic payload) {
    if (payload is List) {
      return payload
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);
    }

    if (payload is Map<String, dynamic>) {
      final nested = payload['items'] ?? payload['rows'] ?? payload['data'];
      if (nested != null) {
        return _extractList(nested);
      }
      return <Map<String, dynamic>>[payload];
    }

    if (payload is Map) {
      return <Map<String, dynamic>>[Map<String, dynamic>.from(payload)];
    }

    return const <Map<String, dynamic>>[];
  }

  Map<String, dynamic> _extractMap(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      final nested = payload['item'] ?? payload['row'];
      if (nested != null) {
        return _extractMap(nested);
      }
      return payload;
    }

    if (payload is Map) {
      return Map<String, dynamic>.from(payload);
    }

    throw const ContactAdminServiceException(
      'Unexpected response format returned by /admin/contact.',
    );
  }
}
