import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class NativeHttpClient extends http.BaseClient {
  NativeHttpClient({Duration timeout = const Duration(seconds: 30)})
      : _timeout = timeout;

  final Duration _timeout;
  HttpClient? _client;

  HttpClient _getOrCreateClient() {
    if (_client != null) return _client!;
    final client = HttpClient()..connectionTimeout = _timeout;
    // Restrict certificate validation bypass strictly to debug builds
    if (kDebugMode) {
      client.badCertificateCallback = ((cert, host, port) => true);
    }
    _client = client;
    return client;
  }

  @override
  void close() {
    _client?.close(force: true);
    _client = null;
    super.close();
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final isIdempotent = request.method == 'GET' || request.method == 'HEAD' || request.method == 'OPTIONS';

    for (int attempt = 0; attempt < 3; attempt++) {
      final nativeClient = _getOrCreateClient();

      try {
        final nativeReq = await nativeClient.openUrl(request.method, request.url);
        request.headers.forEach((key, value) {
          nativeReq.headers.set(key, value);
        });

        if (request is http.Request && request.bodyBytes.isNotEmpty) {
          nativeReq.add(request.bodyBytes);
        } else {
          final bytes = await request.finalize().toBytes();
          if (bytes.isNotEmpty) nativeReq.add(bytes);
        }

        final nativeRes = await nativeReq.close();
        final headers = <String, String>{};
        nativeRes.headers.forEach((name, values) {
          headers[name] = values.join(',');
        });

        return http.StreamedResponse(
          nativeRes,
          nativeRes.statusCode,
          contentLength: nativeRes.contentLength >= 0 ? nativeRes.contentLength : null,
          request: request,
          headers: headers,
          isRedirect: nativeRes.isRedirect,
          persistentConnection: nativeRes.persistentConnection,
          reasonPhrase: nativeRes.reasonPhrase,
        );
      } catch (e) {
        _client?.close(force: true);
        _client = null;
        // Only retry socket exceptions for idempotent HTTP methods
        if (!isIdempotent || attempt == 2 || e is! SocketException) {
          rethrow;
        }
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }
    }
    throw StateError('Unreachable');
  }
}

class ApiClient {
  ApiClient({required this.basePath, http.Client? client})
      : client = client ?? _createDefaultClient();

  static http.Client _createDefaultClient() {
    if (kIsWeb) {
      return http.Client();
    }
    try {
      return NativeHttpClient();
    } catch (_) {
      return http.Client();
    }
  }

  final String basePath;
  http.Client client;
  final Map<String, String> _defaultHeaders = {};

  void addDefaultHeader(String key, String value) {
    _defaultHeaders[key] = value;
  }

  Future<http.Response> invokeAPI(
    String path,
    String method,
    Map<String, String> headers,
    Object? body,
  ) async {
    final allHeaders = {..._defaultHeaders, ...headers};
    // Only inject JSON Content-Type when a non-empty payload is being transmitted
    if (body != null &&
        !allHeaders.containsKey('Content-Type') &&
        !allHeaders.containsKey('content-type')) {
      allHeaders['Content-Type'] = 'application/json';
    }
    final upperMethod = method.toUpperCase();
    final url = Uri.parse('$basePath$path');
    const timeout = Duration(seconds: 45);
    final isAuthRoute = path.contains('/auth/');
    final stopwatch = Stopwatch()..start();

    if (kDebugMode) {
      final bodyPreview = body == null
          ? ''
          : (isAuthRoute ? ' | body: <redacted>' : ' | body: ${_truncateForLog(body.toString())}');
      debugPrint('[API] --> $upperMethod $url$bodyPreview');
    }

    try {
      final http.Response response;
      switch (upperMethod) {
        case 'GET':
          response = await client.get(url, headers: allHeaders).timeout(timeout);
        case 'POST':
          response = await client.post(url, headers: allHeaders, body: body).timeout(timeout);
        case 'PUT':
          response = await client.put(url, headers: allHeaders, body: body).timeout(timeout);
        case 'PATCH':
          response = await client.patch(url, headers: allHeaders, body: body).timeout(timeout);
        case 'DELETE':
          response = await client.delete(url, headers: allHeaders).timeout(timeout);
        default:
          throw ArgumentError('Unsupported HTTP method: $method');
      }

      stopwatch.stop();
      if (kDebugMode) {
        final resPreview = isAuthRoute
            ? '<redacted>'
            : _truncateForLog(response.body);
        debugPrint(
          '[API] <-- ${response.statusCode} $upperMethod $url (${stopwatch.elapsedMilliseconds}ms) | $resPreview',
        );
      }
      return response;
    } catch (e) {
      stopwatch.stop();
      if (kDebugMode) {
        debugPrint(
          '[API] <-- ERROR $upperMethod $url (${stopwatch.elapsedMilliseconds}ms): $e',
        );
      }
      rethrow;
    }
  }

  static String _truncateForLog(String value, {int maxLength = 800}) {
    if (value.length <= maxLength) return value;
    return '${value.substring(0, maxLength)}... (${value.length} chars)';
  }
}
