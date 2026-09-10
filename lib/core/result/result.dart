import '../error/failure.dart';

sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isErr => this is Err<T>;

  T? get dataOrNull => this is Success<T> ? (this as Success<T>).value : null;
  Failure? get failureOrNull => this is Err<T> ? (this as Err<T>).failure : null;

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
