import 'dart:async';

/// Delays execution of a function, resetting the timer on each call.
///
/// The Debouncer pattern is useful when you have frequent events and only care
/// about the final state. It delays execution until calls stop for a specified
/// duration.
///
/// Use cases:
/// - Search input: wait until user stops typing before searching
/// - Window resize: only recalculate layout after resizing stops
/// - Auto-save: save only after user stops editing
/// - Form validation: validate after user stops changing fields
///
/// Example:
/// ```dart
/// final debouncer = Debouncer(Duration(milliseconds: 500));
///
/// // In text input handler
/// debouncer(() => performSearch(query));
/// // Each new keystroke cancels the previous timer and starts a new one
/// // Search only runs 500ms after the last keystroke
/// ```
///
/// Remember to call [dispose] when done to clean up the timer.
final class Debouncer {
  /// Creates a debouncer with the given [_duration].
  ///
  /// The duration specifies how long to wait after the last call before
  /// executing the action.
  Debouncer(this._duration);

  /// The time to wait before executing the action.
  final Duration _duration;

  /// The active timer, if any.
  Timer? _timer;

  /// Schedules [block] to execute after [_duration] of inactivity.
  ///
  /// If this is called again before [_duration] elapses, the previous
  /// timer is cancelled and a new one is started. Only the most recent
  /// call's action will execute.
  ///
  /// Example:
  /// ```dart
  /// debouncer(() => print('Executed'));
  /// // ... 200ms later
  /// debouncer(() => print('Cancelled - new timer started'));
  /// // ... 500ms later
  /// debouncer(() => print('This one will execute'));
  /// ```
  void call(void Function() block) {
    _timer?.cancel();
    _timer = .new(_duration, block);
  }

  /// Cancels any pending execution and cleans up the timer.
  ///
  /// Call this when you no longer need the debouncer to prevent
  /// the action from executing unexpectedly.
  void dispose() {
    _timer?.cancel();
  }
}

/// Limits the execution frequency of a function to at most once per interval.
///
/// The Throttle pattern is useful when you want to limit how often an action
/// happens, even if events occur frequently. Unlike debouncing (which waits
/// for inactivity), throttling allows periodic execution.
///
/// Use cases:
/// - Scroll events: fire handler at most once per 100ms while scrolling
/// - Mouse move: limit position updates while tracking mouse movement
/// - Button clicks: prevent rapid-fire clicks on expensive operations
/// - API calls: rate-limit requests during rapid user interactions
///
/// Example:
/// ```dart
/// final throttle = Throttle(Duration(milliseconds: 100));
///
/// // In scroll listener
/// throttle(() => updateUI());
/// // First call executes immediately
/// // Subsequent calls within 100ms are ignored
/// // Call after 100ms executes again
/// ```
///
/// Note: This throttle uses `>` for interval comparison, meaning it requires
/// strictly more than the interval time to have passed before allowing another
/// execution. Standard behavior would use `>=` to allow execution at the exact
/// interval boundary. Adjust if needed for your use case.
final class Throttle {
  /// Creates a throttle with the given [interval].
  ///
  /// Actions will be executed at most once per [interval] duration.
  Throttle(this.interval);

  /// The minimum time between action executions.
  final Duration interval;

  /// The timestamp of the last execution, or null if never executed.
  DateTime? _lastRun;

  /// Executes [action] only if enough time has passed since the last execution.
  ///
  /// The action runs immediately if:
  /// - This is the first call
  /// - More than [interval] has elapsed since the last execution
  ///
  /// Otherwise, the action is skipped.
  ///
  /// Example:
  /// ```dart
  /// final throttle = Throttle(Duration(seconds: 1));
  ///
  /// throttle(() => print('1')); // Executes immediately
  /// throttle(() => print('2')); // Skipped (< 1 second)
  /// throttle(() => print('3')); // Skipped (< 1 second)
  /// // ... wait 1+ seconds
  /// throttle(() => print('4')); // Executes (interval passed)
  /// ```
  void call(void Function() action) {
    final now = DateTime.now();
    final lastRun = _lastRun;
    if (lastRun == null || now.difference(lastRun) > interval) {
      _lastRun = now;
      action();
    }
  }
}
