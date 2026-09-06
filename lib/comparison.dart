/// Represents the result of a comparison operation between two values.
///
/// This enum provides a type-safe way to work with comparison results,
/// replacing magic numbers (-1, 0, 1) with meaningful enum cases.
///
/// Use this instead of raw integer comparisons for better readability
/// and type safety.
///
/// Example:
/// ```dart
/// final comparison = 'a'.compareWith('b');
/// if (comparison == Comparison.less) {
///   print('First is less than second');
/// }
/// ```
enum Comparison {
  /// Indicates the first value is less than the second.
  less,

  /// Indicates the first value is equal to the second.
  equal,

  /// Indicates the first value is greater than the second.
  greater;

  /// Converts this comparison result to its integer representation.
  ///
  /// Returns:
  /// - `-1` for [less]
  /// - `0` for [equal]
  /// - `1` for [greater]
  ///
  /// This representation is compatible with standard comparison functions
  /// like those in sorting algorithms or [Comparable.compareTo].
  ///
  /// Example:
  /// ```dart
  /// Comparison.less.asInt();   // -1
  /// Comparison.equal.asInt();  // 0
  /// Comparison.greater.asInt(); // 1
  /// ```
  int asInt() => switch (this) {
    .less => -1,
    .equal => 0,
    .greater => 1,
  };
}

/// Extension that provides type-safe comparison methods for [Comparable] types.
///
/// This extension wraps Dart's [Comparable] interface and converts raw integer
/// results to the more expressive [Comparison] enum, making comparison code
/// more readable and maintainable.
///
/// Example:
/// ```dart
/// // Standard approach (less readable)
/// if ('apple'.compareTo('banana') < 0) {
///   print('apple is less than banana');
/// }
///
/// // With this extension (more readable)
/// if ('apple'.compareWith('banana') == Comparison.less) {
///   print('apple is less than banana');
/// }
/// ```
extension ComparableExtensions<T extends Object> on Comparable<T> {
  /// Compares this value with another value of the same type.
  ///
  /// Returns a [Comparison] enum indicating the relationship between
  /// this value and [other].
  ///
  /// This is a type-safe wrapper around [Comparable.compareTo] that
  /// converts the integer result to a meaningful enum value.
  ///
  /// Parameters:
  /// - [other]: The value to compare this against.
  ///
  /// Returns:
  /// - [Comparison.less] if this value is less than [other]
  /// - [Comparison.equal] if this value equals [other]
  /// - [Comparison.greater] if this value is greater than [other]
  ///
  /// Example:
  /// ```dart
  /// final comparison = 5.compareWith(3);
  /// assert(comparison == Comparison.greater);
  ///
  /// if (name.compareWith('Alice') == Comparison.less) {
  ///   print('Name comes before Alice');
  /// }
  /// ```
  Comparison compareWith(T other) {
    final result = compareTo(other);

    return switch (result) {
      < 0 => .less,
      == 0 => .equal,
      > 0 => .greater,
      _ => throw Exception('Impossible case'),
    };
  }

  /// Checks if this value is equal to [other].
  ///
  /// A convenient boolean method that checks for equality using the
  /// [Comparable] interface.
  ///
  /// Example:
  /// ```dart
  /// if (5.isEqualTo(5)) {
  ///   print('Values are equal');
  /// }
  /// ```
  bool isEqualTo(T other) => compareWith(other) == .equal;

  /// Checks if this value is greater than [other].
  ///
  /// Returns true only if this value is strictly greater than [other].
  ///
  /// Example:
  /// ```dart
  /// assert(10.isGreaterThan(5) == true);
  /// assert(5.isGreaterThan(10) == false);
  /// ```
  bool isGreaterThan(T other) => compareWith(other) == .greater;

  /// Checks if this value is greater than or equal to [other].
  ///
  /// Returns true if this value is greater than [other] or equal to it.
  ///
  /// Example:
  /// ```dart
  /// assert(10.isGreaterThanOrEqualTo(10) == true);
  /// assert(10.isGreaterThanOrEqualTo(5) == true);
  /// assert(5.isGreaterThanOrEqualTo(10) == false);
  /// ```
  bool isGreaterThanOrEqualTo(T other) {
    final result = compareWith(other);

    return result == .greater || result == .equal;
  }

  /// Checks if this value is less than [other].
  ///
  /// Returns true only if this value is strictly less than [other].
  ///
  /// Example:
  /// ```dart
  /// assert(5.isLessThan(10) == true);
  /// assert(10.isLessThan(5) == false);
  /// ```
  bool isLessThan(T other) => compareWith(other) == .less;

  /// Checks if this value is less than or equal to [other].
  ///
  /// Returns true if this value is less than [other] or equal to it.
  ///
  /// Example:
  /// ```dart
  /// assert(5.isLessThanOrEqualTo(5) == true);
  /// assert(5.isLessThanOrEqualTo(10) == true);
  /// assert(10.isLessThanOrEqualTo(5) == false);
  /// ```
  bool isLessThanOrEqualTo(T other) {
    final result = compareWith(other);

    return result == .less || result == .equal;
  }
}
