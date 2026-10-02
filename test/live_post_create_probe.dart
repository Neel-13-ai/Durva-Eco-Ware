// ignore_for_file: avoid_print, prefer_const_declarations

import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const baseUrl = 'https://api-dev.durvaecoware.com';
  print('=== Durva Eco Ware: Live POST Create Probe ===');
  print('Target: $baseUrl\n');

  // Step 1: Authenticate
  print('[1/2] Authenticating as superadmin...');
  String? token;
  try {
    final loginRes = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': 'superadmin', 'password': '123456'}),
    );
    print('  POST /api/auth/login -> HTTP ${loginRes.statusCode}');
    if (loginRes.statusCode == 200) {
      final dynamic data = jsonDecode(loginRes.body);
      if (data is Map<String, dynamic>) {
        token = (data['token'] ?? data['data']?['token'])?.toString();
      }
      print('  Token acquired: ${token != null && token.length > 30 ? token.substring(0, 30) : token}...');
    } else {
      print('  FAILED: ${loginRes.body}');
      return;
    }
  } catch (e) {
    print('  Auth exception: $e');
    return;
  }

  if (token == null) {
    print('  Token acquisition failed.');
    return;
  }

  final headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  final now = DateTime.now().millisecondsSinceEpoch;

  // Step 2: Probe every POST create endpoint
  print('\n[2/2] Probing POST create endpoints with valid server schemas...\n');

  final results = <PostResult>[];

  // --- Master Data ---
  results.add(await probe(
    'POST /api/categories',
    headers,
    jsonEncode({
      'categoryName': 'Probe Cat $now',
      'categoryType': 'FINISHED_GOOD',
      'description': 'Probe test category',
    }),
  ));

  results.add(await probe(
    'POST /api/units',
    headers,
    jsonEncode({
      'unitName': 'Probe Unit $now',
      'shortName': 'PU',
    }),
  ));

  results.add(await probe(
    'POST /api/warehouses',
    headers,
    jsonEncode({
      'warehouseCode': 'W${now % 10000}',
      'warehouseName': 'Probe WH $now',
      'isDefault': false,
    }),
  ));

  results.add(await probe(
    'POST /api/document-sequences',
    headers,
    jsonEncode({
      'documentType': 'TestProbe$now',
      'prefix': 'TP-',
      'nextNumber': 1,
      'padding': 4,
    }),
  ));

  results.add(await probe(
    'POST /api/products',
    headers,
    jsonEncode({
      'productName': 'Probe Product $now',
      'sku': 'SKU-$now',
      'categoryId': 9,
      'unitId': 9,
      'productType': 'FINISHED_GOOD',
      'purchasePrice': 100.0,
      'sellingPrice': 150.0,
      'minimumStock': 10.0,
    }),
  ));

  // --- Partners ---
  results.add(await probe(
    'POST /api/suppliers',
    headers,
    jsonEncode({
      'supplierCode': 'SUP-$now',
      'supplierName': 'Probe Supplier $now',
      'phone': '9876543210',
      'email': 'sup$now@test.com',
    }),
  ));

  results.add(await probe(
    'POST /api/customers',
    headers,
    jsonEncode({
      'customerCode': 'CUST-$now',
      'customerName': 'Probe Customer $now',
      'phone': '9876543211',
      'email': 'cust$now@test.com',
    }),
  ));

  results.add(await probe(
    'POST /api/transporters',
    headers,
    jsonEncode({
      'transporterCode': 'TR-$now',
      'transporterName': 'Probe Transporter $now',
      'phone': '9876543212',
    }),
  ));

  results.add(await probe(
    'POST /api/vehicles',
    headers,
    jsonEncode({
      'vehicleNumber': 'MH12PR${now % 10000}',
      'vehicleType': 'TRUCK',
    }),
  ));

  // --- BOM ---
  results.add(await probe(
    'POST /api/b-o-m-headers',
    headers,
    jsonEncode({
      'bomCode': 'BOM-$now',
      'finishedProductId': 8,
      'batchSize': 100.0,
      'createdBy': 1,
    }),
  ));

  // --- Production ---
  results.add(await probe(
    'POST /api/production-orders',
    headers,
    jsonEncode({
      'productionNumber': 'PO-$now',
      'bomId': 2,
      'finishedProductId': 8,
      'warehouseId': 1,
      'productionDate': DateTime.now().toIso8601String(),
      'shiftName': 'General Shift',
      'plannedQty': 100.0,
      'status': 'DRAFT',
      'createdBy': 1,
    }),
  ));

  results.add(await probe(
    'POST /api/production-stages',
    headers,
    jsonEncode({
      'stageName': 'Probe Stage $now',
      'sequenceNo': 7,
    }),
  ));

  // --- Expenses ---
  results.add(await probe(
    'POST /api/expense-categories',
    headers,
    jsonEncode({
      'categoryName': 'Probe Expense Cat $now',
    }),
  ));

  results.add(await probe(
    'POST /api/expenses',
    headers,
    jsonEncode({
      'expenseNumber': 'EXP-$now',
      'expenseCategoryId': 9,
      'amount': 250.0,
      'expenseDate': DateTime.now().toIso8601String(),
      'paymentMethodId': 1,
      'createdBy': 1,
    }),
  ));

  // Summary
  int passed = 0;
  int failed = 0;
  int errored = 0;

  for (final r in results) {
    if (r.statusCode == 200 || r.statusCode == 201 || r.statusCode == 204) {
      passed++;
      print('  ✅ ${r.endpoint} -> HTTP ${r.statusCode}');
    } else if (r.statusCode > 0) {
      failed++;
      print('  ⚠️ ${r.endpoint} -> HTTP ${r.statusCode} | ${r.bodyPreview}');
    } else {
      errored++;
      print('  ❌ ${r.endpoint} -> ${r.error}');
    }
  }

  print('');
  print(''.padRight(60).replaceAll(' ', '═'));
  print('RESULTS: $passed passed | $failed rejected | $errored errors');
  print('Out of ${results.length} POST create endpoints tested.');
  print(''.padRight(60).replaceAll(' ', '═'));
}

class PostResult {
  final String endpoint;
  final int statusCode;
  final String bodyPreview;
  final String error;

  PostResult(this.endpoint, this.statusCode, this.bodyPreview, this.error);
}

Future<PostResult> probe(String endpoint, Map<String, String> headers, String body) async {
  final url = endpoint.split(' ').skip(1).join(' ');
  final fullUrl = 'https://api-dev.durvaecoware.com$url';
  try {
    final res = await http.post(
      Uri.parse(fullUrl),
      headers: headers,
      body: body,
    );
    final preview = res.body.length > 120
        ? '${res.body.substring(0, 120)}...'
        : res.body;
    return PostResult(endpoint, res.statusCode, preview, '');
  } catch (e) {
    return PostResult(endpoint, 0, '', e.toString());
  }
}
