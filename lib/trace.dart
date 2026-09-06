@experimental
library;

import 'dart:developer' as developer;

import 'package:meta/meta.dart';

/// Executes an asynchronous operation while logging its execution time and status.
///
/// This function wraps an asynchronous [block] with automatic timing and logging.
/// It logs the start, completion time (including duration), and any errors that occur.
/// This is useful for performance profiling, debugging, and monitoring the execution
/// of critical operations.
///
/// The function returns the same value as [block] and re-throws any exception it
/// raises, making it transparent to callers: behaviour is identical to calling
/// [block] directly, with timing and logging added as a side effect.
///
/// **Logging Output:**
/// - Start: `▶ <label> started`
/// - Success: `✓ <label> done in <ms>ms`
/// - Error: `✗ <label> failed after <ms>ms: <error>`
///
/// Logs are written using [developer.log], which respects Dart's logging
/// configuration and appears in the DevTools timeline and logs.
///
/// **Type Parameter [T]:** The return type of the operation, can be any value
/// (nullable or non-nullable).
///
/// **Parameters:**
/// - [label]: A descriptive name for the operation, used in log messages.
/// - [block]: An async function that performs the operation and returns a [Future].
///
/// **Returns:** The value resolved from the [Future] returned by [block].
///
/// **Throws:** Re-throws any exception thrown by [block] after logging the failure.
///
/// Example:
/// ```dart
/// // Simple operation — note the required await
/// final data = await tracedAsync('fetch_users', () async {
///   return fetchUsers();
/// });
///
/// // Error handling
/// try {
///   await tracedAsync('risky_operation', () async => riskyFunction());
/// } catch (e) {
///   print('Operation failed: $e');
/// }
/// ```
///
/// See also:
/// - [developer.log] for understanding the logging backend.
/// - For sync operations, consider using [tracedSync].
@experimental
Future<T> tracedAsync<T>(String label, Future<T> Function() block) async {
  developer.log('▶ $label started');
  final sw = Stopwatch()..start();
  try {
    final result = await block();
    sw.stop();
    developer.log('✓ $label done in ${sw.elapsedMilliseconds}ms');
    return result;
  } catch (e) {
    sw.stop();
    developer.log('✗ $label failed after ${sw.elapsedMilliseconds}ms: $e');
    rethrow;
  }
}

/// Executes a synchronous operation while logging its execution time and status.
///
/// This function wraps a synchronous [block] with automatic timing and logging.
/// It logs the start, completion time (including duration), and any errors that occur.
/// This is useful for performance profiling, debugging, and monitoring the execution
/// of critical operations.
///
/// The function returns the same value as [block] and re-throws any exception it
/// raises, making it transparent to callers: behaviour is identical to calling
/// [block] directly, with timing and logging added as a side effect.
///
/// **Logging Output:**
/// - Start: `▶ <label> started`
/// - Success: `✓ <label> done in <ms>ms`
/// - Error: `✗ <label> failed after <ms>ms: <error>`
///
/// Logs are written using [developer.log], which respects Dart's logging
/// configuration and appears in the DevTools timeline and logs.
///
/// **Type Parameter [T]:** The return type of the operation, can be any value
/// (nullable or non-nullable).
///
/// **Parameters:**
/// - [label]: A descriptive name for the operation, used in log messages.
/// - [block]: A synchronous function that performs the operation and returns a value.
///
/// **Returns:** The value returned by [block].
///
/// **Throws:** Re-throws any exception thrown by [block] after logging the failure.
///
/// Example:
/// ```dart
/// // Simple operation
/// final data = tracedSync('parse_config', () {
///   return parseConfig();
/// });
///
/// // With complex logic
/// final result = tracedSync('calculate', () {
///   var sum = 0;
///   for (var i = 0; i < 1000000; i++) {
///     sum += i;
///   }
///   return sum;
/// });
///
/// // Error handling
/// try {
///   tracedSync('risky_operation', () => riskyFunction());
/// } catch (e) {
///   print('Operation failed: $e');
/// }
/// ```
///
/// See also:
/// - [developer.log] for understanding the logging backend.
/// - For async operations, consider using [tracedAsync].
@experimental
T tracedSync<T>(String label, T Function() block) {
  developer.log('▶ $label started');
  final sw = Stopwatch()..start();
  try {
    final result = block();
    sw.stop();
    developer.log('✓ $label done in ${sw.elapsedMilliseconds}ms');
    return result;
  } catch (e) {
    sw.stop();
    developer.log('✗ $label failed after ${sw.elapsedMilliseconds}ms: $e');
    rethrow;
  }
}
