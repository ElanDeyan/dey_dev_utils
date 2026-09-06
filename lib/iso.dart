@experimental
library;

import 'package:dey_dev_utils/lens.dart';
import 'package:meta/meta.dart';

/// An isomorphism: a reversible transformation between two types.
///
/// An [Iso] represents a bidirectional mapping between types [A] and [B].
/// It consists of two inverse functions:
/// - [to]: transforms from [A] to [B]
/// - [from]: transforms from [B] to [A]
///
/// These functions form an isomorphism, meaning they are perfect inverses
/// of each other: `from(to(a)) == a` and `to(from(b)) == b` for all valid
/// values. This property is assumed but not enforced by the type system.
///
/// **Use cases:**
/// - Type conversions with guaranteed round-trip safety
/// - Bidirectional serialization/deserialization
/// - Format conversions (e.g., JSON ↔ Dart objects)
/// - Domain modeling (e.g., string representations ↔ enums)
///
/// **Example:**
/// ```dart
/// // Define an isomorphism between String and int
/// final stringToInt = Iso(
///   to: (s) => int.parse(s),
///   from: (i) => i.toString(),
/// );
///
/// // Use it
/// assert(stringToInt.to('42') == 42);
/// assert(stringToInt.from(42) == '42');
/// assert(stringToInt.from(stringToInt.to('42')) == '42'); // Round-trip
/// ```
@experimental
final class Iso<A extends Object?, B extends Object?> {
  /// Creates an isomorphism with the given [to] and [from] transformations.
  ///
  /// Both [to] and [from] are required. For this to represent a valid
  /// isomorphism, they must be proper inverses of each other.
  const Iso({required this.to, required this.from});

  /// Transforms a value from type [A] to type [B].
  ///
  /// This should be the inverse of [from], such that
  /// `from(to(a)) == a` for all values [a].
  final B Function(A) to;

  /// Transforms a value from type [B] to type [A].
  ///
  /// This should be the inverse of [to], such that
  /// `to(from(b)) == b` for all values [b].
  final A Function(B) from;

  /// Downgrades this isomorphism to a [Lens].
  ///
  /// Every isomorphism is a lens (you can always get and set), but not every
  /// lens is an isomorphism. This returns a lens where:
  /// - **get** uses [to] to extract the [B] value from an [A]
  /// - **set** uses [from] to reconstruct the [A] value from a [B]
  ///
  /// The old value is ignored during set (since isomorphisms can fully
  /// reconstruct from just the new part).
  ///
  /// Example:
  /// ```dart
  /// final iso = Iso(to: (s) => int.parse(s), from: (i) => i.toString());
  /// final lens = iso.asLens;
  /// assert(lens.get('123') == 123);
  /// assert(lens.set('old', 456) == '456');
  /// ```
  ///
  /// See also: [Lens]
  Lens<A, B> get asLens => Lens(get: to, set: (_, b) => from(b));

  /// Flips the direction of this isomorphism.
  ///
  /// Returns a new [Iso] that transforms from [B] to [A] instead of [A] to [B],
  /// by swapping the [to] and [from] functions. This is mathematically free
  /// since isomorphisms are symmetric.
  ///
  /// If `iso.to(a) == b`, then `iso.inverse.from(b) == a`.
  ///
  /// Example:
  /// ```dart
  /// final iso = Iso(to: int.parse, from: (i) => i.toString());
  /// final inv = iso.inverse;
  /// assert(inv.to(42) == '42');
  /// assert(inv.from('42') == 42);
  /// ```
  Iso<B, A> get inverse => Iso(to: from, from: to);

  /// Lifts this isomorphism to work on lists of values.
  ///
  /// Returns a new [Iso] that transforms `List<A>` to `List<B>` (and vice versa)
  /// by applying [to] and [from] to each element. This is useful when you want
  /// to apply an isomorphism to a collection of values.
  ///
  /// If `iso` is a valid isomorphism, then `iso.isoList` is also a valid
  /// isomorphism (the round-trip property holds element-wise).
  ///
  /// Example:
  /// ```dart
  /// final iso = Iso(to: int.parse, from: (i) => i.toString());
  /// final listIso = iso.isoList;
  /// assert(listIso.to(['1', '2', '3']) == [1, 2, 3]);
  /// assert(listIso.from([10, 20]) == ['10', '20']);
  /// ```
  Iso<List<A>, List<B>> get isoList =>
      Iso(to: (as) => as.map(to).toList(), from: (bs) => bs.map(from).toList());

  /// Composes this isomorphism with another isomorphism.
  ///
  /// Chains two isomorphisms: `A ↔ B` and `B ↔ C` to create a new isomorphism
  /// `A ↔ C`. This allows you to build complex transformations by composing
  /// simpler ones.
  ///
  /// The composition follows mathematical function composition:
  /// - Forward: `other.to(to(a))` - apply this iso's [to], then the other's [to]
  /// - Backward: `from(other.from(c))` - apply the other's [from], then this iso's [from]
  ///
  /// Type parameter [C] is the final type in the chain.
  ///
  /// Example:
  /// ```dart
  /// // Chain: String -> int -> bool (if int.isEven)
  /// final toInt = Iso(to: int.parse, from: (i) => i.toString());
  /// final toBool = Iso(to: (i) => i.isEven, from: (b) => b ? 2 : 1);
  /// final stringToBool = toInt.then(toBool);
  ///
  /// assert(stringToBool.to('4') == true);   // '4' -> 4 -> true
  /// assert(stringToBool.from(false) == '1'); // false -> 1 -> '1'
  /// ```
  Iso<A, C> then<C>(Iso<B, C> other) =>
      Iso(to: (a) => other.to(to(a)), from: (c) => from(other.from(c)));
}
