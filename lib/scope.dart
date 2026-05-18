// ignore_for_file: avoid_positional_boolean_parameters

R run<R extends Object?>(R Function() block) => block();

R use<R extends Object?, T extends Object?>(
  T value,
  R Function(T value) block, {
  void Function(T value)? dispose,
}) {
  try {
    return block(value);
  } finally {
    dispose?.call(value);
  }
}

extension AlsoExtension<T extends Object> on T {
  T also(void Function(T value) block) {
    try {
      return this;
    } finally {
      block(this);
    }
  }
}

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
