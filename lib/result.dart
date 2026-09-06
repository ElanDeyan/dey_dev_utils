import 'package:dey_dev_utils/option.dart';
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
  int get hashCode => error.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other case Err(error: final otherError)) return error == otherError;

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
  int get hashCode => value.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other case Ok(value: final otherValue)) return value == otherValue;

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
  /// Attempts to execute [block] and wraps any matching thrown value in [Err]
  /// with its stack trace. Returns [Ok] if successful. For catching only
  /// [Exception] types, use [guardExceptionSync] instead.
  ///
  /// **Note:** Only catches [E] or subtypes of [E]. Other exceptions will
  /// propagate uncaught.
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
  ///
  /// Useful for pattern matching or conditional error handling. If you need
  /// to check whether an error exists, use [isErr] instead for clarity.
  /// To extract the value, use [ok] for [Ok] results.
  E? get err => switch (this) {
    Ok() => null,
    Err(:final error) => error,
  };

  /// Returns true if this result is a failure ([Err]).
  ///
  /// Use this for conditional logic checking if an error occurred. For checking
  /// whether an error matches a condition, use [isErrAnd] instead.
  ///
  /// Example:
  /// ```dart
  /// if (result.isErr) {
  ///   print('Operation failed');
  /// }
  /// ```
  bool get isErr => this is Err<T, E>;

  /// Returns true if this result is a success ([Ok]).
  ///
  /// Use this for conditional logic checking if an operation succeeded. For
  /// checking whether a value matches a condition, use [isOkAnd] instead.
  ///
  /// Example:
  /// ```dart
  /// if (result.isOk) {
  ///   print('Operation succeeded');
  /// }
  /// ```
  bool get isOk => this is Ok<T, E>;

  /// Returns the success value if this is an [Ok], otherwise null.
  ///
  /// **Warning:** If [T] is nullable, this method cannot distinguish between
  /// `Ok(null)` and `Err(...)` — both return null. For nullable [T], use
  /// [toOption] for safe extraction, or [isOk] to check the state first.
  ///
  /// For most cases, prefer [unwrapOr], [unwrapOrNull], or [isOkAnd] instead
  /// of this getter for clearer intent.
  T? get ok => switch (this) {
    Ok(:final value) => value,
    Err() => null,
  };

  /// Combines two already-evaluated results using the [and] operator (&).
  ///
  /// Shorthand for calling [and]. Returns this result if it's an error,
  /// otherwise returns [other]. Because Dart evaluates operator operands
  /// before calling the operator, this does not prevent [other] from being
  /// created. Use [andLazy] when the fallback computation must be skipped.
  ///
  /// Example:
  /// ```dart
  /// final result = checkAuth(user) & validateData(data) & saveData(data);
  /// ```
  Result<T, E> operator &(Result<T, E> other) => and(other);

  /// Chains operations: returns this result if it's an error, otherwise [other].
  ///
  /// This is useful for performing sequential operations where the second
  /// depends on the first succeeding. If this result is [Err], it's returned
  /// unchanged (short-circuit). If this is [Ok], the [other] result is returned.
  /// The [other] result has already been evaluated before this method is
  /// called; use [andLazy] to defer its computation.
  /// Both [value] types and error types must match—for transformations, use
  /// [andThen] instead.
  ///
  /// Example:
  /// ```dart
  /// Result<int, String> a = Ok(5);
  /// Result<int, String> b = Ok(10);
  /// final result = a.and(b); // Returns b (Ok(10))
  ///
  /// Result<int, String> c = Err('failed');
  /// final result2 = c.and(b); // Returns c (Err('failed')); b is ignored
  /// ```
  Result<T, E> and(Result<T, E> other) {
    if (this is Err<T, E>) return this;

    return other;
  }

  /// Evaluates [otherBlock] only when this result is successful.
  ///
  /// Use this method for lazy sequential composition. Unlike [and] and
  /// [operator &], the callback is not invoked when this result is an error.
  Result<T, E> andLazy(Result<T, E> Function() otherBlock) {
    if (this is Err<T, E>) return this;

    return otherBlock();
  }

  /// Transforms the success value into a new result, or propagates the error.
  ///
  /// If this is [Ok], applies [otherBlock] to the value and returns its result.
  /// If this is [Err], propagates the error unchanged (short-circuit behavior).
  /// Stack traces are preserved through error propagation.
  ///
  /// This is the monadic bind operation (flatMap), useful for chaining
  /// operations that might fail while maintaining error information throughout
  /// the chain. Use [map] for simple value transformations that can't fail.
  ///
  /// Example:
  /// ```dart
  /// final result = getUserId()
  ///   .andThen((id) => getUser(id))
  ///   .andThen((user) => loadPreferences(user.id));
  /// // If any step fails, subsequent steps are skipped
  /// ```
  Result<U, E> andThen<U extends Object?>(
    Result<U, E> Function(T value) otherBlock,
  ) => switch (this) {
    Ok(:final value) => otherBlock(value),
    Err(:final error, :final stackTrace) => .err(error, stackTrace),
  };

  /// Returns a shallow copy of this result.
  ///
  /// The result wrapper is copied, but mutable values and errors are shared.
  /// Error stack traces are preserved. For creating new results, prefer [Ok]
  /// or [Err] constructors directly.
  Result<T, E> clone() => switch (this) {
    Err<T, E>(:final error, :final stackTrace) => .err(error, stackTrace),
    Ok<T, E>(:final value) => .ok(value),
  };

  /// Unwraps the success value, or throws an exception with [message].
  ///
  /// Use this when you're certain the result should be [Ok], but want to
  /// provide a custom error message if it's not. The original stack trace
  /// is preserved. For unwrapping with fallback values, use [unwrapOr] or
  /// [unwrapOrElse] instead.
  ///
  /// Example:
  /// ```dart
  /// final value = result.expect('Operation should have succeeded');
  /// final config = loadConfig().expect('Config file must be valid');
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
  /// provide a custom error message if it's not. The original stack trace
  /// is preserved. Primarily useful for testing or assertions. For normal
  /// error handling, prefer [err], [isErr], or pattern matching.
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
  /// Use this for conditional error checking without extracting the error value.
  /// For other checks, use [isErr] or pattern matching.
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
  /// Use this for conditional logic without extracting the value, maintaining
  /// type safety. For other checks, use pattern matching or [isOk].
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
  /// If this is [Ok], applies [block] to the value and wraps the result in [Ok].
  /// If this is [Err], returns the same error unchanged. The error type remains
  /// the same; for transforming errors, use [mapErr] instead.
  ///
  /// This is useful for value transformations that can't fail. For operations
  /// that might fail, use [andThen] (flatMap) instead. Errors short-circuit
  /// the transformation and are returned immediately.
  ///
  /// Example:
  /// ```dart
  /// Result<int, String> result = Ok(5);
  /// final doubled = result.map((value) => value * 2); // Ok(10)
  ///
  /// Result<int, String> error = Err('failed');
  /// final doubled2 = error.map((value) => value * 2); // Err('failed')
  /// ```
  Result<Y, E> map<Y extends Object?>(Y Function(T value) block) =>
      switch (this) {
        Err<T, E>(:final error, :final stackTrace) => .err(error, stackTrace),
        Ok<T, E>(:final value) => .ok(block(value)),
      };

  /// Transforms the error value using [block], leaving success values unchanged.
  ///
  /// If this is [Err], applies [block] to the error and wraps the result in
  /// a new error type. If this is [Ok], returns the same success value with
  /// the new error type. Useful for converting error types when delegating
  /// to functions expecting different error types.
  ///
  /// Example:
  /// ```dart
  /// Result<String, String> result = Err('failed');
  /// final mapped = result.mapErr((e) => CustomError(e)); // Err(CustomError)
  /// ```
  Result<T, F> mapErr<F extends Object>(F Function(E error) block) =>
      switch (this) {
        Err<T, E>(:final error, :final stackTrace) => .err(
          block(error),
          stackTrace,
        ),
        Ok<T, E>(:final value) => .ok(value),
      };

  /// Returns this result if it's a success, otherwise the already-evaluated
  /// [other].
  ///
  /// Use this to provide a fallback result when the first result fails.
  /// The first successful result is returned; if both fail, the second error
  /// is returned. Because Dart evaluates operator operands before calling the
  /// operator, this does not prevent [other] from being created. Use [orLazy]
  /// for lazy fallbacks, or [orElse] for fallbacks based on the error.
  ///
  /// Example:
  /// ```dart
  /// Result<int, String> a = Err('failed');
  /// Result<int, String> b = Ok(10);
  /// final result = a | b; // Returns b (Ok(10))
  /// final result = cachedResult | freshResult;
  /// ```
  Result<T, E> or(Result<T, E> other) {
    if (this is Ok<T, E>) return this;

    return other;
  }

  /// Evaluates [otherBlock] only when this result is an error.
  ///
  /// Use this method for lazy fallback composition. Unlike [or] and
  /// [operator |], the callback is not invoked when this result is successful.
  Result<T, E> orLazy(Result<T, E> Function() otherBlock) {
    if (this is Ok<T, E>) return this;

    return otherBlock();
  }

  /// Returns this success value, or computes a recovery result from the error.
  ///
  /// If this is [Ok], returns it unchanged. If this is [Err], applies [otherBlock]
  /// to the error and stack trace, returning the computed result. Use this for
  /// dynamic recovery that depends on what the error was. For static fallbacks,
  /// use [or] instead.
  ///
  /// This allows context-aware error handling—examine the error and decide
  /// whether to recover or propagate a different result.
  ///
  /// Example:
  /// ```dart
  /// final result = operation.orElse(
  ///   (error, st) => error is NotFoundException
  ///     ? Ok(defaultValue)
  ///     : Err(error),
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
  /// Use this when you only care whether a value exists, not why it failed.
  /// If you need the error information, keep it as a [Result].
  ///
  /// Example:
  /// ```dart
  /// final option = result.toOption(); // Option<T>
  /// final value = option.unwrapOr(defaultValue);
  /// ```
  Option<T> toOption() => switch (this) {
    Ok(:final value) => .some(value),
    Err() => const .none(),
  };

  /// Returns the success value, or throws the error with its original stack trace.
  ///
  /// This is the most direct way to extract the value. Use with caution—only
  /// when you're certain the result should be [Ok] or want to fail hard if
  /// it's not. For safer extraction with fallbacks, use [unwrapOr],
  /// [unwrapOrNull], or [expect] instead.
  ///
  /// The original stack trace is preserved when throwing, making debugging easier.
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
  /// never throws and always returns a value. Use this when you have a
  /// sensible default value that doesn't depend on the error.
  /// For defaults computed from the error, use [unwrapOrElse] instead.
  ///
  /// Example:
  /// ```dart
  /// final value = result.unwrapOr(0); // Returns 0 if error
  /// final name = result.unwrapOr('Unknown'); // Returns 'Unknown' if error
  /// ```
  T unwrapOr(T defaultValue) => switch (this) {
    Ok(:final value) => value,
    Err() => defaultValue,
  };

  /// Returns the success value, or computes a default from the error.
  ///
  /// Applies [block] to the error to compute a fallback value if this is [Err].
  /// Use this when the default value depends on what the error was, allowing
  /// context-aware recovery. For static defaults, use [unwrapOr] instead.
  ///
  /// Example:
  /// ```dart
  /// final value = result.unwrapOrElse(
  ///   (e) => handleError(e),
  /// );
  /// final retryCount = result.unwrapOrElse(
  ///   (e) => e.isRetryable ? 3 : 0,
  /// );
  /// ```
  T unwrapOrElse(T Function(E error) block) => switch (this) {
    Ok(:final value) => value,
    Err(:final error) => block(error),
  };

  /// Returns the success value as nullable, or null if this is an error.
  ///
  /// A safe way to extract a value when null is an acceptable default for
  /// errors. Never throws an exception. Use this for optional extraction
  /// without distinguishing between error states.
  ///
  /// **Warning:** If [T] is nullable, this method cannot distinguish between
  /// `Ok(null)` and `Err(...)`—both return null. For nullable [T] types,
  /// use [toOption] for safe extraction, or [isOk] to check the state first.
  ///
  /// Example:
  /// ```dart
  /// final value = result.unwrapOrNull(); // Nullable<T>
  /// final name = getName().unwrapOrNull() ?? 'Unknown';
  /// ```
  T? unwrapOrNull() => switch (this) {
    Ok(:final value) => value,
    Err() => null,
  };

  /// Combines two already-evaluated results using the [or] operator (|).
  ///
  /// Shorthand for calling [or]. Returns this result if it's a success,
  /// otherwise returns [other]. Because Dart evaluates operator operands
  /// before calling the operator, use [orLazy] to defer fallback computation.
  ///
  /// Example:
  /// ```dart
  /// final result = fetchFromCache() | fetchFromNetwork();
  /// ```
  Result<T, E> operator |(Result<T, E> other) => or(other);

  /// Executes an asynchronous function and wraps the result.
  ///
  /// Attempts to execute [asyncBlock] and wraps any matching thrown value in
  /// [Err] with its stack trace. Returns [Ok] if the async operation succeeds.
  /// For catching only [Exception] types, use [guardExceptionAsync] instead.
  ///
  /// **Note:** Only catches [E] or subtypes of [E]. Other exceptions will
  /// propagate uncaught.
  ///
  /// This is the async counterpart to [guardSync]. Stack traces are preserved
  /// for better debugging.
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

  /// Executes an asynchronous function, catching only [Exception] types.
  ///
  /// A convenience method that constrains the error type to [Exception]
  /// rather than accepting any [Object]. Use this when you want [Error]
  /// values to propagate uncaught.
  ///
  /// Example:
  /// ```dart
  /// final result = await Result<String, IOException>.guardExceptionAsync(
  ///   () => file.readAsString(),
  /// );
  /// ```
  static Future<Result<T, E>> guardExceptionAsync<
    T extends Object?,
    E extends Exception
  >(Future<T> Function() asyncBlock) => guardAsync<T, E>(asyncBlock);

  /// Executes a synchronous function, catching only [Exception] types.
  ///
  /// A convenience method that constrains the error type to [Exception]
  /// rather than accepting any [Object]. Use this when you want [Error]
  /// values to propagate uncaught.
  ///
  /// Example:
  /// ```dart
  /// final result = Result<int, FormatException>.guardExceptionSync(
  ///   () => int.parse(input),
  /// );
  /// ```
  static Result<T, E> guardExceptionSync<
    T extends Object?,
    E extends Exception
  >(T Function() block) => Result<T, E>.guardSync(block);
}

/// Extension methods for flattening nested result types.
///
/// Useful when you have a [Result] containing another [Result] and need to
/// flatten it into a single result. This is the join/mu operation in monad terminology.
extension FlattenResultExtension<T extends Object?, E extends Object>
    on Result<Result<T, E>, E> {
  /// Flattens a nested [Result] into a single [Result].
  ///
  /// Converts [Result<Result<T, E>, E>] into [Result<T, E>]. Use this when
  /// you have a result that contains another result, such as one created with
  /// [map] or explicit nested construction. [andThen] already flat-maps the
  /// result returned by its callback. This unwraps one level of nesting.
  ///
  /// Example:
  /// ```dart
  /// final nested = Ok(Ok(42));
  /// final flat = nested.flatten(); // Ok(42)
  ///
  /// final nested2 = Ok(Err('error'));
  /// final flat2 = nested2.flatten(); // Err('error')
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
  /// The result is returned unchanged, allowing for method chaining. Useful
  /// for logging errors, metrics, or cleanup without consuming the result.
  /// Does nothing if this is [Ok].
  ///
  /// Example:
  /// ```dart
  /// result
  ///   .inspectErr((e) => logger.error('Failed: $e'))
  ///   .inspectErr((e) => metrics.recordError(e))
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
  /// The result is returned unchanged, allowing for method chaining. Useful
  /// for logging, validation, or side effects without transforming the value.
  /// Does nothing if this is [Err].
  ///
  /// Example:
  /// ```dart
  /// result
  ///   .inspectOk((value) => logger.info('Success: $value'))
  ///   .inspectOk((value) => metrics.recordSuccess(value))
  ///   .andThen((v) => nextOperation(v));
  /// ```
  Result<T, E> inspectOk(void Function(T value) block) {
    if (this case Ok(:final value)) {
      block(value);
    }
    return this;
  }
}
