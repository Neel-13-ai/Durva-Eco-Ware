import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class NativeHttpClient extends http.BaseClient {
  NativeHttpClient({Duration timeout = const Duration(seconds: 30)})
      : _timeout = timeout;

  final Duration _timeout;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    for (int attempt = 0; attempt < 3; attempt++) {
      final nativeClient = HttpClient()
        ..badCertificateCallback = ((cert, host, port) => true)
        ..connectionTimeout = _timeout;

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
        nativeClient.close(force: true);
        if (attempt == 2 || e is! SocketException) {
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
    final url = Uri.parse('$basePath$path');
    const timeout = Duration(seconds: 45);

    switch (method.toUpperCase()) {
      case 'GET':
        return client.get(url, headers: allHeaders).timeout(timeout);
      case 'POST':
        return client.post(url, headers: allHeaders, body: body).timeout(timeout);
      case 'PUT':
        return client.put(url, headers: allHeaders, body: body).timeout(timeout);
      case 'PATCH':
        return client.patch(url, headers: allHeaders, body: body).timeout(timeout);
      case 'DELETE':
        return client.delete(url, headers: allHeaders).timeout(timeout);
      default:
        throw ArgumentError('Unsupported HTTP method: $method');
    }
  }
}
