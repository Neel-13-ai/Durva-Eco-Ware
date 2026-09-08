import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

String? _cachedDeviceName;

Future<String> initDeviceName() async {
  if (_cachedDeviceName != null) return _cachedDeviceName!;
  try {
    final plugin = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final android = await plugin.androidInfo;
      _cachedDeviceName = '${android.manufacturer} ${android.model}'.trim();
    } else if (Platform.isIOS) {
      final ios = await plugin.iosInfo;
      _cachedDeviceName = ios.name.isNotEmpty ? ios.name : ios.model;
    }
  } catch (_) {}
  _cachedDeviceName ??= 'Mobile Device';
  return _cachedDeviceName!;
}

String detectDeviceName() => _cachedDeviceName ?? 'Mobile Device';
