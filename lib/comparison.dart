enum Comparison {
  less,
  equal,
  higher;

  int asInt() => switch (this) {
    .less => -1,
    .equal => 0,
    .higher => 1,
  };
}

extension ComparableResult<T extends Object> on Comparable<T> {
  Comparison compareWith(T other) {
    final result = compareTo(other);

    return switch (result) {
      < 0 => .less,
      == 0 => .equal,
      > 0 => .higher,
      _ => throw Exception('Impossible case'),
    };
  }
}
