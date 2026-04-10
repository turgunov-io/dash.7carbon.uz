import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import 'api_error.dart';

class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  factory ApiClient.create({String? token, bool useDefaultToken = true}) {
    return ApiClient(createDio(token: token, useDefaultToken: useDefaultToken));
  }

  static Dio createDio({String? token, bool useDefaultToken = true}) {
    final headers = <String, String>{'Accept': 'application/json'};
    final runtimeToken = token?.trim() ?? '';
    final defaultToken = useDefaultToken ? AppConfig.adminToken.trim() : '';
    final authToken = runtimeToken.isNotEmpty ? runtimeToken : defaultToken;
    if (authToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }

    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        responseType: ResponseType.json,
        headers: headers,
      ),
    );

    if (!kIsWeb) {
      dio.options.sendTimeout = const Duration(seconds: 15);
    }

    return dio;
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return _request(
      () => _dio.get<dynamic>(path, queryParameters: queryParameters),
    );
  }

  Future<dynamic> post(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _request(
      () => _dio.post<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
      ),
    );
  }

  Future<dynamic> put(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _request(
      () =>
          _dio.put<dynamic>(path, data: data, queryParameters: queryParameters),
    );
  }

  Future<dynamic> patch(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _request(
      () => _dio.patch<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
      ),
    );
  }

  Future<dynamic> delete(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _request(
      () => _dio.delete<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
      ),
    );
  }

  Future<dynamic> _request(Future<Response<dynamic>> Function() call) async {
    try {
      final response = await call();
      return _unwrapResponse(response.data);
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    } catch (error) {
      throw ApiError(
        type: ApiErrorType.unknown,
        message: 'РќРµРѕР¶РёРґР°РЅРЅР°СЏ РѕС€РёР±РєР°: $error',
        details: error,
      );
    }
  }

  dynamic _unwrapResponse(dynamic raw) {
    final normalized = _normalizeDynamic(raw);

    if (normalized is Map<String, dynamic>) {
      final status = normalized['status'];
      if (status == 'success') {
        return normalized['data'];
      }
      if (status == 'error') {
        throw ApiError(
          type: ApiErrorType.badRequest,
          message: _extractEnvelopeMessage(normalized),
          details: normalized,
        );
      }
    }

    return normalized;
  }

  dynamic _normalizeDynamic(dynamic raw) {
    if (raw is String) {
      final body = raw.trim();
      if (body.isEmpty) {
        return null;
      }
      try {
        return jsonDecode(body);
      } catch (_) {
        return body;
      }
    }
    return raw;
  }

  String _extractEnvelopeMessage(Map<String, dynamic> envelope) {
    final message = envelope['message'];
    final baseMessage = message is String && message.trim().isNotEmpty
        ? message.trim()
        : 'Сервер вернул ошибку.';

    final errors = envelope['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final buffer = <String>[];
      for (final entry in errors.entries) {
        final value = entry.value;
        if (value is List) {
          final joined = value.map((item) => item.toString()).join(', ');
          if (joined.isNotEmpty) {
            buffer.add('${entry.key}: $joined');
          }
        } else if (value != null) {
          final text = value.toString().trim();
          if (text.isNotEmpty) {
            buffer.add('${entry.key}: $text');
          }
        }
      }
      if (buffer.isNotEmpty) {
        return '$baseMessage: ${buffer.join(' | ')}';
      }
    }

    return baseMessage;
  }

  void dispose() {
    _dio.close(force: true);
  }
}
