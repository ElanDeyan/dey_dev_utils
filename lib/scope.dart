// ignore_for_file: avoid_positional_boolean_parameters

/// Executes a code block and returns its result.
///
/// This is a utility for wrapping computation in a function scope.
/// Primarily useful as a base for scope manipulation or when you need
/// to control the execution context of a block of code.
///
/// Example:
/// ```dart
/// final result = run(() {
///   print('Doing computation...');
///   return 49;
/// });
/// ```
R run<R extends Object?>(R Function() block) => block();

/// Executes a block with a value and ensures cleanup via disposal.
///
/// This implements the resource management pattern (similar to try-with-resources
/// in Java). The [block] function is called with [value], and [dispose] is
/// is called in a `finally` block, regardless of whether the block succeeds or
/// throws.
///
/// Use this for:
/// - File/stream handling
/// - Database connection management
/// - Cleanup of temporary resources
/// - Any resource with a defined lifecycle
///
/// Parameters:
/// - [value]: The resource to use
/// - [block]: Function that uses the resource and returns a result
/// - [dispose]: Optional cleanup function called in finally
///
/// If both [block] and [dispose] throw, the exception from [dispose] replaces
/// the exception from [block], as with a Dart `finally` clause.
///
/// Example:
/// ```dart
/// final content = use(
///   File('data.txt'),
///   (file) => file.readAsStringSync(),
///   dispose: (file) => print('File closed'),
/// );
/// ```
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

/// Extension for executing side effects while returning the original value.
///
/// This extension provides a convenient way to perform operations (like logging
/// or validation) without transforming the value. The block executes as a
/// side effect, and the original value is always returned.
///
/// Common use cases:
/// - Logging intermediate values in a chain
/// - Validation checks
/// - Debugging value transformations
/// - Side effects in fluent APIs
///
/// Example:
/// ```dart
/// final user = fetchUser()
///   .also((u) => print('Fetched: ${u.name}'))
///   .also((u) => analytics.track('user_loaded'));
/// ```
extension AlsoExtension<T extends Object> on T {
  /// Executes a side effect block and returns this value unchanged.
  ///
  /// If [block] throws, the exception propagates and this value is not
  /// returned.
  ///
  /// Example:
  /// ```dart
  /// final number = 42
  ///   .also((n) => print('Value is: $n'));
  /// // Prints: Value is: 42
  /// // number is still 42
  /// ```
  T also(void Function(T value) block) {
    block(this);

    return this;
  }
}

/// Extension for conditionally transforming values.
///
/// This extension provides methods to apply transformations based on conditions,
/// returning either the transformed value or the original value unchanged.
/// Unlike [TakeExtension], which returns null or the value, this applies
/// transformations that always return a value of the same type.
///
/// Common use cases:
/// - Building configuration objects with conditional properties
/// - Applying transformations based on runtime conditions
/// - Fluent builder patterns with conditional steps
/// - Debugging-enabled features
///
/// Example:
/// ```dart
/// final config = Config()
///   .applyIf(isProduction, (c) => c.copyWith(debug: false))
///   .applyIfLazy((c) => c.environment == 'test', (c) => c.copyWith(timeout: 5000));
/// ```
extension ApplyExtension<T extends Object> on T {
  /// Conditionally transforms this value and returns the result.
  ///
  /// If [condition] is true, applies the [block] transformation to this value
  /// and returns the result. Otherwise, returns this value unchanged. The
  /// [block] must return another value of the same type [T].
  ///
  /// Use this for simple boolean conditions where you have a transform to apply
  /// if the condition is true.
  ///
  /// Example:
  /// ```dart
  /// final user = User(name: 'Alice', role: 'user')
  ///   .applyIf(isAdmin, (u) => u.copyWith(role: 'admin', level: 10));
  /// // If isAdmin is true, user becomes an admin with level 10
  /// // If isAdmin is false, user remains unchanged
  /// ```
  T applyIf(bool condition, T Function(T value) block) {
    if (condition) {
      return block(this);
    }

    return this;
  }

  /// Conditionally transforms this value based on a lazy predicate.
  ///
  /// Evaluates the [predicate] with this value. If it returns true, applies
  /// the [block] transformation and returns the result. Otherwise, returns
  /// this value unchanged.
  ///
  /// Use this when the condition depends on properties of the value itself,
  /// avoiding the need to compute the condition before calling the method.
  ///
  /// Example:
  /// ```dart
  /// final builder = StringBuilder('Hello')
  ///   .applyIfLazy(
  ///     (sb) => sb.length < 100,
  ///     (sb) => sb.append(' World!'),
  ///   );
  /// // Appends only if current length is less than 100
  /// ```
  ///
  /// Another example with configuration:
  /// ```dart
  /// final settings = Settings(maxRetries: 3)
  ///   .applyIfLazy(
  ///     (s) => s.maxRetries < 5,
  ///     (s) => s.copyWith(maxRetries: 5, enableBackoff: true),
  ///   );
  /// ```
  T applyIfLazy(bool Function(T value) predicate, T Function(T value) block) {
    if (predicate(this)) {
      return block(this);
    }

    return this;
  }
}

/// Extension for transforming values using a block function.
///
/// This extension provides functional transformation capabilities,
/// similar to map/flatMap patterns from functional programming.
/// Useful for chaining transformations in a readable way.
///
/// Example:
/// ```dart
/// final doubled = 5
///   .let((n) => n * 2)
///   .let((n) => '$n is the result');
/// ```
extension LetExtension<T extends Object> on T {
  /// Transforms this value using [block] and returns the result.
  ///
  /// The [block] receives this value and can return any type [R].
  /// Use this for value transformations in a fluent, readable style.
  ///
  /// Example:
  /// ```dart
  /// final user = userData
  ///   .let((data) => User.fromJson(data))
  ///   .let((user) => user.copyWith(verified: true));
  /// ```
  R let<R extends Object?>(R Function(T value) block) => block(this);
}

/// Extension for conditionally filtering values.
///
/// Provides methods to return the value (as-is) or null based on conditions,
/// useful for filtering in chains or implementing optional transformations.
extension TakeExtension<T extends Object> on T {
  /// Returns this value if [condition] is true, otherwise null.
  ///
  /// A simple boolean check that conditionally returns the value.
  /// Useful for filtering in chains.
  ///
  /// Example:
  /// ```dart
  /// final adult = person.takeIf(person.age >= 18);
  /// // adult is person if age >= 18, null otherwise
  /// ```
  T? takeIf(bool condition) {
    if (condition) return this;

    return null;
  }

  /// Returns this value if [predicate] returns true for it, otherwise null.
  ///
  /// A lazy predicate-based check that evaluates the condition using
  /// the value itself. Useful for conditional filtering based on the
  /// value's properties.
  ///
  /// Example:
  /// ```dart
  /// final validAge = age.takeIfLazy((a) => a >= 18 && a <= 120);
  /// ```
  T? takeIfLazy(bool Function(T value) predicate) {
    if (predicate(this)) return this;

    return null;
  }

  /// Returns this value if [condition] is false, otherwise null.
  ///
  /// The opposite of [takeIf]. Useful for negated conditions.
  ///
  /// Example:
  /// ```dart
  /// final notEmpty = text.takeUnless(text.isEmpty);
  /// // Returns text if it's not empty, null if empty
  /// ```
  T? takeUnless(bool condition) {
    if (!condition) return this;

    return null;
  }

  /// Returns this value if [predicate] returns false for it, otherwise null.
  ///
  /// The opposite of [takeIfLazy]. Useful for negated predicate conditions.
  ///
  /// Example:
  /// ```dart
  /// final validNumber = input.takeUnlessLazy((n) => n < 0);
  /// // Returns input if it's not negative, null if negative
  /// ```
  T? takeUnlessLazy(bool Function(T value) predicate) {
    if (!predicate(this)) return this;

    return null;
  }
}
