import 'package:harness_app/ui/core/app_failure.dart';

sealed class Result<T> {
  const Result();
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Error<T> extends Result<T> {
  const Error(this.failure);
  final AppFailure failure;
}
