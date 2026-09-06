import 'package:meta/meta.dart';

@immutable
final class None<T extends Object?> extends Option<T> {
  const None();

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  bool operator ==(covariant Option<T> other) {
    if (other is Some<T>) return false;

    return true;
  }
}

@immutable
sealed class Option<T extends Object?> {
  const Option();

  const factory Option.none() = None<T>;
  const factory Option.some(T value) = Some<T>;
}

@immutable
final class Some<T extends Object?> extends Option<T> {
  const Some(this.value);
  final T value;

  @override
  int get hashCode => value.hashCode;

  @override
  bool operator ==(covariant Option<T> other) {
    return switch (other) {
      None<T>() => false,
      Some<T>() => value == other.value,
    };
  }
}
