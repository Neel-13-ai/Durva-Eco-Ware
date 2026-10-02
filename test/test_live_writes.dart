// ignore_for_file: avoid_print, prefer_const_declarations

import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const baseUrl = 'https://api-dev.durvaecoware.com';
  print('=== Running Durva Eco Ware Live Write Tests ===\n');

  // 1. Authenticate
  final loginRes = await http.post(
    Uri.parse('$baseUrl/api/auth/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'username': 'superadmin', 'password': '123456'}),
  );

  if (loginRes.statusCode != 200) {
    print('❌ Auth failed with status ${loginRes.statusCode}');
    return;
  }
  final dynamic authData = jsonDecode(loginRes.body);
  final String? token = authData is Map<String, dynamic>
      ? (authData['token'] ?? authData['data']?['token'])?.toString()
      : null;

  if (token == null) {
    print('❌ Could not extract auth token');
    return;
  }

  final headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };
  print('✅ Authenticated successfully as superadmin.\n');

  final now = DateTime.now().millisecondsSinceEpoch;

  // 1. Category
  final cat = await http.post(
    Uri.parse('$baseUrl/api/categories'),
    headers: headers,
    body: jsonEncode({
      'categoryName': 'Paper Products ${now % 10000}',
      'categoryType': 'FINISHED_GOOD',
    }),
  );
  print('1. Category POST (${cat.statusCode}): ${cat.body}');

  // 2. Unit
  final unit = await http.post(
    Uri.parse('$baseUrl/api/units'),
    headers: headers,
    body: jsonEncode({
      'unitName': 'Packet ${now % 10000}',
      'shortName': 'PKT',
    }),
  );
  print('2. Unit POST (${unit.statusCode}): ${unit.body}');

  // 3. Warehouse
  final wh = await http.post(
    Uri.parse('$baseUrl/api/warehouses'),
    headers: headers,
    body: jsonEncode({
      'warehouseCode': 'W${now % 10000}',
      'warehouseName': 'Storage Area ${now % 10000}',
      'isDefault': false,
    }),
  );
  print('3. Warehouse POST (${wh.statusCode}): ${wh.body}');

  // 4. Supplier
  final sup = await http.post(
    Uri.parse('$baseUrl/api/suppliers'),
    headers: headers,
    body: jsonEncode({
      'supplierCode': 'SUP-${now % 10000}',
      'supplierName': 'Eco Raw Supplier',
      'phone': '9876543210',
      'email': 'sup@example.com',
    }),
  );
  print('4. Supplier POST (${sup.statusCode}): ${sup.body}');

  // 5. Customer
  final cust = await http.post(
    Uri.parse('$baseUrl/api/customers'),
    headers: headers,
    body: jsonEncode({
      'customerCode': 'CUST-${now % 10000}',
      'customerName': 'Green Mart',
      'phone': '9876543211',
      'email': 'green@example.com',
    }),
  );
  print('5. Customer POST (${cust.statusCode}): ${cust.body}');

  // 6. Transporter
  final trans = await http.post(
    Uri.parse('$baseUrl/api/transporters'),
    headers: headers,
    body: jsonEncode({
      'transporterCode': 'TR-${now % 10000}',
      'transporterName': 'Express Logistics',
      'phone': '9876543212',
    }),
  );
  print('6. Transporter POST (${trans.statusCode}): ${trans.body}');

  // 7. Vehicle
  final veh = await http.post(
    Uri.parse('$baseUrl/api/vehicles'),
    headers: headers,
    body: jsonEncode({
      'vehicleNumber': 'MH12AB${now % 10000}',
      'vehicleType': 'TRUCK',
    }),
  );
  print('7. Vehicle POST (${veh.statusCode}): ${veh.body}');

  // 8. Expense Category
  final expCat = await http.post(
    Uri.parse('$baseUrl/api/expense-categories'),
    headers: headers,
    body: jsonEncode({
      'categoryName': 'Factory Maintenance ${now % 10000}',
    }),
  );
  print('8. Expense Category POST (${expCat.statusCode}): ${expCat.body}');

  // 9. BOM Header
  final bom = await http.post(
    Uri.parse('$baseUrl/api/b-o-m-headers'),
    headers: headers,
    body: jsonEncode({
      'bomCode': 'BOM-${now % 10000}',
      'finishedProductId': 8,
      'batchSize': 100.0,
      'createdBy': 1,
    }),
  );
  print('9. BOM Header POST (${bom.statusCode}): ${bom.body}');
  int? bomId;
  if (bom.statusCode >= 200 && bom.statusCode < 300) {
    final dynamic bomData = jsonDecode(bom.body);
    if (bomData is Map<String, dynamic>) {
      bomId = bomData['id'] as int?;
    }
  }

  // 10. Production Order
  if (bomId != null) {
    final po = await http.post(
      Uri.parse('$baseUrl/api/production-orders'),
      headers: headers,
      body: jsonEncode({
        'productionNumber': 'PO-${now % 10000}',
        'bomId': bomId,
        'finishedProductId': 8,
        'warehouseId': 1,
        'productionDate': DateTime.now().toIso8601String(),
        'shiftName': 'General Shift',
        'plannedQty': 100.0,
        'status': 'DRAFT',
        'createdBy': 1,
      }),
    );
    print('10. Production Order POST (${po.statusCode}): ${po.body}');
  }

  // 11. Expense
  final exp = await http.post(
    Uri.parse('$baseUrl/api/expenses'),
    headers: headers,
    body: jsonEncode({
      'expenseNumber': 'EXP-${now % 10000}',
      'expenseCategoryId': 9,
      'amount': 250.0,
      'expenseDate': DateTime.now().toIso8601String(),
      'paymentMethodId': 1,
      'createdBy': 1,
    }),
  );
  print('11. Expense POST (${exp.statusCode}): ${exp.body}');

  print('\n=== All Live Write Tests Completed ===');
}
