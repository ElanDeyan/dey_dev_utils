@experimental
library;

import 'package:meta/meta.dart';

/// A monoid: a set of values with an associative binary operation and identity element.
///
/// A [Monoid] captures a fundamental algebraic structure consisting of:
/// - A type [T] representing the set of values
/// - A binary operation [combine] that combines two values of type [T]
/// - An identity element [empty] that doesn't change the result when combined
///
/// **Monoid laws (assumed but not enforced):**
/// 1. **Closure**: For any `a, b : T`, `combine(a, b) : T`
///    (combining two values produces another value of the same type)
/// 2. **Associativity**: `combine(combine(a, b), c) == combine(a, combine(b, c))`
///    (the order of grouping doesn't matter, only the order of application)
/// 3. **Identity**: `combine(empty, a) == a` and `combine(a, empty) == a`
///    (the empty element doesn't change anything when combined)
///
/// These laws are assumed to be satisfied by all implementations.
///
/// **Common examples:**
/// - **Integers with addition**: empty = 0, combine = (a, b) => a + b
/// - **Integers with multiplication**: empty = 1, combine = (a, b) => a * b
/// - **Strings with concatenation**: empty = "", combine = (a, b) => a + b
/// - **Lists with concatenation**: empty = [], combine = (a, b) => a + b
/// - **Booleans (logical OR)**: empty = false, combine = (a, b) => a || b
/// - **Booleans (logical AND)**: empty = true, combine = (a, b) => a && b
/// - **Any type with min/max**: empty = max/min value, combine = (a, b) => min/max(a, b)
///
/// **Use cases:**
/// - **Aggregation and reduction**: Combine multiple values into a single result
/// - **Parallel/distributed computation**: Combine partial results from independent computations
/// - **Accumulation**: Build up a value by repeatedly combining increments
/// - **Defaults and folding**: Safely reduce collections to a single value with predictable behavior
///
/// **Example - implementing a sum monoid:**
/// ```dart
/// class SumMonoid implements Monoid<int> {
///   const SumMonoid();
///
///   @override
///   int get empty => 0;
///
///   @override
///   int combine(int a, int b) => a + b;
/// }
///
/// // Usage
/// final sum = SumMonoid();
/// final result = [1, 2, 3, 4].fold(sum.empty, sum.combine); // 10
/// assert(result == 10);
/// ```
///
/// **Example - implementing a string concatenation monoid:**
/// ```dart
/// class StringMonoid implements Monoid<String> {
///   const StringMonoid();
///
///   @override
///   String get empty => '';
///
///   @override
///   String combine(String a, String b) => a + b;
/// }
///
/// // Usage
/// final str = StringMonoid();
/// final words = ['Hello', ' ', 'World'];
/// final result = words.fold(str.empty, str.combine); // 'Hello World'
/// ```
@experimental
abstract interface class Monoid<T extends Object?> {
  /// Creates a monoid instance.
  ///
  /// This constructor is typically called by concrete implementations.
  /// It can be used with `const` if all fields are compile-time constants.
  const Monoid();

  /// The identity element of this monoid.
  ///
  /// This value has the property that combining it with any other value
  /// leaves that value unchanged:
  /// - `combine(empty, a) == a` for any `a : T`
  /// - `combine(a, empty) == a` for any `a : T`
  ///
  /// This is the "neutral" or "zero" element of the monoid.
  /// For addition it's 0, for concatenation it's empty string/list, etc.
  T get empty;

  /// Combines two values of type [T] into a single value.
  ///
  /// This binary operation must satisfy:
  /// - **Closure**: The result is always of type [T]
  /// - **Associativity**: `combine(combine(a, b), c) == combine(a, combine(b, c))`
  ///
  /// The operation is typically commutative in practice (though mathematically
  /// a monoid doesn't require commutativity), and should be deterministic.
  ///
  /// Parameters:
  /// - [a]: The first value to combine
  /// - [b]: The second value to combine
  ///
  /// Returns: A new value representing the combination of [a] and [b].
  T combine(T a, T b);
}
