import 'dart:convert';

sealed class Failure {
  const Failure(this._rawMessage);
  final String _rawMessage;

  /// User-facing message that guarantees no raw socket exceptions,
  /// low-level OS errors, or stack traces leak to the UI.
  String get message => sanitizeMessage(_rawMessage);

  /// Preserves the raw error message for debug logging and telemetry.
  String get rawMessage => _rawMessage;

  @override
  String toString() => message;

  static bool _isNetworkIssue(String msg) {
    final lower = msg.toLowerCase();
    return lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('network is unreachable') ||
        lower.contains('connection refused') ||
        lower.contains('connection reset') ||
        lower.contains('clientexception') ||
        lower.contains('handshakeexception') ||
        lower.contains('network error') ||
        lower.contains('no address associated with hostname');
  }

  static bool _isTimeoutIssue(String msg) {
    final lower = msg.toLowerCase();
    return lower.contains('timeoutexception') ||
        lower.contains('timed out') ||
        lower.contains('deadline exceeded');
  }

  static String _extractJsonMessage(String msg) {
    final trimmed = msg.trim();
    if (!trimmed.startsWith('{')) return msg;
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) {
        final extracted = decoded['message'] ?? decoded['Message'] ?? decoded['error'] ?? decoded['title'];
        if (extracted is String && extracted.trim().isNotEmpty) {
          return extracted.trim();
        }
      }
    } catch (_) {}
    return msg;
  }

  /// Sanitizes any raw exception string so that low-level OS details, SQL errors,
  /// or raw JSON payloads never leak to the end user.
  static String sanitizeMessage(String msg) {
    if (msg.isEmpty) return 'An unexpected error occurred. Please try again.';
    if (_isNetworkIssue(msg)) {
      return 'Unable to connect to the server. Please check your internet connection.';
    }
    if (_isTimeoutIssue(msg)) {
      return 'Connection timed out. Please check your network and try again.';
    }

    final clean = _extractJsonMessage(msg);
    final lower = clean.toLowerCase();
    if (lower.contains('violation of unique key constraint') ||
        lower.contains('cannot insert duplicate key')) {
      final dupMatch = RegExp(r'duplicate key value is \(([^)]+)\)', caseSensitive: false)
          .firstMatch(clean);
      final dupValue = dupMatch?.group(1)?.trim();
      if (lower.contains('dbo.units') || lower.contains('uq__units')) {
        return dupValue != null && dupValue.isNotEmpty
            ? 'Unit "$dupValue" already exists.'
            : 'A unit with this name already exists.';
      }
      return dupValue != null && dupValue.isNotEmpty
          ? '"$dupValue" already exists. Please use a different value.'
          : 'This record already exists. Please use a different value.';
    }

    return clean;
  }

  /// Converts any caught exception into a properly typed and sanitized [Failure].
  factory Failure.fromException(Object error) {
    if (error is Failure) return error;
    final msg = error.toString();
    if (_isNetworkIssue(msg)) {
      return NetworkFailure(msg);
    }
    if (_isTimeoutIssue(msg)) {
      return NetworkFailure(msg);
    }
    if (error is FormatException) {
      return const ValidationFailure('Unable to process server response.');
    }
    return UnknownFailure(msg);
  }
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Unable to connect to the server. Please check your internet connection.']);
}

class ServerFailure extends Failure {
  const ServerFailure(this.statusCode, [super.message = 'Server error']);
  final int statusCode;

  @override
  String get message {
    if (_rawMessage.trim().isEmpty) {
      return switch (statusCode) {
        401 => 'Your session has expired or is unauthorized. Please sign in again.',
        403 => 'You do not have permission to perform this action.',
        404 => 'The requested resource was not found.',
        >= 500 => 'Server error ($statusCode). Please try again later.',
        _ => 'Request failed ($statusCode). Please try again.',
      };
    }
    return super.message;
  }
}

class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Validation error']);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Unauthorized request']);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Resource not found']);
}

class ConflictFailure extends Failure {
  const ConflictFailure([super.message = 'Resource conflict']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'An unexpected error occurred']);
}
