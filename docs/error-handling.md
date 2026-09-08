# Error Handling & Failure Modeling

## 1. Sealed Result Primitive (`lib/core/result/result.dart`)

To avoid uncaught exceptions leaking into UI widgets, all repository methods return a sealed `Result<T>`:

```dart
sealed class Result<T> {
  const Result();

  R when<R>({
    required R Function(T value) success,
    required R Function(Failure failure) failure,
  }) {
    final self = this;
    if (self is Success<T>) return success(self.value);
    return failure((self as Err<T>).failure);
  }
}

class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;
}
```

---

## 2. Failure Domain Hierarchy (`lib/core/error/failure.dart`)

```dart
sealed class Failure {
  const Failure(this.message);
  final String message;
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network connection failed']);
}

class ServerFailure extends Failure {
  const ServerFailure(this.statusCode, [super.message = 'Server error']);
  final int statusCode;
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'An unexpected error occurred']);
}
```

---

## 3. User-Facing Error Message Sanitization

```dart
static String cleanErrorMessage(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return 'Action failed. Please try again.';
  }
  final trimmed = raw.trim();
  if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map && decoded.containsKey('message')) {
        final msg = decoded['message'];
        if (msg is String && msg.isNotEmpty) return msg;
      }
    } catch (_) {}
  }
  return raw;
}
```
