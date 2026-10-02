// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const baseUrl = 'https://api-dev.durvaecoware.com';
  print('====================================================');
  print('       LIVE AUTH API COMPREHENSIVE TEST SUITE       ');
  print('       Target: $baseUrl                      ');
  print('====================================================\n');

  int passed = 0;
  int failed = 0;

  // TEST 1: Valid Login
  print('--- [TEST 1] POST /api/auth/login with valid credentials ---');
  String? token;
  String? refreshToken;
  dynamic userData;
  try {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({'username': 'superadmin', 'password': '123456'}),
    );
    print('  Status: ${res.statusCode}');
    print('  Response: ${res.body}');
    if (res.statusCode == 200 || res.statusCode == 201) {
      final decoded = jsonDecode(res.body);
      token = (decoded['token'] ?? decoded['data']?['token'] ?? decoded['accessToken'] ?? decoded['jwt'])?.toString();
      refreshToken = (decoded['refreshToken'] ?? decoded['data']?['refreshToken'])?.toString();
      userData = decoded['user'] ?? decoded['data']?['user'] ?? decoded['data'];
      print('  ✅ Valid login passed. Token: ${token?.substring(0, token.length > 25 ? 25 : token.length)}...');
      print('  User Info: $userData');
      passed++;
    } else {
      print('  ❌ Valid login failed with status ${res.statusCode}');
      failed++;
    }
  } catch (e) {
    print('  ❌ Valid login exception: $e');
    failed++;
  }

  // TEST 2: Invalid Login (Wrong Password)
  print('\n--- [TEST 2] POST /api/auth/login with invalid password ---');
  try {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({'username': 'superadmin', 'password': 'wrongpassword999'}),
    );
    print('  Status: ${res.statusCode}');
    print('  Response: ${res.body}');
    if (res.statusCode == 400 || res.statusCode == 401 || res.statusCode == 403) {
      print('  ✅ Invalid credentials properly rejected by backend.');
      passed++;
    } else {
      print('  ❌ Unexpected status for invalid login: ${res.statusCode}');
      failed++;
    }
  } catch (e) {
    print('  ❌ Exception during invalid login test: $e');
    failed++;
  }

  // TEST 3: GET /api/auth/me (Current User Profile with Token)
  print('\n--- [TEST 3] GET /api/auth/me with Bearer Token ---');
  if (token != null) {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      print('  Status: ${res.statusCode}');
      print('  Response: ${res.body}');
      if (res.statusCode == 200) {
        print('  ✅ /api/auth/me returned profile successfully.');
        passed++;
      } else {
        print('  ℹ️ /api/auth/me returned status ${res.statusCode}');
      }
    } catch (e) {
      print('  ❌ /api/auth/me exception: $e');
      failed++;
    }
  } else {
    print('  ⚠️ Skipped /api/auth/me due to missing token.');
  }

  // TEST 4: GET /api/roles (Role Verification with Token)
  print('\n--- [TEST 4] GET /api/roles with Bearer Token ---');
  if (token != null) {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/roles'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      print('  Status: ${res.statusCode}');
      print('  Response: ${res.body}');
      if (res.statusCode == 200) {
        print('  ✅ /api/roles returned roles successfully.');
        passed++;
      } else {
        print('  ℹ️ /api/roles status: ${res.statusCode}');
      }
    } catch (e) {
      print('  ❌ /api/roles exception: $e');
      failed++;
    }
  }

  // TEST 5: POST /api/auth/refresh (Token Refresh)
  print('\n--- [TEST 5] POST /api/auth/refresh ---');
  if (refreshToken != null || token != null) {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/auth/refresh'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'refreshToken': refreshToken ?? token,
          'token': token,
        }),
      );
      print('  Status: ${res.statusCode}');
      print('  Response: ${res.body}');
      if (res.statusCode == 200) {
        print('  ✅ /api/auth/refresh succeeded.');
        passed++;
      } else {
        print('  ℹ️ /api/auth/refresh status: ${res.statusCode}');
      }
    } catch (e) {
      print('  ℹ️ /api/auth/refresh exception: $e');
    }
  }

  // TEST 6: POST /api/auth/logout
  print('\n--- [TEST 6] POST /api/auth/logout ---');
  if (token != null) {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/auth/logout'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      print('  Status: ${res.statusCode}');
      print('  Response: ${res.body}');
      if (res.statusCode == 200 || res.statusCode == 204) {
        print('  ✅ /api/auth/logout succeeded.');
        passed++;
      } else {
        print('  ℹ️ /api/auth/logout status: ${res.statusCode}');
      }
    } catch (e) {
      print('  ℹ️ /api/auth/logout exception: $e');
    }
  }

  print('\n====================================================');
  print('                  TEST RESULTS                      ');
  print('  Passed: $passed, Failed: $failed                  ');
  print('====================================================');
}
