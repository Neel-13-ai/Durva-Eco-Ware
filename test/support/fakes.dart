import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:durvaeco/infrastructure/storage/secure_store.dart';

class InMemorySecureStore implements SecureStore {
  final Map<String, String> _data = {};

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, String value) async => _data[key] = value;

  @override
  Future<void> delete(String key) async => _data.remove(key);
}

typedef RouteHandler = http.Response Function(http.Request request);

class FakeApi {
  final Map<String, RouteHandler> _routes = {};

  void on(String method, String pathSuffix, RouteHandler handler) {
    _routes['$method $pathSuffix'] = handler;
  }

  http.Client client() {
    return MockClient((request) async {
      for (final entry in _routes.entries) {
        final parts = entry.key.split(' ');
        if (request.method == parts[0] && request.url.path.endsWith(parts[1])) {
          return entry.value(request);
        }
      }
      return http.Response('{"error":"NOT_FOUND"}', 404);
    });
  }
}

http.Response jsonResponse(int status, Map<String, dynamic> body) {
  return http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json'},
  );
}
