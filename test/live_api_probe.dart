import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final baseUrl = 'https://api-dev.durvaecoware.com';
  print('=== Probing Live API: $baseUrl ===');

  // 1. Authenticate
  print('\n[1/3] Testing Authentication...');
  String? token;
  try {
    final loginRes = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': 'superadmin', 'password': '123456'}),
    );
    print('  POST /api/auth/login -> HTTP ${loginRes.statusCode}');
    if (loginRes.statusCode == 200) {
      final data = jsonDecode(loginRes.body);
      token = data['token'] ?? data['data']?['token'];
      print('  Token acquired successfully: ${token?.substring(0, 20)}...');
    }
  } catch (e) {
    print('  Auth failed: $e');
  }

  // 2. Fetch Swagger schema to count all registered endpoints
  print('\n[2/3] Inspecting Swagger Schema...');
  Map<String, dynamic>? swaggerPaths;
  try {
    final swRes = await http.get(Uri.parse('$baseUrl/swagger/v1/swagger.json'));
    print('  GET /swagger/v1/swagger.json -> HTTP ${swRes.statusCode}');
    if (swRes.statusCode == 200) {
      final schema = jsonDecode(swRes.body);
      swaggerPaths = schema['paths'] as Map<String, dynamic>?;
      int totalEndpoints = 0;
      swaggerPaths?.forEach((path, methods) {
        totalEndpoints += (methods as Map).length;
      });
      print('  Total Swagger Registered Endpoints: $totalEndpoints across ${swaggerPaths?.length} paths');
    }
  } catch (e) {
    print('  Swagger check failed: $e');
  }

  // 3. Probe all Live GET Endpoints with Auth Token
  print('\n[3/3] Probing Live Endpoints with Superadmin Bearer Token...');
  final endpointsToTest = [
    '/api/auth/me',
    '/api/categories',
    '/api/units',
    '/api/products',
    '/api/warehouses',
    '/api/documentsequences',
    '/api/suppliers',
    '/api/customers',
    '/api/transporters',
    '/api/vehicles',
    '/api/paymentmethods',
    '/api/purchases',
    '/api/goodsreceipts',
    '/api/vendorpayments',
    '/api/inventory/balances',
    '/api/inventory/low-stock',
    '/api/inventory/transactions',
    '/api/inventory/movements',
    '/api/inventory/audit-logs',
    '/api/boms',
    '/api/productionorders',
    '/api/qualitychecks',
    '/api/waste',
    '/api/wastereasons',
    '/api/sales',
    '/api/customerpayments',
    '/api/deliveries',
    '/api/deliveries/pending',
    '/api/expenses',
    '/api/expensecategories',
    '/api/notifications',
    '/api/notifications/unread-count',
    '/api/reports/stock-summary',
    '/api/reports/production-summary',
    '/api/reports/sales-summary',
  ];

  final headers = <String, String>{
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  int successCount = 0;
  int totalTested = 0;

  for (final ep in endpointsToTest) {
    totalTested++;
    try {
      final res = await http.get(Uri.parse('$baseUrl$ep'), headers: headers);
      final isOk = res.statusCode == 200 || res.statusCode == 204;
      if (isOk) successCount++;
      final preview = res.body.length > 60 ? '${res.body.substring(0, 60)}...' : res.body;
      print('  ${isOk ? "✅" : "⚠️"} GET $ep -> HTTP ${res.statusCode} (Length: ${res.body.length}b)');
    } catch (e) {
      print('  ❌ GET $ep -> Error: $e');
    }
  }

  print('\n=============================================');
  print('Live Probe Complete: $successCount / $totalTested endpoints returned HTTP 200 OK');
  print('=============================================');
}
