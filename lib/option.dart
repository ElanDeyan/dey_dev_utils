/// A value that may be present or absent.
///
/// Use [Option] when the absence of a value is expected and should be handled
/// explicitly. A [Some] contains a non-null value, while [None] represents
/// absence. Transform and combine options without unwrapping them, or use an
/// exhaustive switch when both cases need different handling.
///
/// {@example /example/doc_examples/option.dart}
library;

import 'package:meta/meta.dart';

/// An optional value that is either present or absent.
///
/// Use [Option.some] for a present value and [Option.none] for absence. The
/// type parameter [T] is non-nullable; nullable values can be converted with
/// [Option.fromNullable].
@immutable
sealed class const Option<T extends Object>() {
  /// Creates an option.
  this;

  /// Creates an option from a nullable [value].
  ///
  /// Returns [Option.none] when [value] is `null`, and [Option.some] otherwise.
  factory fromNullable(T? value) {
    if (value == null) {
      return None<T>();
    }

    return .some(value);
  }

  /// Creates an absent option.
  const factory none() = None<T>;

  /// Creates an option containing [value].
  const factory some(T value) = Some<T>;

  /// Whether this option represents an absent value.
  bool get isNone => this is None<T>;

  /// Whether this option contains a value.
  bool get isSome => this is Some<T>;

  /// An [Iterable] that yields this option once.
  Iterable<T> get iterable sync* {
    switch (this) {
      case None<T>():
        return;
      case Some<T>(:final value):
        yield value;
    }
  }

  /// Returns the option that is present only when exactly one operand is
  /// present.
  Option<T> operator ^(Option<T> other) => xor(other);

  /// Returns [other] when this option contains a value, or [Option.none]
  /// otherwise.
  Option<U> and<U extends Object>(Option<U> other) {
    switch (this) {
      case None<T>():
        return const .none();
      case Some<T>():
        return other;
    }
  }

  /// Applies [callback] to the contained value and returns its option.
  ///
  /// Returns [Option.none] without calling [callback] when this option is
  /// absent.
  Option<U> andThen<U extends Object>(Option<U> Function(T value) callback) {
    switch (this) {
      case None<T>():
        return const .none();
      case Some<T>(:final value):
        return callback(value);
    }
  }

  /// Returns the contained value or throws a [StateError] with [message].
  ///
  /// Prefer this when absence indicates a programming error and the supplied
  /// [message] explains the violated expectation.
  T expect(String message) {
    switch (this) {
      case None<T>():
        throw StateError(message);
      case Some<T>(:final value):
        return value;
    }
  }

  /// Calls [inspector] with the contained value, then returns this option.
  ///
  /// Does not call [inspector] when this option is absent.
  Option<T> inspect(void Function(T value) inspector) {
    final self = this;
    if (this case Some<T>(:final value)) {
      inspector(value);
    }

    return self;
  }

  /// Whether this option is absent or its value satisfies [predicate].
  bool isNoneOr(bool Function(T value) predicate) {
    switch (this) {
      case None<T>():
        return true;
      case Some<T>(:final value):
        return predicate(value);
    }
  }

  /// Whether this option contains a value that satisfies [predicate].
  bool isSomeAnd(bool Function(T value) predicate) {
    switch (this) {
      case None<T>():
        return false;
      case Some<T>(:final value):
        return predicate(value);
    }
  }

  /// Transforms the contained value with [mapper], preserving absence.
  Option<U> map<U extends Object>(U Function(T value) mapper) {
    switch (this) {
      case Some<T>(:final value):
        return .some(mapper(value));
      case None<T>():
        return const .none();
    }
  }

  /// Transforms the contained value with [mapper], or uses [defaultValue].
  ///
  /// The result always contains a value: [mapper] is applied to a present
  /// value, and [defaultValue] is used when this option is absent.
  U mapOr<U extends Object>(
    U Function(T value) mapper, {
    required U defaultValue,
  }) {
    switch (this) {
      case Some<T>(:final value):
        return mapper(value);
      case None<T>():
        return defaultValue;
    }
  }

  /// Transforms the contained value with [mapper], or computes a fallback.
  ///
  /// The result always contains a value. [defaultValue] is called only when
  /// this option is absent.
  U mapOrElse<U extends Object>(
    U Function(T value) mapper, {
    required U Function() defaultValue,
  }) {
    switch (this) {
      case Some<T>(:final value):
        return mapper(value);
      case None<T>():
        return defaultValue();
    }
  }

  /// Returns this option when it contains a value, or [other] otherwise.
  Option<T> or(Option<T> other) {
    switch (this) {
      case None<T>():
        return other;
      case Some<T>():
        return this;
    }
  }

  /// Returns this option when present, or calls [callback] otherwise.
  ///
  /// [callback] is called only when this option is absent.
  Option<T> orElse(Option<T> Function() callback) {
    switch (this) {
      case None<T>():
        return callback();
      case Some<T>():
        return this;
    }
  }

  /// Returns the contained value or throws a [StateError] if absent.
  T unwrap() {
    switch (this) {
      case Some<T>(:final value):
        return value;
      case None<T>():
        throw StateError('Called `unwrap` on a `None` value.');
    }
  }

  /// Returns the contained value, or [defaultValue] if absent.
  T unwrapOr(T defaultValue) {
    switch (this) {
      case Some<T>(:final value):
        return value;
      case None<T>():
        return defaultValue;
    }
  }

  /// Returns the contained value, or computes a fallback if absent.
  ///
  /// [defaultValue] is called only when this option is absent.
  T unwrapOrElse(T Function() defaultValue) {
    switch (this) {
      case Some<T>(:final value):
        return value;
      case None<T>():
        return defaultValue();
    }
  }

  /// Keeps the contained value only when it satisfies [predicate].
  Option<T> where(bool Function(T value) predicate) {
    switch (this) {
      case None<T>():
        return const .none();
      case Some<T>(:final value):
        if (predicate(value)) {
          return this;
        }

        return const .none();
    }
  }

  /// Returns the option that is present only when exactly one operand is
  /// present.
  Option<T> xor(Option<T> other) {
    switch (this) {
      case None<T>():
        return other;
      case Some<T>():
        if (other is None<T>) {
          return this;
        }

        return const .none();
    }
  }

  /// Combines the two contained values into a record, or returns [Option.none]
  /// if either option is absent.
  Option<(T, U)> zip<U extends Object>(Option<U> other) {
    switch (this) {
      case None<T>():
        return const .none();
      case Some<T>(:final value):
        if (other case Some<U>(value: final otherValue)) {
          return .some((value, otherValue));
        }

        return const .none();
    }
  }

  /// Combines two contained values with [callback], or returns [Option.none]
  /// if either option is absent.
  Option<R> zipWith<U extends Object, R extends Object>(
    Option<U> other,
    R Function(T value, U otherValue) callback,
  ) {
    switch (this) {
      case None<T>():
        return const .none();
      case Some<T>(:final value):
        if (other case Some<U>(value: final otherValue)) {
          return .some(callback(value, otherValue));
        }

        return const .none();
    }
  }

  /// Returns this option when present, or [other] otherwise.
  Option<T> operator |(Option<T> other) => or(other);
}

/// An absent value.
///
/// Use [Option.none] when an operation has no value to return.
@immutable
final class const None<T extends Object>() extends Option<T> {
  /// Creates an absent option.
  this;

  /// The hash code of this absent option.
  @override
  int get hashCode => runtimeType.hashCode;

  /// Whether [other] is an absent option of the same type.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Option<T> && other is None<T>;
  }
}

/// A present value wrapped in an option.
///
/// Use [Option.some] to create one, or pattern match on [Some] to access its
/// value.
@immutable
final class const Some<T extends Object>(
  /// The non-null value contained in this option.
  final T value,
) extends Option<T> {
  /// Creates an option containing [value].
  this;

  @override
  int get hashCode => Object.hash(runtimeType, value);

  /// Whether [other] contains a value equal to this option's value.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Option<T> && other is Some<T> && other.value == value;
  }
}

/// Provides [flatten] for nested options.
extension FlattenOptionExtension<T extends Object> on Option<Option<T>> {
  /// Removes one level of nesting from an option.
  Option<T> flatten() {
    switch (this) {
      case None<Option<T>>():
        return const .none();
      case Some<Option<T>>(:final value):
        return value;
    }
  }
}

/// Provides [unzip] for options containing a pair.
extension UnzipOptionExtension<T extends Object, U extends Object>
    on Option<(T, U)> {
  /// Splits a pair into two options.
  ///
  /// When this option contains a pair, both returned options contain their
  /// corresponding value. When this option is absent, both are absent.
  (Option<T>, Option<U>) unzip() {
    switch (this) {
      case None<(T, U)>():
        return const (.none(), .none());
      case Some<(T, U)>(:final value):
        final (first, second) = value;
        return (.some(first), .some(second));
    }
  }
}
