import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient({required this.basePath, http.Client? client})
      : client = client ?? http.Client();

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
    switch (method.toUpperCase()) {
      case 'GET':
        return client.get(url, headers: allHeaders);
      case 'POST':
        return client.post(url, headers: allHeaders, body: body);
      case 'PUT':
        return client.put(url, headers: allHeaders, body: body);
      case 'DELETE':
        return client.delete(url, headers: allHeaders);
      default:
        throw ArgumentError('Unsupported HTTP method: $method');
    }
  }
}
