/// Executes a bouncing computation until completion without recursion.
///
/// The trampoline pattern prevents stack overflow by replacing recursive
/// function calls with iterative execution. Instead of making recursive calls
/// directly, return a [More] bounce with a thunk that will be executed next.
///
/// This is particularly useful for:
/// - Tree traversals that could overflow the stack
/// - Deep recursive algorithms (parsing, DFS, etc.)
/// - Tail-recursive patterns that can't be optimized by the compiler
///
/// How it works:
/// 1. Start with an initial [Bounce] (usually [More])
/// 2. Each [More] returns a function that produces the next [Bounce]
/// 3. The trampoline executes these functions in a loop (not recursion)
/// 4. When [Done] is reached, the final value is returned
///
/// Example:
/// ```dart
/// // Calculate factorial without recursion overflow
/// Bounce<int> factorialBounce(int n, int acc) {
///   if (n <= 1) {
///     return Done(acc);
///   }
///   return More(() => factorialBounce(n - 1, n * acc));
/// }
///
/// final result = trampoline(More(() => factorialBounce(5, 1)));
/// // result = 120
/// ```
T trampoline<T>(Bounce<T> bounce) {
  var current = bounce;

  while (current is More<T>) {
    current = current.next();
  }

  assert(current is Done<T>);

  return (current as Done<T>).value;
}

/// Base class for computations in the trampoline pattern.
///
/// A [Bounce] represents either:
/// - More computation to do ([More])
/// - The final result ([Done])
///
/// This sealed class restricts implementations to [More] and [Done],
/// ensuring type safety in the trampoline execution.
sealed class Bounce<T extends Object?> {
  const Bounce();
}

/// Represents the final result of a bouncing computation.
///
/// When the trampoline reaches a [Done] bounce, it extracts the [value]
/// and returns it. This signals that the computation is complete.
///
/// Example:
/// ```dart
/// final result = Done(42);
/// // Trampoline will extract and return 42
/// ```
class Done<T extends Object?> extends Bounce<T> {
  /// Creates a completed result with the given [value].
  const Done(this.value);

  /// The final computed value that will be returned by the trampoline.
  final T value;
}

/// Represents pending computation in the trampoline pattern.
///
/// Each [More] contains a thunk (lazy function) that will be executed
/// to produce the next [Bounce]. This defers execution and prevents
/// direct recursion, allowing the trampoline loop to handle deep stacks.
///
/// Example:
/// ```dart
/// // Represent pending recursive computation
/// return More(() => nextBounce(n - 1));
/// // Instead of: return nextBounce(n - 1);
/// ```
class More<T extends Object?> extends Bounce<T> {
  /// Creates a pending computation with the given [next] thunk.
  ///
  /// The [next] function will be called by the trampoline to get the
  /// next bounce in the chain. This deferral is key to preventing
  /// stack overflow in deep recursion.
  const More(this.next);

  /// A lazy function that produces the next computation step.
  ///
  /// The trampoline calls this function to get the next [Bounce].
  /// Wrap recursive calls in this thunk to avoid direct recursion:
  ///
  /// ```dart
  /// // Good: deferred recursion
  /// return More(() => recursiveStep(n - 1));
  ///
  /// // Bad: would still be recursive
  /// return More(recursiveStep(n - 1));
  /// ```
  final Bounce<T> Function() next;
}
