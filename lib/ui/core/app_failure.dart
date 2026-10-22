sealed class AppFailure {
  const AppFailure();
}

class NetworkFailure extends AppFailure {
  const NetworkFailure();
}

class NotFoundFailure extends AppFailure {
  const NotFoundFailure();
}

class ValidationFailure extends AppFailure {
  const ValidationFailure(this.code);
  final String code;
}

class QuotaFailure extends AppFailure {
  const QuotaFailure(this.resetsAt);
  final DateTime resetsAt;
}

class ConsentRequiredFailure extends AppFailure {
  const ConsentRequiredFailure();
}

class UnauthorizedFailure extends AppFailure {
  const UnauthorizedFailure();
}

class ServerFailure extends AppFailure {
  const ServerFailure();
}
