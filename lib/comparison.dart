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
