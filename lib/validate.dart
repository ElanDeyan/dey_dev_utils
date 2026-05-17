import 'package:collection/collection.dart';
import 'package:dev_utils/result.dart';
import 'package:meta/meta.dart';

Validated<T> check<T extends Object?>(
  T value,
  bool Function(T value) predicate, {
  required String error,
}) => predicate(value) ? .valid(value) : .invalid({error});

@immutable
final class Invalid<T extends Object?> extends Validated<T> {
  const Invalid(this.errors);

  final Set<String> errors;

  @override
  int get hashCode => errors.hashCode;

  @override
  bool operator ==(covariant Validated<T> other) {
    switch (other) {
      case Valid():
        return false;
      case Invalid(errors: final otherErrors):
        const collectionEquality = DeepCollectionEquality(
          DefaultEquality<String>(),
        );
        return collectionEquality.equals(errors, otherErrors);
    }
  }
}

@immutable
final class Valid<T extends Object?> extends Validated<T> {
  const Valid(this.value);

  final T value;

  @override
  int get hashCode => value.hashCode;

  @override
  bool operator ==(covariant Validated<T> other) {
    switch (other) {
      case Valid(value: final otherValue):
        return value == otherValue;
      case Invalid():
        return false;
    }
  }
}

@immutable
sealed class Validated<T extends Object?> {
  const Validated();

  const factory Validated.invalid(Set<String> errors) = Invalid;
  const factory Validated.valid(T value) = Valid;

  bool get isValid => this is Valid<T>;

  Result<T, Set<String>> asResult() => switch (this) {
    Invalid<T>(:final errors) => .err(errors),
    Valid<T>(:final value) => .ok(value),
  };

  T? unwrapOrNull() => switch (this) {
    Invalid<T>() => null,
    Valid<T>(:final value) => value,
  };
}

extension ValidatedOps<T> on Validated<T> {
  Validated<T> check(bool Function(T) rule, String error) => switch (this) {
    Invalid(:final errors) => .invalid({...errors, error}),
    Valid(:final value) => rule(value) ? this : .invalid({error}),
  };
}
