final class Once<T extends Object?> {
  Once(this._init);

  final T Function() _init;
  T? _value;

  T call() => _value ??= _init();
}
