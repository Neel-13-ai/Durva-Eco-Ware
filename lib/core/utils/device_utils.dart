import 'package:flutter/foundation.dart';
import 'dart:io';

String? _cachedDeviceName;

Future<String> initDeviceName() async {
  if (_cachedDeviceName != null) return _cachedDeviceName!;
  if (kIsWeb) {
    _cachedDeviceName = 'Web Browser';
    return _cachedDeviceName!;
  }
  try {
    _cachedDeviceName ??= Platform.isWindows
        ? 'Windows App'
        : (Platform.isAndroid
            ? 'Android App'
            : (Platform.isIOS ? 'iOS App' : 'Mobile Device'));
  } catch (_) {
    _cachedDeviceName = 'Web Browser';
  }
  return _cachedDeviceName!;
}

String detectDeviceName() {
  if (_cachedDeviceName != null) return _cachedDeviceName!;
  if (kIsWeb) return 'Web Browser';
  try {
    return Platform.isWindows ? 'Windows App' : 'Mobile Device';
  } catch (_) {
    return 'Web Browser';
  }
}

