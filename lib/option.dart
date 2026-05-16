import 'package:meta/meta.dart';

@immutable
final class None<T extends Object?> extends Option<T> {
  const None();
}

@immutable
class Option<T extends Object?> {
  const Option();

  const factory Option.none() = None;
  const factory Option.some(T value) = Some;
}

@immutable
final class Some<T extends Object?> extends Option<T> {
  final T value;

  const Some(this.value);
}
