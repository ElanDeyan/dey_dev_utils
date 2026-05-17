Validated<T> check<T extends Object?>(
  T value,
  bool Function(T value) predicate, {
  required String error,
}) => predicate(value) ? .valid(value) : .invalid([error]);

final class Invalid<T extends Object?> extends Validated<T> {
  const Invalid(this.errors);

  final List<String> errors;
}

final class Valid<T extends Object?> extends Validated<T> {
  const Valid(this.value);

  final T value;
}

sealed class Validated<T extends Object?> {
  const Validated();

  const factory Validated.invalid(List<String> errors) = Invalid;
  const factory Validated.valid(T value) = Valid;
}

extension ValidatedOps<T> on Validated<T> {
  Validated<T> check(bool Function(T) rule, String error) => switch (this) {
    Invalid() => this,
    Valid(:final value) => rule(value) ? this : .invalid([error]),
  };
}
