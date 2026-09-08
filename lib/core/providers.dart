import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../infrastructure/api/api_client.dart';
import 'config/app_config.dart';

final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig.fromEnvironment();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final config = ref.watch(appConfigProvider);
  return ApiClient(basePath: config.apiBaseUrl);
});
