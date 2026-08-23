import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:fl_clash/models/v2board.dart';

import 'constant.dart';
import 'preferences.dart';

enum V2boardErrorType {
  invalidLoginResponse,
  missingSubscriptionUrl,
  invalidServerUrl,
  invalidSubscriptionUrl,
  network,
  server,
}

final class V2boardException implements Exception {
  final V2boardErrorType type;
  final String? details;

  const V2boardException(this.type, {this.details});

  String get message => details ?? type.name;

  @override
  String toString() => message;
}

final class V2boardApiClient {
  final Dio _dio;

  V2boardApiClient({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 20),
              headers: {'User-Agent': browserUa},
            ),
          );

  Future<V2boardSession> login({
    required String baseUrl,
    required String email,
    required String password,
  }) async {
    final normalizedBaseUrl = normalizeV2boardBaseUrl(baseUrl);
    try {
      final loginResponse = await _dio.post<Object?>(
        _endpoint(normalizedBaseUrl, 'api/v1/passport/auth/login'),
        data: {'email': email.trim(), 'password': password},
      );
      final authData = _readAuthData(loginResponse.data);
      final subscriptionUrl = await getSubscriptionUrl(
        baseUrl: normalizedBaseUrl,
        authData: authData,
      );
      return V2boardSession(
        baseUrl: normalizedBaseUrl,
        email: email.trim(),
        authData: authData,
        subscriptionUrl: subscriptionUrl,
      );
    } on DioException catch (error) {
      throw _dioException(error);
    }
  }

  Future<String> getSubscriptionUrl({
    required String baseUrl,
    required String authData,
  }) async {
    try {
      final response = await _dio.get<Object?>(
        _endpoint(baseUrl, 'api/v1/user/getSubscribe'),
        options: Options(headers: {'Authorization': authData}),
      );
      return clashSubscriptionUrl(_readSubscriptionUrl(response.data));
    } on DioException catch (error) {
      throw _dioException(error);
    }
  }

  String _endpoint(String baseUrl, String path) {
    return Uri.parse(baseUrl).resolve(path).toString();
  }

  String _readAuthData(Object? responseData) {
    final data = _responseData(responseData);
    if (data is String && data.isNotEmpty) {
      return data;
    }
    if (data is Map) {
      final authData = data['auth_data'];
      if (authData is String && authData.isNotEmpty) {
        return authData;
      }
    }
    throw const V2boardException(V2boardErrorType.invalidLoginResponse);
  }

  String _readSubscriptionUrl(Object? responseData) {
    final data = _responseData(responseData);
    if (data is String && data.isNotEmpty) {
      return data;
    }
    if (data is Map) {
      final clashUrl = data['subscribe_url_clash'];
      if (clashUrl is String && clashUrl.isNotEmpty) {
        return clashUrl;
      }
      final url = data['subscribe_url'];
      if (url is String && url.isNotEmpty) {
        return url;
      }
    }
    throw const V2boardException(V2boardErrorType.missingSubscriptionUrl);
  }

  Object? _responseData(Object? responseData) {
    if (responseData is Map) {
      return responseData['data'];
    }
    return null;
  }

  V2boardException _dioException(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      final message = data['message'];
      if (message is String && message.isNotEmpty) {
        return V2boardException(V2boardErrorType.server, details: message);
      }
    }
    return const V2boardException(V2boardErrorType.network);
  }
}

final class V2boardSessionStore {
  static const _key = 'v2boardSession';

  Future<V2boardSession?> load() async {
    try {
      final value = await preferences.getString(_key);
      if (value == null || value.isEmpty) {
        return null;
      }
      final json = jsonDecode(value);
      if (json is! Map) {
        return null;
      }
      return V2boardSession.fromJson(Map<String, Object?>.from(json));
    } catch (_) {
      return null;
    }
  }

  Future<void> save(V2boardSession session) async {
    await preferences.setString(_key, jsonEncode(session.toJson()));
  }

  Future<void> clear() async {
    await preferences.remove(_key);
  }
}

String normalizeV2boardBaseUrl(String value) {
  final trimmed = value.trim();
  final candidate = trimmed.contains('://') ? trimmed : 'https://$trimmed';
  final uri = Uri.tryParse(candidate);
  if (uri == null ||
      !{'http', 'https'}.contains(uri.scheme) ||
      uri.host.isEmpty) {
    throw const V2boardException(V2boardErrorType.invalidServerUrl);
  }
  final path = uri.path.endsWith('/') ? uri.path : '${uri.path}/';
  return uri.replace(path: path, query: null, fragment: null).toString();
}

String clashSubscriptionUrl(String value) {
  final uri = Uri.tryParse(value.trim());
  if (uri == null ||
      !{'http', 'https'}.contains(uri.scheme) ||
      uri.host.isEmpty) {
    throw const V2boardException(V2boardErrorType.invalidSubscriptionUrl);
  }
  final queryParameters = Map<String, String>.from(uri.queryParameters);
  queryParameters.putIfAbsent('flag', () => 'clash');
  return uri.replace(queryParameters: queryParameters).toString();
}

final v2boardApiClient = V2boardApiClient();
final v2boardSessionStore = V2boardSessionStore();
