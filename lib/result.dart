import 'package:dev_utils/option.dart';
import 'package:meta/meta.dart';

/// A result type that captures either a successful value or any error.
///
/// This is useful for functions that may fail with any type of error.
/// The error type is `Object`, making it a catch-all for any exception.
/// Commonly used with try-catch blocks where the error type is unknown.
///
/// Example:
/// ```dart
/// CatchAllResult<String> parseJson(String json) {
///   try {
///     return Ok(jsonDecode(json));
///   } catch (e) {
///     return Err(e);
///   }
/// }
/// ```
typedef CatchAllResult<T extends Object?> = Result<T, Object>;

/// A future result that will eventually resolve to either a value or an error.
///
/// Represents an asynchronous operation that can either succeed with a value
/// of type [T] or fail with a specific error type [E].
///
/// Useful for async operations that need explicit error handling.
typedef FutureResult<T extends Object?, E extends Object> =
    Future<Result<T, E>>;

/// Represents a failed result containing an error and its stack trace.
///
/// This is used when an operation fails. The [stackTrace] is automatically
/// captured from the current context if not provided.
///
/// Example:
/// ```dart
/// Result<int, String> divide(int a, int b) {
///   if (b == 0) return Err('Division by zero');
///   return Ok(a ~/ b);
/// }
/// ```
@immutable
final class Err<T extends Object?, E extends Object> extends Result<T, E> {
  /// Creates an error result with the given [error] and optional [stackTrace].
  ///
  /// If [stackTrace] is not provided, the current stack trace is automatically
  /// captured using [StackTrace.current].
  Err(this.error, [StackTrace? stackTrace])
    : stackTrace = stackTrace ?? .current;

  /// The error value that describes why the operation failed.
  final E error;

  /// The stack trace at the point where this error was created.
  final StackTrace stackTrace;

  @override
  int get hashCode => Object.hashAll([error]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is Err<T, E>) return error == other.error;

    return false;
  }

  @override
  String toString() => 'Err<$T, $E>(error: $error)';
}

/// Represents a successful result containing a value.
///
/// This is used when an operation succeeds and produces a meaningful value.
///
/// Example:
/// ```dart
/// Result<int, String> parseNumber(String input) {
///   final value = int.tryParse(input);
///   if (value != null) return Ok(value);
///   return Err('Invalid number');
/// }
/// ```
@immutable
final class Ok<T extends Object?, E extends Object> extends Result<T, E> {
  /// Creates a successful result with the given [value].
  const Ok(this.value);

  /// The successful value produced by the operation.
  final T value;

  @override
  int get hashCode => Object.hashAll([value]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is Ok<T, E>) return value == other.value;

    return false;
  }

  @override
  String toString() => 'Ok<$T, $E>(value: $value)';
}

/// A type-safe way to handle operations that may fail.
///
/// Instead of throwing exceptions or returning null, [Result] represents
/// either a successful value ([Ok]) or a failure ([Err]). This makes error
/// handling explicit and composable.
///
/// Use [Result] when:
/// - You need explicit error handling
/// - You want to chain operations that might fail
/// - You need to distinguish between different error types
///
/// Example:
/// ```dart
/// Result<int, String> safeDivide(int a, int b) {
///   if (b == 0) return Result.err('Cannot divide by zero');
///   return Result.ok(a ~/ b);
/// }
///
/// // Usage:
/// final result = safeDivide(10, 2);
/// final value = result.unwrapOr(0); // Get value or default
/// ```
@immutable
sealed class Result<T extends Object?, E extends Object> {
  const Result();

  /// Creates a failed result with the given [error].
  factory Result.err(E error, [StackTrace? stackTrace]) = Err;

  /// Executes a synchronous function and wraps the result.
  ///
  /// Attempts to execute [block] and wraps any exception in [Err].
  /// Returns [Ok] with the value if the function succeeds.
  /// Returns [Err] with the caught exception and stack trace if an exception
  /// is thrown.
  ///
  /// Note: will catch only [E] or subtypes of [E].
  ///
  /// Example:
  /// ```dart
  /// final result = Result<int, FormatException>.guardSync(
  ///   () => int.parse('42'),
  /// );
  /// ```
  factory Result.guardSync(T Function() block) {
    try {
      final value = block();
      return .ok(value);
    } on E catch (e, st) {
      return .err(e, st);
    }
  }

  /// Creates a successful result with the given [value].
  const factory Result.ok(T value) = Ok;

  /// Returns the error value if this is an [Err], otherwise null.
  E? get err => switch (this) {
    Ok() => null,
    Err(:final error) => error,
  };

  /// Returns true if this result is a failure ([Err]).
  bool get isErr => this is Err<T, E>;

  /// Returns true if this result is a success ([Ok]).
  bool get isOk => this is Ok<T, E>;

  /// Returns the success value if this is an [Ok], otherwise null.
  /// **Warning:** If [T] is nullable, this method cannot distinguish between
  /// `Ok(null)` and `Err(...)` — both return null. Use [toOption] instead
  /// for nullable [T].
  T? get ok => switch (this) {
    Ok(:final value) => value,
    Err() => null,
  };

  /// Combines two results using the [and] operator (&).
  ///
  /// Returns this result if it's an error, otherwise returns [other].
  Result<T, E> operator &(Result<T, E> other) => and(other);

  /// Chains operations: returns this result if it's an error, otherwise
  /// [other].
  ///
  /// This is useful for performing sequential operations where the second
  /// depends on the first succeeding. If this result is [Err], it's returned
  /// unchanged (short-circuit). If this is [Ok], the [other] result is returned.
  ///
  /// Example:
  /// ```dart
  /// Result<int, String> a = Ok(5);
  /// Result<int, String> b = Ok(10);
  /// final result = a.and(b); // Returns b (Ok(10))
  /// ```
  Result<T, E> and(Result<T, E> other) {
    if (this is Err<T, E>) return this;

    return other;
  }

  /// Transforms the success value into a new result, or propagates the error.
  ///
  /// If this is [Ok], applies [otherBlock] to the value and returns its result.
  /// If this is [Err], the error is propagated unchanged (short-circuit behavior).
  ///
  /// This is the monadic bind operation, useful for chaining operations
  /// that might fail while maintaining error information.
  ///
  /// Example:
  /// ```dart
  /// Result<int, String> stringToInt = Ok('42');
  /// final result = stringToInt.andThen(
  ///   (value) => value > 0 ? Ok(value) : Err('Must be positive')
  /// );
  /// ```
  Result<U, E> andThen<U extends Object?>(
    Result<U, E> Function(T value) otherBlock,
  ) => switch (this) {
    Ok(:final value) => otherBlock(value),
    Err(:final error, :final stackTrace) => .err(error, stackTrace),
  };

  /// Returns a new instance of this.
  Result<T, E> clone() => switch (this) {
    Err<T, E>(:final error, :final stackTrace) => .err(error, stackTrace),
    Ok<T, E>(:final value) => .ok(value),
  };

  /// Unwraps the success value, or throws an exception with [message].
  ///
  /// Use this when you're certain the result should be [Ok], but want to
  /// provide a custom error message if it's not.
  ///
  /// Example:
  /// ```dart
  /// final value = result.expect('Operation should have succeeded');
  /// ```
  T expect(String message) => switch (this) {
    Ok(:final value) => value,
    Err(:final stackTrace) => Error.throwWithStackTrace(
      Exception(message),
      stackTrace,
    ),
  };

  /// Unwraps the error value, or throws an exception with [message].
  ///
  /// Use this when you're certain the result should be [Err], but want to
  /// provide a custom error message if it's not.
  ///
  /// Example:
  /// ```dart
  /// final error = result.expectErr('Operation should have failed');
  /// ```
  E expectErr(String message) => switch (this) {
    Ok() => throw Exception(message),
    Err(:final error) => error,
  };

  /// Checks if this is an error and the error matches the [predicate].
  ///
  /// Returns true only if this is [Err] and [predicate] returns true for the error.
  ///
  /// Example:
  /// ```dart
  /// if (result.isErrAnd((e) => e.code == 404)) {
  ///   print('Not found');
  /// }
  /// ```
  bool isErrAnd(bool Function(E error) predicate) => switch (this) {
    Err(:final error) => predicate(error),
    Ok() => false,
  };

  /// Checks if this is a success and the value matches the [predicate].
  ///
  /// Returns true only if this is [Ok] and [predicate] returns true for the value.
  ///
  /// Example:
  /// ```dart
  /// if (result.isOkAnd((value) => value > 0)) {
  ///   print('Positive value');
  /// }
  /// ```
  bool isOkAnd(bool Function(T value) predicate) => switch (this) {
    Ok(:final value) => predicate(value),
    Err() => false,
  };

  /// Transforms the success value using [block], leaving errors unchanged.
  ///
  /// If this is [Ok], applies [block] to the value and wraps the result.
  /// If this is [Err], returns the same error.
  ///
  /// Example:
  /// ```dart
  /// Result<int, String> result = Ok(5);
  /// final doubled = result.map((value) => value * 2); // Ok(10)
  /// ```
  Result<Y, E> map<Y extends Object?>(Y Function(T value) block) =>
      switch (this) {
        Err<T, E>(:final error, :final stackTrace) => .err(error, stackTrace),
        Ok<T, E>(:final value) => .ok(block(value)),
      };

  /// Transforms the error value using [block], leaving success values unchanged.
  ///
  /// If this is [Err], applies [block] to the error and wraps the result.
  /// If this is [Ok], returns the same success value.
  ///
  /// Example:
  /// ```dart
  /// Result<int, String> result = Err('parse error');
  /// final mapped = result.mapErr((e) => 'Error: $e');
  /// ```
  Result<T, F> mapErr<F extends Object>(F Function(E error) block) =>
      switch (this) {
        Err<T, E>(:final error, :final stackTrace) => .err(
          block(error),
          stackTrace,
        ),
        Ok<T, E>(:final value) => .ok(value),
      };

  /// Returns this result if it's a success, otherwise [other].
  ///
  /// Use this to provide a fallback result when the first result fails.
  ///
  /// Example:
  /// ```dart
  /// Result<int, String> a = Err('failed');
  /// Result<int, String> b = Ok(10);
  /// final result = a | b; // Returns b (Ok(10))
  /// ```
  Result<T, E> or(Result<T, E> other) {
    if (this is Ok<T, E>) return this;

    return other;
  }

  /// Returns this success value, or computes a recovery result from the error.
  ///
  /// If this is [Ok], returns it unchanged.
  /// If this is [Err], applies [otherBlock] to the error and stack trace,
  /// returning the computed result.
  ///
  /// Example:
  /// ```dart
  /// final result = failedOp.orElse(
  ///   (error, st) => Ok(defaultValue),
  /// );
  /// ```
  Result<T, F> orElse<F extends Object>(
    Result<T, F> Function(E error, StackTrace st) otherBlock,
  ) => switch (this) {
    Err(:final error, :final stackTrace) => otherBlock(error, stackTrace),
    Ok(:final value) => .ok(value),
  };

  /// Converts this result into an [Option].
  ///
  /// Converts [Ok] to [Some] and [Err] to [None], discarding error information.
  ///
  /// Example:
  /// ```dart
  /// final option = result.toOption(); // Option<T>
  /// ```
  Option<T> toOption() => switch (this) {
    Ok(:final value) => .some(value),
    Err() => const .none(),
  };

  /// Unwraps the success value, or throws the error.
  ///
  /// This is the most direct way to extract the value, but will throw if
  /// the result is an error. Use with caution.
  ///
  /// Example:
  /// ```dart
  /// final value = result.unwrap(); // May throw
  /// ```
  T unwrap() => switch (this) {
    Ok(:final value) => value,
    Err(:final error, :final stackTrace) => Error.throwWithStackTrace(
      error,
      stackTrace,
    ),
  };

  /// Returns the success value, or [defaultValue] if this is an error.
  ///
  /// A safe way to extract a value with a guaranteed fallback. This method
  /// never throws and always returns a value.
  ///
  /// Example:
  /// ```dart
  /// final value = result.unwrapOr(0); // Returns 0 if error
  /// ```
  T unwrapOr(T defaultValue) => switch (this) {
    Ok(:final value) => value,
    Err() => defaultValue,
  };

  /// Returns the success value, or computes a default from the error.
  ///
  /// Applies [block] to the error to compute a fallback value if this is [Err].
  /// Useful when the default value depends on what the error was.
  ///
  /// Example:
  /// ```dart
  /// final value = result.unwrapOrElse((e) => handleError(e));
  /// ```
  T unwrapOrElse(T Function(E error) block) => switch (this) {
    Ok(:final value) => value,
    Err(:final error) => block(error),
  };

  /// Returns the success value as nullable, or null if this is an error.
  ///
  /// A safe way to extract a value when null is an acceptable default for
  /// errors.
  ///
  /// Never throws an exception.
  ///
  /// **Warning:** If [T] is nullable, this method cannot distinguish between
  /// `Ok(null)` and `Err(...)` — both return null. Use [toOption] instead
  /// for nullable [T].
  ///
  /// Example:
  /// ```dart
  /// final value = result.unwrapOrNull(); // Nullable<T>
  /// ```
  T? unwrapOrNull() => switch (this) {
    Ok(:final value) => value,
    Err() => null,
  };

  /// Combines two results using the [or] operator (|).
  ///
  /// Returns this result if it's a success, otherwise returns [other].
  Result<T, E> operator |(Result<T, E> other) => or(other);

  /// Executes an asynchronous function and wraps the result.
  ///
  /// Attempts to execute [asyncBlock] and wraps any exception in [Err].
  /// Returns [Ok] with the value if the async function succeeds.
  /// Returns [Err] with the caught exception and stack trace if an exception is thrown.
  ///
  /// This is the async counterpart to [Result.guardSync].
  ///
  /// Note: it will only catch [E] or subtypes of [E]. Other errors will be
  /// thrown.
  ///
  /// Example:
  /// ```dart
  /// final result = await Result<String, HttpException>.guardAsync(
  ///   () => fetchData(),
  /// );
  /// ```
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

/// Extension methods for flattening nested result types.
///
/// Useful when you have a [Result] containing another [Result] and need to
/// flatten it into a single result. This is the join/mu operation in monad terminology.
extension FlattenResultExtension<T extends Object?, E extends Object>
    on Result<Result<T, E>, E> {
  /// Flattens a nested [Result] into a single [Result].
  ///
  /// Converts [Result<Result<T, E>, E>] into [Result<T, E>].
  ///
  /// Example:
  /// ```dart
  /// final nested = Ok(Ok(42));
  /// final flat = nested.flatten(); // Ok(42)
  /// ```
  Result<T, E> flatten() => switch (this) {
    Ok(:final value) => value,
    Err(:final error, :final stackTrace) => .err(error, stackTrace),
  };
}

/// Extension methods for inspecting result values without transforming them.
///
/// Useful for logging, debugging, or side effects while preserving the result.
/// These methods allow you to peek at the value or error without consuming
/// the result, enabling fluent method chaining.
extension InspectResultExtension<T extends Object?, E extends Object>
    on Result<T, E> {
  /// Executes a side effect if this is an error, then returns this unchanged.
  ///
  /// The [block] callback is invoked with the error value if this is [Err].
  /// The result is returned unchanged, allowing for method chaining.
  /// Useful for logging errors without changing the result.
  ///
  /// Example:
  /// ```dart
  /// result
  ///   .inspectErr((e) => print('Error: $e'))
  ///   .unwrapOr(defaultValue);
  /// ```
  Result<T, E> inspectErr(void Function(E error) block) {
    if (this case Err(:final error)) {
      block(error);
    }
    return this;
  }

  /// Executes a side effect if this is a success, then returns this unchanged.
  ///
  /// The [block] callback is invoked with the success value if this is [Ok].
  /// The result is returned unchanged, allowing for method chaining.
  /// Useful for logging successful values without changing the result.
  ///
  /// Example:
  /// ```dart
  /// result
  ///   .inspectOk((value) => print('Success: $value'))
  ///   .andThen((v) => nextOperation(v));
  /// ```
  Result<T, E> inspectOk(void Function(T value) block) {
    if (this case Ok(:final value)) {
      block(value);
    }
    return this;
  }
}
