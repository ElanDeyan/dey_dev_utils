import 'package:meta/meta.dart';

@immutable
final class const None<T extends Object>() extends Option<T> {
  @override
  int get hashCode => runtimeType.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Option<T>) return false;
    if (other is Some<T>) return false;

    return true;
  }
}

@immutable
sealed class const Option<T extends Object>() {
  const factory none() = None<T>;
  const factory some(T value) = Some<T>;

  bool get isNone => this is None<T>;
  bool get isSome => this is Some<T>;
  T expect(String message) {
    if (this case Some<T>(:final value)) {
      return value;
    }

    throw StateError(message);
  }

  Option<T> inspect(void Function(T value) inspector) {
    final self = this;
    if (this case Some<T>(:final value)) {
      inspector(value);
    }

    return self;
  }

  bool isNoneOr(bool Function(T value) predicate) {
    if (this case Some<T>(:final value)) {
      return predicate(value);
    }

    return true;
  }

  bool isSomeAnd(bool Function(T value) predicate) {
    if (this case Some<T>(:final value)) {
      return predicate(value);
    }

    return false;
  }

  Option<U> map<U extends Object>(U Function(T value) mapper) {
    switch (this) {
      case Some<T>(:final value):
        return .some(mapper(value));
      case None<T>():
        return const .none();
    }
  }

  Option<U> mapOr<U extends Object>(
    U Function(T value) mapper, {
    required U defaultValue,
  }) {
    switch (this) {
      case Some<T>(:final value):
        return .some(mapper(value));
      case None<T>():
        return .some(defaultValue);
    }
  }

  Option<U> mapOrElse<U extends Object>(
    U Function(T value) mapper, {
    required U Function() defaultValue,
  }) {
    switch (this) {
      case Some<T>(:final value):
        return .some(mapper(value));
      case None<T>():
        return .some(defaultValue());
    }
  }

  T unwrap() {
    if (this case Some<T>(:final value)) {
      return value;
    }

    throw StateError('Called `unwrap` on a `None` value.');
  }

  T unwrapOr(T defaultValue) {
    if (this case Some<T>(:final value)) {
      return value;
    }

    return defaultValue;
  }

  T unwrapOrElse(T Function() defaultValue) {
    if (this case Some<T>(:final value)) {
      return value;
    }

    return defaultValue();
  }
}

@immutable
final class const Some<T extends Object>(final T value) extends Option<T> {
  @override
  int get hashCode => value.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Option<T>) return false;
    if (other is None<T>) return false;

    return switch (other) {
      None<T>() => false,
      Some<T>(value: final otherValue) => value == otherValue,
    };
  }
}
