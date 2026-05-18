// The trampoline — runs until Done:
T trampoline<T>(Bounce<T> bounce) {
  var current = bounce;

  while (current is More<T>) {
    current = current.next();
  }

  assert(current is Done<T>);

  return (current as Done<T>).value;
}

sealed class Bounce<T extends Object?> {
  const Bounce();
}

class Done<T extends Object?> extends Bounce<T> {
  const Done(this.value);
  final T value;
}

class More<T extends Object?> extends Bounce<T> {
  const More(this.next);
  final Bounce<T> Function() next;
}
