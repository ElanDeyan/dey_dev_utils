import 'package:dev_utils/lens.dart';

final class Iso<A extends Object?, B extends Object?> {
  const Iso({required this.to, required this.from});
  final B Function(A) to;
  final A Function(B) from;

  // Downgrade to Lens (every Iso is a Lens):
  Lens<A, B> get asLens => Lens(get: to, set: (_, b) => from(b));

  // Flip direction — free!
  Iso<B, A> get inverse => Iso(to: from, from: to);

  // Lift to work on lists:
  Iso<List<A>, List<B>> get isoList =>
      Iso(to: (as) => as.map(to).toList(), from: (bs) => bs.map(from).toList());

  // Compose: A ↔️ B ↔️ C becomes A ↔️ C
  Iso<A, C> then<C>(Iso<B, C> other) =>
      Iso(to: (a) => other.to(to(a)), from: (c) => from(other.from(c)));
}
