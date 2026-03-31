import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../session/session_user.dart';

const String _apiBaseUrlDefine =
    String.fromEnvironment('SKILLBITE_API_BASE_URL');
const String _apiFallbackUrlsDefine =
    String.fromEnvironment('SKILLBITE_API_FALLBACK_URLS');

List<String> buildApiBaseUrlCandidates() {
  final candidates = <String>[];
  final deferredLoopbackCandidates = <String>[];
  final shouldDeferAndroidLoopback = !kIsWeb && Platform.isAndroid;

  void addCandidate(String rawUrl) {
    final normalized = normalizeApiBaseUrl(rawUrl);
    if (normalized.isEmpty) {
      return;
    }
    if (candidates.contains(normalized) ||
        deferredLoopbackCandidates.contains(normalized)) {
      return;
    }
    if (shouldDeferAndroidLoopback && _isLoopbackApiBaseUrl(normalized)) {
      deferredLoopbackCandidates.add(normalized);
      return;
    }
    candidates.add(normalized);
  }

  addCandidate(_apiBaseUrlDefine);
  for (final rawUrl in _apiFallbackUrlsDefine.split(',')) {
    addCandidate(rawUrl);
  }

  if (kIsWeb) {
    addCandidate('http://127.0.0.1:8000/api/mobile/v1');
    addCandidate('http://localhost:8000/api/mobile/v1');
  } else if (Platform.isAndroid) {
    addCandidate('http://10.0.2.2:8000/api/mobile/v1');
    addCandidate('http://10.0.3.2:8000/api/mobile/v1');
    addCandidate('http://127.0.0.1:8000/api/mobile/v1');
  } else {
    addCandidate('http://127.0.0.1:8000/api/mobile/v1');
    addCandidate('http://localhost:8000/api/mobile/v1');
  }

  for (final candidate in deferredLoopbackCandidates) {
    if (!candidates.contains(candidate)) {
      candidates.add(candidate);
    }
  }

  return candidates;
}

bool _isLoopbackApiBaseUrl(String rawUrl) {
  final uri = Uri.tryParse(rawUrl);
  final host = uri?.host.toLowerCase() ?? '';
  return host == '127.0.0.1' || host == 'localhost' || host == '::1';
}

String normalizeApiBaseUrl(String rawUrl) {
  final trimmed = rawUrl.trim();
  if (trimmed.isEmpty) {
    return '';
  }
  final withoutTrailingSlash = trimmed.endsWith('/')
      ? trimmed.substring(0, trimmed.length - 1)
      : trimmed;
  return withoutTrailingSlash.endsWith('/api/mobile/v1')
      ? withoutTrailingSlash
      : '$withoutTrailingSlash/api/mobile/v1';
}

class MobileApiClient {
  MobileApiClient({
    required String baseUrl,
    List<String> fallbackBaseUrls = const [],
  })  : _baseUrlCandidates = [
          baseUrl,
          ...fallbackBaseUrls.where((candidate) => candidate != baseUrl),
        ],
        _activeBaseUrl = baseUrl;

  final List<String> _baseUrlCandidates;
  String _activeBaseUrl;
  String? token;
  static const Duration _requestTimeout = Duration(seconds: 8);

  String get baseUrl => _activeBaseUrl;

  Future<SessionUser> login(String username, String password) async {
    final payload = await _postWithFallback(
      '/auth/login/',
      {
        'username': username,
        'password': password,
        'device_name': 'flutter-dev',
      },
      includeAuth: false,
    );
    token = payload['token'] as String?;
    return SessionUser.fromJson(payload['user'] as Map<String, dynamic>);
  }

  Future<SessionUser> register({
    required String username,
    required String email,
    required String fullName,
    required String fullNameArabic,
    required String password,
    required String companyName,
    required String phoneNumber,
    required String idNumber,
    required String region,
    required String secBusinessLine,
  }) async {
    final payload = await _postWithFallback(
      '/auth/register/',
      {
        'username': username,
        'email': email,
        'full_name_en': fullName,
        'full_name_ar': fullNameArabic,
        'password': password,
        'company_name': companyName,
        'phone_number': phoneNumber,
        'id_number': idNumber,
        'region': region,
        'sec_business_line': secBusinessLine,
      },
      includeAuth: false,
    );
    token = payload['token'] as String?;
    return SessionUser.fromJson(payload['user'] as Map<String, dynamic>);
  }

  Future<void> forgotPassword({
    required String username,
    required String email,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _postWithFallback(
      '/auth/forgot-password/',
      {
        'username': username,
        'email': email,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      },
      includeAuth: false,
    );
  }

  Future<Map<String, dynamic>> get(String path) async {
    return _sendWithFallback(
      (candidate) async {
        final response = await http
            .get(_uriFor(candidate, path), headers: _headers())
            .timeout(_requestTimeout);
        return _parseResponse(response);
      },
      failureMessage: 'Request failed.',
    );
  }

  Future<Map<String, dynamic>> post(
    String path,
    Object body, {
    bool includeAuth = true,
  }) async {
    return _sendWithFallback(
      (candidate) async {
        final response = await http
            .post(
              _uriFor(candidate, path),
              headers: _headers(includeAuth: includeAuth),
              body: jsonEncode(body),
            )
            .timeout(_requestTimeout);
        return _parseResponse(response);
      },
      failureMessage: 'Request failed.',
    );
  }

  Future<Map<String, dynamic>> _postWithFallback(
    String path,
    Object body, {
    bool includeAuth = true,
  }) async {
    return _sendWithFallback(
      (candidate) async {
        final response = await http
            .post(
              _uriFor(candidate, path),
              headers: _headers(includeAuth: includeAuth),
              body: jsonEncode(body),
            )
            .timeout(_requestTimeout);
        return _parseResponse(response);
      },
      failureMessage: 'Login failed.',
    );
  }

  Iterable<String> _orderedBaseUrlCandidates() sync* {
    yield _activeBaseUrl;
    for (final candidate in _baseUrlCandidates) {
      if (candidate != _activeBaseUrl) {
        yield candidate;
      }
    }
  }

  Future<Map<String, dynamic>> _sendWithFallback(
    Future<Map<String, dynamic>> Function(String baseUrl) request, {
    required String failureMessage,
  }) async {
    Object? lastError;
    for (final candidate in _orderedBaseUrlCandidates()) {
      try {
        final payload = await request(candidate);
        _activeBaseUrl = candidate;
        return payload;
      } catch (error) {
        lastError = error;
      }
    }
    throw lastError ?? Exception(failureMessage);
  }

  Uri _uriFor(String base, String path) => Uri.parse('$base$path');

  Map<String, String> _headers({bool includeAuth = true}) {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (includeAuth && token != null) 'Authorization': 'Bearer $token',
    };
  }

  String resolveUrl(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    final parsed = Uri.tryParse(trimmed);
    if (parsed != null && parsed.hasScheme) {
      return parsed.toString();
    }
    return Uri.parse(baseUrl).resolve(trimmed).toString();
  }

  Map<String, dynamic> _parseResponse(http.Response response) {
    Map<String, dynamic> payload;
    final rawBody =
        utf8.decode(response.bodyBytes, allowMalformed: true).trim();
    final normalizedBody =
        rawBody.startsWith('\uFEFF') ? rawBody.substring(1) : rawBody;
    try {
      payload = jsonDecode(normalizedBody) as Map<String, dynamic>;
    } catch (_) {
      if (normalizedBody.isEmpty) {
        throw Exception('Empty server response (${response.statusCode}).');
      }
      final preview = normalizedBody.length > 180
          ? '${normalizedBody.substring(0, 180)}...'
          : normalizedBody;
      throw Exception(
        'Unexpected server response (${response.statusCode}): $preview',
      );
    }
    if (payload['ok'] == true) {
      return payload;
    }
    if (response.statusCode >= 400 || payload['ok'] != true) {
      throw Exception(_extractError(payload));
    }
    return payload;
  }

  String _extractError(Map<String, dynamic> payload) {
    final error = payload['error'];
    if (error is Map<String, dynamic>) {
      return (error['message'] ?? 'Request failed').toString();
    }
    return 'Request failed';
  }
}
