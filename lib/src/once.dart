@experimental
library;

import 'package:meta/meta.dart';

/// Lazy initialization wrapper that computes a value only once and caches it.
///
/// [Once] ensures expensive computations or resource allocations are performed
/// once and reused. Perfect for implementing lazy singletons, caching results,
/// or deferring initialization until first use.
///
/// The instance itself is callable via the [call] method, making usage clean
/// and intuitive.
///
/// Example:
/// ```dart
/// // Expensive computation deferred until first access
/// final expensiveValue = Once(() {
///   print('Computing...');
///   return complexCalculation();
/// });
///
/// final result1 = expensiveValue(); // Prints 'Computing...', computes value
/// final result2 = expensiveValue(); // Returns cached value (no computation)
/// ```
///
/// Common use cases:
/// - Lazy singleton initialization
/// - Expensive resource loading (files, network requests)
/// - Heavy computations deferred to first use
/// - Caching configuration or expensive lookups
@experimental
final class Once<T extends Object?> {
  /// Creates a lazy initializer with the given [_init] function.
  ///
  /// The function will be called exactly once when [call] is first invoked.
  /// Subsequent calls return the cached result.
  Once(this._init);

  /// The initialization function that computes the value.
  ///
  /// This function is called exactly once on the first [call] invocation,
  /// and its result is cached for all subsequent calls.
  final T Function() _init;

  /// The cached value, computed lazily on first access.
  ///
  /// Initially null, and populated after the first [call] invocation.
  T? _value;

  bool _computed = false;

  /// Gets or computes the lazy-initialized value.
  ///
  /// On the first call, executes the initialization function, caches the result,
  /// and returns it. On subsequent calls, returns the cached value without
  /// re-executing the initialization function.
  ///
  /// Example:
  /// ```dart
  /// final config = Once(() => loadConfig());
  ///
  /// final settings1 = config(); // Loads config
  /// final settings2 = config(); // Returns cached config
  /// ```
  T call() {
    if (!_computed) {
      _value = _init();
      _computed = true;
    }

    return _value ??= _init();
  }
}
