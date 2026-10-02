import 'dart:io';

class ApiItem {
  final int id;
  final String epic;
  final String endpoint;
  final String method;
  final String desc;
  final String claimedStatus;
  final String repoPath;
  final String dto;
  final String uiRoute;

  bool hasEndpointConst = false;
  bool hasRepoMethod = false;
  bool hasUiScreen = false;
  bool hasUiIntegration = false;
  String notes = '';

  ApiItem({
    required this.id,
    required this.epic,
    required this.endpoint,
    required this.method,
    required this.desc,
    required this.claimedStatus,
    required this.repoPath,
    required this.dto,
    required this.uiRoute,
  });
}

void main() {
  final csvFile = File('c:/workspace/durvaeco/DURVA_ECO_WARE_ALL_202_APIS_STATUS.csv');
  final lines = csvFile.readAsLinesSync();
  
  final apiEndpointsFile = File('c:/workspace/durvaeco/lib/core/constants/api_endpoints.dart').readAsStringSync();
  final routerFile = File('c:/workspace/durvaeco/lib/app/router.dart').readAsStringSync();

  // Read all repo files
  final repoFiles = <String, String>{};
  final repoDir = Directory('c:/workspace/durvaeco/lib');
  for (final file in repoDir.listSync(recursive: true)) {
    if (file is File && file.path.endsWith('.dart')) {
      final normalized = file.path.replaceAll('\\', '/');
      repoFiles[normalized] = file.readAsStringSync();
    }
  }

  final items = <ApiItem>[];

  for (int i = 1; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty) continue;
    final p = parseCsvLine(line);
    if (p.length < 9) continue;

    final id = int.tryParse(p[0]) ?? i;
    final item = ApiItem(
      id: id,
      epic: p[1],
      endpoint: p[2],
      method: p[3],
      desc: p[4],
      claimedStatus: p[5],
      repoPath: p[6],
      dto: p[7],
      uiRoute: p[8],
    );

    // 1. Check ApiEndpoints constant
    final baseRoute = item.endpoint.replaceAll(RegExp(r'/\{[a-zA-Z0-9]+\}'), '');
    item.hasEndpointConst = apiEndpointsFile.contains(baseRoute) || apiEndpointsFile.contains(item.endpoint);

    // 2. Check Repository
    final normalizedRepo = 'c:/workspace/durvaeco/' + item.repoPath.replaceAll('\\', '/');
    final repoContent = repoFiles[normalizedRepo] ?? '';
    final userRepoContent = repoFiles['c:/workspace/durvaeco/lib/features/auth/data/user_repository.dart'] ?? '';
    final settingsRepoContent = repoFiles['c:/workspace/durvaeco/lib/features/auth/data/settings_repository.dart'] ?? '';

    if (item.endpoint == '/api/auth/login') {
      item.hasRepoMethod = repoContent.contains('login(');
    } else if (item.endpoint.startsWith('/api/users')) {
      if (item.endpoint == '/api/users/change-password') {
        item.hasRepoMethod = userRepoContent.contains('changePassword');
      } else if (item.method == 'GET' && !item.endpoint.contains('{id}')) {
        item.hasRepoMethod = userRepoContent.contains('getUsers');
      } else if (item.method == 'GET' && item.endpoint.contains('{id}')) {
        item.hasRepoMethod = userRepoContent.contains('getUserById');
      } else if (item.method == 'POST') {
        item.hasRepoMethod = userRepoContent.contains('createUser');
      } else if (item.method == 'PUT') {
        item.hasRepoMethod = userRepoContent.contains('updateUser');
      } else if (item.method == 'DELETE') {
        item.hasRepoMethod = userRepoContent.contains('deleteUser');
      }
    } else if (item.endpoint.startsWith('/api/app-settings')) {
      if (item.method == 'GET' && !item.endpoint.contains('{id}')) item.hasRepoMethod = settingsRepoContent.contains('getAppSettings');
      else if (item.method == 'GET' && item.endpoint.contains('{id}')) item.hasRepoMethod = settingsRepoContent.contains('getAppSettingById');
      else if (item.method == 'POST') item.hasRepoMethod = settingsRepoContent.contains('createAppSetting');
      else if (item.method == 'PUT') item.hasRepoMethod = settingsRepoContent.contains('updateAppSetting');
      else if (item.method == 'DELETE') item.hasRepoMethod = settingsRepoContent.contains('deleteAppSetting');
    } else if (item.endpoint.startsWith('/api/company-settings')) {
      if (item.method == 'GET' && !item.endpoint.contains('{id}')) item.hasRepoMethod = settingsRepoContent.contains('getCompanySettings');
      else if (item.method == 'GET' && item.endpoint.contains('{id}')) item.hasRepoMethod = settingsRepoContent.contains('getCompanySettingById');
      else if (item.method == 'POST') item.hasRepoMethod = settingsRepoContent.contains('createCompanySetting');
      else if (item.method == 'PUT') item.hasRepoMethod = settingsRepoContent.contains('updateCompanySetting');
      else if (item.method == 'DELETE') item.hasRepoMethod = settingsRepoContent.contains('deleteCompanySetting');
    } else if (item.endpoint.startsWith('/api/roles')) {
      if (item.method == 'GET' && !item.endpoint.contains('{id}')) item.hasRepoMethod = settingsRepoContent.contains('getRoles');
      else if (item.method == 'GET' && item.endpoint.contains('{id}')) item.hasRepoMethod = settingsRepoContent.contains('getRoleById');
      else if (item.method == 'POST') item.hasRepoMethod = settingsRepoContent.contains('createRole');
      else if (item.method == 'PUT') item.hasRepoMethod = settingsRepoContent.contains('updateRole');
      else if (item.method == 'DELETE') item.hasRepoMethod = settingsRepoContent.contains('deleteRole');
    } else if (repoContent.isNotEmpty) {
      // Check repository methods
      final isCollectionGet = item.method == 'GET' && !item.endpoint.contains('{id}');
      final isItemGet = item.method == 'GET' && item.endpoint.contains('{id}');
      final isPost = item.method == 'POST';
      final isPut = item.method == 'PUT';
      final isDelete = item.method == 'DELETE';

      if (isCollectionGet) {
        item.hasRepoMethod = repoContent.contains('getAll') || repoContent.contains('get(') || repoContent.contains('fetch') || repoContent.contains('list');
      } else if (isItemGet) {
        item.hasRepoMethod = repoContent.contains('getById') || repoContent.contains('fetchById') || repoContent.contains('get(') || repoContent.contains('getStockBalance(') || repoContent.contains('getReasonById') || repoContent.contains('getEntryById') || repoContent.contains('getCustomerPaymentById') || repoContent.contains('getNotificationById') || repoContent.contains('getStockTransactionById') || repoContent.contains('getAuditLogById');
      } else if (isPost) {
        item.hasRepoMethod = repoContent.contains('create') || repoContent.contains('save') || repoContent.contains('submit') || repoContent.contains('issue') || repoContent.contains('insert') || repoContent.contains('add');
      } else if (isPut) {
        item.hasRepoMethod = repoContent.contains('update') || repoContent.contains('edit') || repoContent.contains('save') || repoContent.contains('mark') || repoContent.contains('adjust');
      } else if (isDelete) {
        item.hasRepoMethod = repoContent.contains('delete') || repoContent.contains('cancel') || repoContent.contains('remove');
      }
    }

    // 3. Check UI Screen & Router
    if (item.endpoint.startsWith('/api/users')) {
      item.hasUiScreen = routerFile.contains("'/users'");
      item.hasUiIntegration = item.hasUiScreen && item.hasRepoMethod;
    } else if (item.endpoint.startsWith('/api/app-settings') || item.endpoint.startsWith('/api/company-settings') || item.endpoint.startsWith('/api/roles')) {
      item.hasUiScreen = routerFile.contains("'/settings'");
      item.hasUiIntegration = item.hasUiScreen && item.hasRepoMethod;
    } else {
      final routeClean = item.uiRoute.replaceAll(RegExp(r'^[a-zA-Z0-9_\s]+\('), '').replaceAll(')', '').trim();
      final routePath = routeClean.split(' ').first;
      item.hasUiScreen = routerFile.contains(routePath) || routerFile.contains(item.uiRoute.split(' ').first);
      item.hasUiIntegration = item.hasUiScreen && item.hasRepoMethod;
    }

    items.add(item);
  }

  print('================================================================');
  print('          DURVA ECO WARE - ALL 202 APIS STATUS AUDIT            ');
  print('================================================================');
  print('Total APIs: ${items.length}\n');

  final fullyIntegrated = items.where((x) => x.hasRepoMethod && x.hasUiIntegration).toList();
  final repoIntegratedMissingUI = items.where((x) => x.hasRepoMethod && !x.hasUiIntegration).toList();
  final missingRepoAndUI = items.where((x) => !x.hasRepoMethod).toList();

  print('1. Fully Integrated (Repo + Active UI Screen): ${fullyIntegrated.length}');
  print('2. Repository Ready but Missing/Incomplete UI Screen: ${repoIntegratedMissingUI.length}');
  print('3. Missing Repository Methods & Missing UI: ${missingRepoAndUI.length}');

  print('\n----------------------------------------------------------------');
  print('DETAILED BREAKDOWN BY MODULE / EPIC');
  print('----------------------------------------------------------------');

  final epics = <String, List<ApiItem>>{};
  for (final item in items) {
    epics.putIfAbsent(item.epic, () => []).add(item);
  }

  for (final entry in epics.entries) {
    final epicName = entry.key;
    final epicItems = entry.value;
    final integrated = epicItems.where((x) => x.hasRepoMethod && x.hasUiIntegration).length;
    final pending = epicItems.length - integrated;
    print('\n📦 $epicName (Total: ${epicItems.length} APIs | Done: $integrated | Remaining: $pending)');
    for (final it in epicItems) {
      final statusIcon = (it.hasRepoMethod && it.hasUiIntegration) ? '✅' : (it.hasRepoMethod ? '⚠️ (Repo only)' : '❌ (Missing Repo & UI)');
      if (!it.hasRepoMethod || !it.hasUiIntegration) {
        print('   $statusIcon ID #${it.id.toString().padLeft(3, ' ')}: ${it.method.padRight(6)} ${it.endpoint.padRight(35)} -> ${it.desc}');
      }
    }
  }
}

List<String> parseCsvLine(String line) {
  final result = <String>[];
  final sb = StringBuffer();
  bool inQuotes = false;
  for (int i = 0; i < line.length; i++) {
    final c = line[i];
    if (c == '"') {
      inQuotes = !inQuotes;
    } else if (c == ',' && !inQuotes) {
      result.add(sb.toString().trim());
      sb.clear();
    } else {
      sb.write(c);
    }
  }
  result.add(sb.toString().trim());
  return result;
}
