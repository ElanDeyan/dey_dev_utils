R run<R extends Object?>(R Function() block) => block();

R runWith<R extends Object?, T extends Object?>(
  T value,
  R Function(T value) block,
) => block(value);

extension InspectExtension<T extends Object> on T {
  T inspect(void Function(T value) block) {
    try {
      return this;
    } finally {
      block(this);
    }
  }
}

extension LetExtension<T extends Object> on T {
  R let<R extends Object?>(R Function(T value) block) => block(this);
}

extension TakeExtension<T extends Object> on T {
  // ignore: avoid_positional_boolean_parameters
  T? takeIf(bool condition) {
    if (condition) return this;

    return null;
  }

  T? takeIfLazy(bool Function(T value) predicate) {
    if (predicate(this)) return this;

    return null;
  }

  T? takeUnless(bool condition) {
    if (!condition) return this;

    return null;
  }

  T? takeUnlessLazy(bool Function(T value) predicate) {
    if (!predicate(this)) return this;

    return null;
  }
}
