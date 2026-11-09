import 'package:dey_dev_utils/option.dart';
import 'package:dey_dev_utils/result.dart';

/// Provides conversions from [Option] to [Result].
extension OptionResultExtension<T extends Object> on Option<T> {
  /// Converts this option to a result, using [error] when the option is absent.
  ///
  /// [stackTrace] defaults to the current stack trace and is used only when
  /// this option is absent.
  Result<T, E> okOr<E extends Object>(E error, {StackTrace? stackTrace}) =>
      switch (this) {
        Some<T>(:final value) => .ok(value),
        None<T>() => .err(error, stackTrace ?? .current),
      };

  /// Converts this option to a result, computing the error only when absent.
  ///
  /// [stackTrace] defaults to the current stack trace and is used only when
  /// this option is absent.
  Result<T, E> okOrElse<E extends Object>(
    E Function() error, {
    StackTrace? stackTrace,
  }) => switch (this) {
    Some<T>(:final value) => .ok(value),
    None<T>() => .err(error(), stackTrace ?? .current),
  };
}

/// Provides transpose for an option containing a result.
extension OptionTransposeExtension<T extends Object, E extends Object>
    on Option<Result<T, E>> {
  /// Transposes this option of a result into a result of an option.
  ///
  /// An absent option becomes `Ok(None)`. An error becomes `Err` with its
  /// original stack trace.
  Result<Option<T>, E> transpose() => switch (this) {
    None<Result<T, E>>() => .ok(Option<T>.none()),
    Some<Result<T, E>>(:final value) => switch (value) {
      Err<T, E>(:final error, :final stackTrace) => .err(error, stackTrace),
      Ok<T, E>(:final value) => .ok(.some(value)),
    },
  };
}

/// Provides conversions from [Result] to [Option].
extension ResultOptionExtension<T extends Object, E extends Object>
    on Result<T, E> {
  /// Returns a present option for a success, or an absent option for an error.
  ///
  /// This discards error information. Use [isOk] or pattern matching when the
  /// success or error variant matters.
  Option<T> toOption() => switch (this) {
    Err<T, E>() => Option<T>.none(),
    Ok<T, E>(:final value) => .some(value),
  };
}

/// Provides transpose for a result containing an option.
extension ResultTransposeExtension<T extends Object, E extends Object>
    on Result<Option<T>, E> {
  /// Transposes this result of an option into an option of a result.
  ///
  /// An error becomes a present `Err` with its original stack trace. A
  /// successful absent option becomes absent.
  Option<Result<T, E>> transpose() => switch (this) {
    Err<Option<T>, E>(:final error, :final stackTrace) => .some(
      .err(error, stackTrace),
    ),
    Ok<Option<T>, E>(:final value) => switch (value) {
      None<T>() => Option<Result<T, E>>.none(),
      Some<T>(:final value) => .some(.ok(value)),
    },
  };
}
