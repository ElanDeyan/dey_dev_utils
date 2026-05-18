abstract interface class Monoid<T extends Object?> {
  const Monoid();

  T get empty;

  T combine(T a, T b);
}
