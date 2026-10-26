/// Case-insensitive, type-safe JSON property reader.
/// Seamlessly bridges ASP.NET PascalCase, camelCase, and alternate field aliases.
class JsonReader {
  JsonReader(this.raw) {
    if (raw != null) {
      for (final entry in raw!.entries) {
        _normalized[entry.key.toLowerCase()] = entry.value;
      }
    }
  }

  final Map<String, dynamic>? raw;
  final Map<String, dynamic> _normalized = {};

  dynamic _getRaw(String key, [List<String>? aliases]) {
    if (raw == null) return null;
    
    // Direct lookup first
    if (raw!.containsKey(key)) return raw![key];
    
    // Lowercase lookup
    final lKey = key.toLowerCase();
    if (_normalized.containsKey(lKey)) return _normalized[lKey];

    // Aliases lookup
    if (aliases != null) {
      for (final a in aliases) {
        if (raw!.containsKey(a)) return raw![a];
        final lA = a.toLowerCase();
        if (_normalized.containsKey(lA)) return _normalized[lA];
      }
    }
    return null;
  }

  int getInt(String key, {List<String>? aliases, int defaultValue = 0}) {
    final val = _getRaw(key, aliases);
    if (val == null) return defaultValue;
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val) ?? (double.tryParse(val)?.toInt() ?? defaultValue);
    return defaultValue;
  }

  int? getOptionalInt(String key, {List<String>? aliases}) {
    final val = _getRaw(key, aliases);
    if (val == null) return null;
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val) ?? double.tryParse(val)?.toInt();
    return null;
  }

  double getDouble(String key, {List<String>? aliases, double defaultValue = 0.0}) {
    final val = _getRaw(key, aliases);
    if (val == null) return defaultValue;
    if (val is double) return val;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? defaultValue;
    return defaultValue;
  }

  double? getOptionalDouble(String key, {List<String>? aliases}) {
    final val = _getRaw(key, aliases);
    if (val == null) return null;
    if (val is double) return val;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val);
    return null;
  }

  String getString(String key, {List<String>? aliases, String defaultValue = ''}) {
    final val = _getRaw(key, aliases);
    if (val == null) return defaultValue;
    return val.toString();
  }

  String? getOptionalString(String key, {List<String>? aliases}) {
    final val = _getRaw(key, aliases);
    if (val == null) return null;
    final str = val.toString().trim();
    return str.isEmpty ? null : str;
  }

  bool getBool(String key, {List<String>? aliases, bool defaultValue = false}) {
    final val = _getRaw(key, aliases);
    if (val == null) return defaultValue;
    if (val is bool) return val;
    if (val is num) return val != 0;
    if (val is String) {
      final s = val.toLowerCase().trim();
      return s == 'true' || s == '1' || s == 'yes';
    }
    return defaultValue;
  }

  DateTime? getDateTime(String key, {List<String>? aliases}) {
    final val = _getRaw(key, aliases);
    if (val == null) return null;
    if (val is DateTime) return val;
    if (val is String) return DateTime.tryParse(val);
    return null;
  }

  List<dynamic> getList(String key, {List<String>? aliases}) {
    final val = _getRaw(key, aliases);
    if (val is List) return val;
    return const [];
  }

  Map<String, dynamic>? getMap(String key, {List<String>? aliases}) {
    final val = _getRaw(key, aliases);
    if (val is Map<String, dynamic>) return val;
    if (val is Map) return Map<String, dynamic>.from(val);
    return null;
  }

  /// Safely extracts a List from API responses that might be a direct List,
  /// or wrapped in 'data', 'value', 'items', or 'results'.
  static List<dynamic> extractList(dynamic decoded) {
    if (decoded == null) return const [];
    if (decoded is List) return decoded;
    if (decoded is Map) {
      if (decoded['data'] is List) return decoded['data'] as List<dynamic>;
      if (decoded['value'] is List) return decoded['value'] as List<dynamic>;
      if (decoded['items'] is List) return decoded['items'] as List<dynamic>;
      if (decoded['results'] is List) return decoded['results'] as List<dynamic>;
    }
    return const [];
  }

  /// Safely extracts a single item Map from API responses that might be wrapped in 'data' or 'value'.
  static Map<String, dynamic> extractObject(dynamic decoded) {
    if (decoded == null) return const {};
    if (decoded is Map<String, dynamic>) {
      if (decoded['data'] is Map<String, dynamic>) return decoded['data'] as Map<String, dynamic>;
      if (decoded['value'] is Map<String, dynamic>) return decoded['value'] as Map<String, dynamic>;
      return decoded;
    }
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return const {};
  }
}

