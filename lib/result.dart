import 'package:dev_utils/option.dart';
import 'package:meta/meta.dart';

@immutable
final class Err<T extends Object?, E extends Object> extends Result<T, E> {
  final E error;
  final StackTrace? _stackTrace;

  const Err(this.error, [this._stackTrace]);

  @override
  int get hashCode => error.hashCode;

  StackTrace get stackTrace => _stackTrace ?? .current;

  @override
  bool operator ==(covariant Result<T, E> other) {
    if (other is Err<T, E>) return error == other.error;

    return false;
  }
}

@immutable
final class Ok<T extends Object?, E extends Object> extends Result<T, E> {
  final T value;

  const Ok(this.value);

  @override
  int get hashCode => value.hashCode;

  @override
  bool operator ==(covariant Result<T, E> other) {
    if (other is Ok<T, E>) return value == other.value;

    return false;
  }
}

@immutable
sealed class Result<T extends Object?, E extends Object> {
  const Result();

  const factory Result.err(E error, [StackTrace? stackTrace]) = Err;
  factory Result.guardSync(T Function() block) {
    try {
      final value = block();
      return .ok(value);
    } on E catch (e, st) {
      return .err(e, st);
    }
  }
  const factory Result.ok(T value) = Ok;

  E? get err => switch (this) {
    Ok() => null,
    Err(:final error) => error,
  };

  T? get ok => switch (this) {
    Ok(:final value) => value,
    Err() => null,
  };

  Result<T, E> operator &(covariant Result<T, E> other) {
    if (this is Err<T, E>) return this;
    if (this is Ok<T, E> && other is Err<T, E>) return other;

    assert(this is Ok<T, E> && other is Ok<T, E>);

    return other;
  }

  Result<T, E> andThen(Result<T, E> Function() otherBlock) {
    if (this is Err<T, E>) return this;

    final otherResult = otherBlock();
    if (this is Ok<T, E> && otherResult is Err<T, E>) return otherResult;

    assert(this is Ok<T, E> && otherResult is Ok<T, E>);
    return otherResult;
  }

  T expect(E error) => switch (this) {
    Ok(:final value) => value,
    Err() => throw error,
  };

  // TODO (elan): implement operators with callbacks parameters

  Result<T, E> orThen(Result<T, E> Function() otherBlock) {
    if (this is Ok<T, E>) return this;

    final otherResult = otherBlock();
    if (this is Err<T, E> && otherResult is Err<T, E>) return otherResult;

    assert(this is Err<T, E> && otherResult is Ok<T, E>);
    return otherResult;
  }

  T unwrap() => switch (this) {
    Ok(:final value) => value,
    Err(:final error) => throw error,
  };

  T unwrapOr(T value) => switch (this) {
    Ok(:final value) => value,
    Err() => value,
  };

  T unwrapOrElse(T Function() block) => switch (this) {
    Ok(:final value) => value,
    Err() => block(),
  };

  T? unwrapOrNull() => switch (this) {
    Ok(:final value) => value,
    Err() => null,
  };

  Option<T> unwrapOrOption() => switch (this) {
    Ok(:final value) => .some(value),
    Err() => .none(),
  };

  Result<T, E> operator |(covariant Result<T, E> other) {
    if (this is Ok<T, E>) return this;
    if (this is Err<T, E> && other is Err<T, E>) return other;

    assert(this is Err<T, E> && other is Ok<T, E>);

    return other;
  }

  static Future<Result<T, E>> guardAsync<T extends Object?, E extends Object>(
    Future<T> Function() asyncBlock,
  ) async {
    try {
      final value = await asyncBlock();
      return .ok(value);
    } on E catch (e, st) {
      return .err(e, st);
    }
  }
}

extension ComparisonResultExtension<
  T extends Comparable<T>,
  E extends Comparable<E>
>
    on Result<T, E> {}
