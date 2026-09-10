import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final res = await http.get(Uri.parse('https://api-dev.durvaecoware.com/swagger/v1/swagger.json'));
  final schema = jsonDecode(res.body);
  final paths = schema['paths'] as Map<String, dynamic>;
  print('Total Swagger Paths on Live Server: ${paths.length}');
  final sortedPaths = paths.keys.toList()..sort();
  for (final p in sortedPaths) {
    final methods = (paths[p] as Map).keys.map((m) => m.toString().toUpperCase()).join(', ');
    print('  - $p ($methods)');
  }
}
