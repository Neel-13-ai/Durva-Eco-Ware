String detectDeviceIanaTimezone() {
  try {
    return DateTime.now().timeZoneName;
  } catch (_) {
    return 'UTC';
  }
}
