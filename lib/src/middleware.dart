@experimental
library;

import 'package:meta/meta.dart';

/// The default identity handler that passes input through unchanged.
///
/// This serves as the terminal handler in the middleware chain - the innermost
/// function that doesn't perform any transformation. All middleware wraps around
/// this core handler.
Future<T> _handler<T extends Object?>(T t) async => t;

/// A handler function that processes a value of type [T] asynchronously.
///
/// [Handler] represents an endpoint or step in an asynchronous pipeline.
/// It takes an input of type [T] and returns a [Future] that eventually resolves
/// to a value of type [T] (possibly transformed).
///
/// Handlers can be chained together through middleware composition.
///
/// Example:
/// ```dart
/// // A simple logging handler
/// Future<String> loggingHandler(String input) async {
///   print('Processing: $input');
///   return input.toUpperCase();
/// }
/// ```
@experimental
typedef Handler<T extends Object?> = Future<T> Function(T);

/// A middleware function that wraps or intercepts a handler.
///
/// A [Middleware] takes an existing [Handler] and returns a new [Handler]
/// that provides additional behavior before or after calling the original handler.
/// This enables composition of cross-cutting concerns like logging, validation,
/// error handling, timing, etc.
///
/// Middleware follows the decorator pattern:
/// - It receives the "next" handler in the chain
/// - It creates a new handler that wraps the next handler
/// - When called, it can perform pre-processing, call the next handler, then post-process
///
/// Example:
/// ```dart
/// // Timing middleware that logs how long the handler takes
/// Middleware<String> timingMiddleware = (next) {
///   return (input) async {
///     final sw = Stopwatch()..start();
///     try {
///       return await next(input);
///     } finally {
///       sw.stop();
///       print('Took ${sw.elapsedMilliseconds}ms');
///     }
///   };
/// };
///
/// // Validation middleware that checks input before processing
/// Middleware<String> validationMiddleware = (next) {
///   return (input) async {
///     if (input.isEmpty) throw ArgumentError('Input cannot be empty');
///     return await next(input);
///   };
/// };
/// ```
@experimental
typedef Middleware<T extends Object?> = Handler<T> Function(Handler<T>);

/// A composable pipeline of middleware that processes values asynchronously.
///
/// [Pipeline] builds and executes a chain of middleware around a terminal handler.
/// Middleware are registered via [use] and executed in the order they were added
/// when the pipeline is called.
///
/// **Execution order:** When you call the pipeline, middleware execute in an
/// "onion layer" pattern:
/// 1. First middleware's pre-processing runs
/// 2. Second middleware's pre-processing runs
/// 3. ... and so on until reaching the core handler
/// 4. The core handler executes
/// 5. Then post-processing runs in reverse order (last to first)
///
/// **Example execution trace:**
/// ```dart
/// final pipeline = Pipeline<String>();
/// pipeline.use(mw1); // Added first
/// pipeline.use(mw2); // Added second
/// pipeline.use(mw3); // Added third
///
/// pipeline('hello');
/// // Execution order:
/// // → mw1 pre-processing
/// //   → mw2 pre-processing
/// //     → mw3 pre-processing
/// //       → core handler
/// //     ← mw3 post-processing
/// //   ← mw2 post-processing
/// // ← mw1 post-processing
/// ```
///
/// This pattern is useful for:
/// - **Logging and monitoring**: Track all values flowing through
/// - **Error handling**: Wrap operations in try-catch
/// - **Validation**: Check and validate inputs before core logic
/// - **Performance timing**: Measure execution duration
/// - **Authentication/Authorization**: Check permissions before processing
/// - **Transformation**: Modify values before or after processing
///
/// **Complete example:**
/// ```dart
/// // Create a pipeline for processing strings
/// final pipeline = Pipeline<String>();
///
/// // Add logging middleware
/// pipeline.use((next) => (input) async {
///   print('Start: $input');
///   final result = await next(input);
///   print('End: $result');
///   return result;
/// });
///
/// // Add timing middleware
/// pipeline.use((next) => (input) async {
///   final sw = Stopwatch()..start();
///   final result = await next(input);
///   sw.stop();
///   print('Duration: ${sw.elapsedMilliseconds}ms');
///   return result;
/// });
///
/// // Add transformation middleware
/// pipeline.use((next) => (input) async {
///   final transformed = input.toUpperCase();
///   return await next(transformed);
/// });
///
/// // Call the pipeline
/// final result = await pipeline('hello');
/// // Logs:
/// // Start: HELLO
/// // Duration: 0ms
/// // End: HELLO
/// ```
@experimental
class Pipeline<T extends Object?> {
  /// Stores the list of middleware in the order they were registered.
  final List<Middleware<T>> _middlewares = [];

  /// Executes the pipeline with the given input.
  ///
  /// This method:
  /// 1. Builds the middleware chain in reverse order (right-to-left)
  /// 2. Each middleware wraps the previous handler
  /// 3. Calls the complete chain with the input
  ///
  /// The chain is built as: `mw1(mw2(mw3(...(core_handler))))`
  /// where middleware are ordered as they were added via [use].
  ///
  /// Returns a [Future] that resolves when the entire pipeline completes.
  /// If any middleware throws an exception, it propagates through the Future.
  ///
  /// Parameters:
  /// - [input]: The value to process through the pipeline
  ///
  /// Returns: A [Future] containing the processed value
  ///
  /// Example:
  /// ```dart
  /// final pipeline = Pipeline<int>();
  /// pipeline.use((next) => (value) async => await next(value * 2));
  /// final result = await pipeline(5); // Returns 10
  /// ```
  Future<T> call(T input) {
    var handler = _handler<T>;

    // Build chain right to left: first middleware ends up outermost
    for (final mw in _middlewares.reversed) {
      final next = handler;
      handler = mw(next);
    }
    return handler(input);
  }

  /// Registers a middleware in this pipeline.
  ///
  /// Middleware are executed in the order they are registered (first registered
  /// is outermost, wrapping all later middleware). This is the same behavior
  /// as popular web frameworks like Express.js.
  ///
  /// Each middleware receives the next handler in the chain and must eventually
  /// call it (unless intentionally short-circuiting the chain).
  ///
  /// Parameters:
  /// - [middleware]: The middleware function to add
  ///
  /// Example:
  /// ```dart
  /// pipeline.use((next) => (input) async {
  ///   print('Before');
  ///   final result = await next(input);
  ///   print('After');
  ///   return result;
  /// });
  /// ```
  void use(Middleware<T> middleware) => _middlewares.add(middleware);
}
