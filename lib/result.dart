import 'package:dev_utils/option.dart';
import 'package:meta/meta.dart';

typedef CatchAllResult<T extends Object?> = Result<T, Object>;
typedef FutureResult<T extends Object?, E extends Object> =
    Future<Result<T, E>>;

@immutable
final class Err<T extends Object?, E extends Object> extends Result<T, E> {
  Err(this.error, [StackTrace? stackTrace])
    : stackTrace = stackTrace ?? .current;

  final E error;
  final StackTrace stackTrace;

  @override
  int get hashCode => Object.hashAll([error]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is Err<T, E>) return error == other.error;

    return false;
  }
}

@immutable
final class Ok<T extends Object?, E extends Object> extends Result<T, E> {
  const Ok(this.value);
  final T value;

  @override
  int get hashCode => Object.hashAll([value]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is Ok<T, E>) return value == other.value;

    return false;
  }
}

@immutable
sealed class Result<T extends Object?, E extends Object> {
  const Result();

  factory Result.err(E error, [StackTrace? stackTrace]) = Err;

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

  bool get isErr => this is Err<T, E>;

  bool get isOk => this is Ok<T, E>;

  T? get ok => switch (this) {
    Ok(:final value) => value,
    Err() => null,
  };

  Result<T, E> operator &(Result<T, E> other) => and(other);

  Result<T, E> and(Result<T, E> other) {
    if (this is Err<T, E>) return this;
    if (other is Err<T, E>) return other;

    return other;
  }

  Result<U, E> andThen<U extends Object?>(
    Result<U, E> Function(T value) otherBlock,
  ) => switch (this) {
    Ok(:final value) => otherBlock(value),
    Err(:final error, :final stackTrace) => .err(error, stackTrace),
  };

  T expect(String message) => switch (this) {
    Ok(:final value) => value,
    Err(:final stackTrace) => Error.throwWithStackTrace(
      Exception(message),
      stackTrace,
    ),
  };

  E expectErr(String message) => switch (this) {
    Ok() => throw Exception(message),
    Err(:final error) => error,
  };

  bool isErrAnd(bool Function(E error) predicate) {
    if (this case Err(:final error) when predicate(error)) return true;

    return false;
  }

  bool isOkAnd(bool Function(T value) predicate) {
    if (this case Ok(:final value) when predicate(value)) return true;

    return false;
  }

  Result<Y, E> map<Y extends Object?>(Y Function(T value) block) =>
      switch (this) {
        Err<T, E>(:final error, :final stackTrace) => .err(error, stackTrace),
        Ok<T, E>(:final value) => .ok(block(value)),
      };

  Result<T, F> mapErr<F extends Object>(F Function(E error) block) =>
      switch (this) {
        Err<T, E>(:final error) => .err(block(error)),
        Ok<T, E>(:final value) => .ok(value),
      };

  Result<T, E> or(Result<T, E> other) {
    if (this is Ok<T, E>) return this;
    if (other is Err<T, E>) return other;

    return other;
  }

  Result<T, F> orElse<F extends Object>(
    Result<T, F> Function(E error, StackTrace? st) otherBlock,
  ) => switch (this) {
    Err(:final error, :final stackTrace) => otherBlock(error, stackTrace),
    Ok(:final value) => .ok(value),
  };

  T unwrap() => switch (this) {
    Ok(:final value) => value,
    Err(:final error, :final stackTrace) => Error.throwWithStackTrace(
      error,
      stackTrace,
    ),
  };

  T unwrapOr(T defaultValue) => switch (this) {
    Ok(:final value) => value,
    Err() => defaultValue,
  };

  T unwrapOrElse(T Function(E error) block) => switch (this) {
    Ok(:final value) => value,
    Err(:final error) => block(error),
  };

  T? unwrapOrNull() => switch (this) {
    Ok(:final value) => value,
    Err() => null,
  };

  Option<T> unwrapOrOption() => switch (this) {
    Ok(:final value) => .some(value),
    Err() => const .none(),
  };

  Result<T, E> operator |(Result<T, E> other) => or(other);

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

extension InspectResultExtension<T extends Object?, E extends Object>
    on Result<T, E> {
  Result<T, E> inspectErr(void Function(E value) block) {
    if (this case Err(:final error)) {
      block(error);
    }
    return this;
  }

  Result<T, E> inspectOk(void Function(T value) block) {
    if (this case Ok(:final value)) {
      block(value);
    }
    return this;
  }
}
