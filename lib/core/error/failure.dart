sealed class Failure {
  const Failure(this.message);
  final String message;
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network error. Please check your connection.']);
}

class ServerFailure extends Failure {
  const ServerFailure(this.statusCode, [super.message = 'Server error']);
  final int statusCode;
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
